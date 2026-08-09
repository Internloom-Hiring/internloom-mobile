import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/models/project_entry.dart';
import '../data/models/student_profile.dart';
import '../data/profile_service.dart';
import '../data/storage_service.dart';
import '../data/supabase_client_provider.dart';
import '../utils/profile_completion.dart';

enum ProfileLoadState { initial, loading, loaded, error, notSignedIn }

/// Single source of truth for the student's profile, shared across
/// every screen. Every mutating method: updates local state ->
/// recomputes completion -> persists to Supabase (via
/// ProfileService, which strips system-owned columns before writing)
/// -> notifies listeners.
///
/// Identity is always read live from `AppSupabase.currentUserId`
/// (i.e. the signed-in session), never threaded in as a parameter —
/// this is what ProfileService/StorageService enforce on their side
/// too, so a stale id can't silently end up in a write. See
/// `ProfileLoadState.notSignedIn` for the "no session" UI state, and
/// `ProfileWriteDeniedException` for RLS/permission failures, which
/// are surfaced with a distinct message from a generic network error.
class ProfileProvider extends ChangeNotifier {
  ProfileProvider({ProfileService? profileService, StorageService? storageService})
      : _profileService = profileService ?? ProfileService(),
        _storageService = storageService ?? StorageService();

  final ProfileService _profileService;
  final StorageService _storageService;

  StudentProfile? _profile;
  ProfileLoadState _loadState = ProfileLoadState.initial;
  String? _errorMessage;
  bool _isSaving = false;

  StudentProfile? get profile => _profile;
  ProfileLoadState get loadState => _loadState;
  String? get errorMessage => _errorMessage;
  bool get isSaving => _isSaving;
  StorageService get storageService => _storageService;

  int get completionPct => _profile == null ? 0 : ProfileCompletion.percentFor(_profile!);
  List<String> get missingItems =>
      _profile == null ? [] : ProfileCompletion.missingItems(_profile!);
  bool get hasGuidedSetupMinimum => _profile?.hasGuidedSetupMinimum ?? false;

  /// Loads the signed-in student's own row. Takes no parameter — the
  /// old version accepted an external `profileId`, which risked
  /// loading (or later saving) against a stale/wrong id if app state
  /// ever drifted from the actual session. Now it's impossible to
  /// pass the wrong id because there's nowhere to pass one.
  Future<void> load() async {
    final sessionUserId = AppSupabase.currentUserId;
    if (sessionUserId == null) {
      _loadState = ProfileLoadState.notSignedIn;
      _errorMessage = 'You need to be signed in to view or edit your profile.';
      notifyListeners();
      return;
    }

    _loadState = ProfileLoadState.loading;
    notifyListeners();
    try {
      final existing = await _profileService.fetchProfile();
      _profile = existing ?? StudentProfile.empty(sessionUserId);
      _loadState = ProfileLoadState.loaded;
      _errorMessage = null;
    } on ProfileWriteDeniedException catch (e) {
      _errorMessage = e.message;
      _loadState = ProfileLoadState.notSignedIn;
    } on ProfileSchemaMissingException catch (e) {
      _errorMessage = e.message;
      _loadState = ProfileLoadState.error;
    } catch (e) {
      _errorMessage = kDebugMode
          ? 'Could not load your profile: $e'
          : 'Could not load your profile. Check your connection and try again.';
      _loadState = ProfileLoadState.error;
    }
    notifyListeners();
  }

  Future<bool> _persist() async {
    if (_profile == null) return false;
    _isSaving = true;
    notifyListeners();
    try {
      final saved = await _profileService.upsertProfile(_profile!);
      // Preserve read-only system fields the server returned (verification
      // status, referral info, etc.) rather than anything a stale local
      // value might have implied.
      _profile = saved;
      _errorMessage = null;
      return true;
    } on ProfileWriteDeniedException catch (e) {
      // Distinct from the generic network-failure message below — this
      // means the write was refused (not signed in, or RLS rejected
      // it), not that the network dropped.
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Could not save — check your connection and try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ---- One save method per section, per Section 2.3's "edit one section at a time" ----

  Future<bool> saveBasicInfo({
    required String fullName,
    required String countryCode,
    required String phone,
  }) async {
    if (_profile == null) return false;
    _profile!.fullName = fullName;
    _profile!.countryCode = countryCode;
    _profile!.phone = phone;
    return _persist();
  }

  Future<bool> saveAboutMe(String aboutMe) async {
    if (_profile == null) return false;
    _profile!.aboutMe = aboutMe;
    return _persist();
  }

  Future<bool> saveEducation({
    required String collegeName,
    required String collegeState,
    required String collegeCity,
    required String course,
    required String branch,
    required int graduationYear,
    required double cgpa,
  }) async {
    if (_profile == null) return false;
    _profile!.collegeName = collegeName;
    _profile!.collegeState = collegeState;
    _profile!.collegeCity = collegeCity;
    _profile!.course = course;
    _profile!.branch = branch;
    _profile!.graduationYear = graduationYear;
    _profile!.cgpa = cgpa;
    return _persist();
  }

  /// Saves the college email and, if a new ID document was picked,
  /// uploads it. This does NOT set verification_status/college_verified
  /// — those are system-owned (see ProfileService); submitting this
  /// form just gives the backend/admin what it needs to verify later.
  Future<bool> saveCollegeVerification({
    required String collegeEmail,
    File? newCollegeIdFile,
    String? newCollegeIdFileName,
  }) async {
    if (_profile == null) return false;
    if (newCollegeIdFile != null && newCollegeIdFileName != null) {
      try {
        _profile!.collegeIdPath = await _storageService.uploadCollegeId(
          newCollegeIdFile,
          fileName: newCollegeIdFileName,
        );
      } on ProfileWriteDeniedException catch (e) {
        _errorMessage = e.message;
        notifyListeners();
        return false;
      } catch (e) {
        // Any other upload failure (missing storage bucket, no storage
        // RLS policy, network error, etc.) must still be caught here —
        // letting it escape uncaught leaves the calling screen's
        // "uploading" spinner stuck forever, since the setState that
        // turns it off never runs.
        _errorMessage = kDebugMode
            ? 'Upload failed: $e'
            : 'Could not upload your file. Check your connection and try again.';
        notifyListeners();
        return false;
      }
    }
    _profile!.collegeEmail = collegeEmail;
    return _persist();
  }

  Future<bool> saveSkills(List<String> skills) async {
    if (_profile == null) return false;
    _profile!.skills = skills;
    return _persist();
  }

  Future<bool> saveProjects(List<ProjectEntry> projects) async {
    if (_profile == null) return false;
    _profile!.projects = projects;
    return _persist();
  }

  Future<bool> saveCertifications(List<String> certifications) async {
    if (_profile == null) return false;
    _profile!.certifications = certifications;
    return _persist();
  }

  Future<bool> saveAchievements(List<String> achievements) async {
    if (_profile == null) return false;
    _profile!.achievements = achievements;
    return _persist();
  }

  Future<bool> saveResume(File file, {required String fileName}) async {
    if (_profile == null) return false;
    try {
      _profile!.resumePath = await _storageService.uploadResume(file, fileName: fileName);
    } on ProfileWriteDeniedException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      // Same reasoning as saveCollegeVerification above: an uncaught
      // exception here would leave guided_setup_screen.dart's upload
      // spinner stuck forever with no error and no navigation.
      _errorMessage = kDebugMode
          ? 'Upload failed: $e'
          : 'Could not upload your resume. Check your connection and try again.';
      notifyListeners();
      return false;
    }
    return _persist();
  }

  /// A viewable link for the student's own resume — signed, 1-hour
  /// expiry, per the Core Architecture doc's storage mandate. Null if
  /// no resume has been uploaded yet.
  Future<String?> resumeSignedUrl() async {
    final path = _profile?.resumePath;
    if (path == null || path.isEmpty) return null;
    return _storageService.signedUrlFor(path);
  }

  /// A viewable link for the student's own uploaded college ID.
  Future<String?> collegeIdSignedUrl() async {
    final path = _profile?.collegeIdPath;
    if (path == null || path.isEmpty) return null;
    return _storageService.signedUrlFor(path);
  }

  Future<bool> saveLinkedin(String linkedinUrl) async {
    if (_profile == null) return false;
    _profile!.linkedinUrl = linkedinUrl;
    return _persist();
  }
}
