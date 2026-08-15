import 'package:postgrest/postgrest.dart';

import 'models/student_profile.dart';
import 'supabase_client_provider.dart';

/// Raised when a write is refused because it doesn't belong to the
/// signed-in user, or the database's Row Level Security policy
/// rejected it. Kept distinct from a generic network/server failure
/// so the UI can show "you're not signed in" rather than "check your
/// connection" — see ProfileProvider.
class ProfileWriteDeniedException implements Exception {
  ProfileWriteDeniedException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// All reads/writes to the real `students` table.
///
/// RLS-safety rules this class enforces (per the Flutter Core
/// Architecture doc, Sections 11.3/15.2: "RLS Policies enforce data
/// access at database level" and "RLS prevents data access even if
/// [UI] guards are bypassed" — client code should never rely on RLS
/// alone to catch a bug, it should also refuse to attempt the wrong
/// write in the first place):
///
/// 1. Every read/write is scoped to `AppSupabase.currentUserId` (i.e.
///    `auth.uid()` on the server) — never to an id passed in from
///    elsewhere in app state, which could be stale. `fetchProfile()`
///    takes no parameter for this reason.
///
/// 2. `upsertProfile()` refuses to write if the profile object's
///    `profileId` doesn't match the live session's user id — this
///    catches bugs (e.g. a stale cached StudentProfile from a
///    previous session) before they ever reach the network, rather
///    than depending on the database to reject it.
///
/// 3. Writes NEVER include system-owned columns — `is_blacklisted`,
///    `verification_status`, `verification_method`, `college_verified`,
///    `referral_code`, `referred_by_code`, `referral_count`,
///    `created_at`, `id`. This is a defense-in-depth measure: it
///    should also be enforced by RLS column grants / `with check`
///    expressions on the actual policy (see
///    supabase/student_profiles_schema.sql), not by this alone.
///
/// 4. RLS/permission failures are surfaced as
///    `ProfileWriteDeniedException`, distinct from network/server
///    failures, so the UI can tell a student "please sign in again"
///    instead of "check your connection" for what's actually an auth
///    problem.
class ProfileService {
  static const _table = 'students';

  /// Fetches the signed-in student's own row. Ignores any id the
  /// caller might otherwise have supplied — identity always comes
  /// from the live session, per the RLS-safety rules above.
  Future<StudentProfile?> fetchProfile() async {
    final profileId = AppSupabase.currentUserId;
    if (profileId == null) {
      throw ProfileWriteDeniedException('Not signed in — sign in before loading a profile.');
    }

    try {
      final row = await AppSupabase.client
          .from(_table)
          .select()
          .eq('profile_id', profileId)
          .maybeSingle();

      if (row == null) return null;
      return StudentProfile.fromMap(row);
    } on PostgrestException catch (e) {
      if (_isPermissionError(e)) {
        throw ProfileWriteDeniedException(
            'You don\'t have permission to view this profile. Please sign in again.');
      }
      rethrow;
    }
  }

  Future<StudentProfile> upsertProfile(StudentProfile profile) async {
    final sessionUserId = AppSupabase.currentUserId;
    if (sessionUserId == null) {
      throw ProfileWriteDeniedException('Not signed in — sign in before saving your profile.');
    }
    if (profile.profileId != sessionUserId) {
      // Refuse client-side rather than let a mismatched write reach
      // the network at all — this should be impossible in normal use
      // (ProfileProvider always loads via the live session id), so
      // hitting this means something upstream is stale or wrong.
      throw ProfileWriteDeniedException(
          'This profile does not belong to the signed-in account — refusing to save.');
    }

    try {
      final row = await AppSupabase.client
          .from(_table)
          .upsert(_toWritableMap(profile), onConflict: 'profile_id')
          .select()
          .single();

      return StudentProfile.fromMap(row);
    } on PostgrestException catch (e) {
      if (_isPermissionError(e)) {
        throw ProfileWriteDeniedException(
            'That change was rejected by the server\'s security policy. Please sign in again '
            'and retry — if this keeps happening, the RLS policy on `students` may need review.');
      }
      rethrow;
    }
  }

  /// Postgres raises `42501` (insufficient_privilege) when an INSERT
  /// is blocked by RLS. An UPDATE/UPSERT blocked by RLS instead
  /// silently matches zero rows, which `.single()` turns into a
  /// PostgREST "no rows returned" error (`PGRST116`) — both are
  /// treated as permission problems here rather than generic server
  /// errors.
  bool _isPermissionError(PostgrestException e) =>
      e.code == '42501' || e.code == 'PGRST116' || e.message.toLowerCase().contains('row-level security');

  /// Everything a student is actually allowed to write. Deliberately
  /// a strict subset of StudentProfile.toMap() — confirm this list
  /// against the real RLS policies on `students` once they exist
  /// (see supabase/student_profiles_schema.sql), since the column
  /// list here should match whatever `with check (...)` / column
  /// grants the backend enforces.
  Map<String, dynamic> _toWritableMap(StudentProfile p) => {
        'profile_id': p.profileId,
        'full_name': p.fullName,
        'country_code': p.countryCode,
        'phone': p.phone,
        'course': p.course,
        'branch': p.branch,
        'graduation_year': p.graduationYear,
        'cgpa': p.cgpa,
        'college_name': p.collegeName,
        'college_state': p.collegeState,
        'college_city': p.collegeCity,
        'college_email': p.collegeEmail,
        'college_id_path': p.collegeIdPath,
        'about_me': p.aboutMe,
        'skills': JsonListColumn.encodeStrings(p.skills),
        'projects': JsonListColumn.encodeMaps(p.projects.map((pr) => pr.toMap()).toList()),
        'certifications': JsonListColumn.encodeStrings(p.certifications),
        'achievements': JsonListColumn.encodeStrings(p.achievements),
        'resume_path': p.resumePath,
        'linkedin_url': p.linkedinUrl,
      };
}
