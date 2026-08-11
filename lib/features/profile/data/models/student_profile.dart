import 'dart:convert';

import 'project_entry.dart';

/// Mirrors the real `students` table exactly (confirmed against the
/// live Supabase schema — see supabase/student_profiles_schema.sql).
///
/// Two id concepts, not one:
/// - `id` — this table's own primary key (uuid), assigned by Supabase.
/// - `profileId` — foreign key to the shared profile/auth user (the
///   `profile_id` column, unique-indexed). This is what Authentication's
///   session gives us and what every query/update in this module keys
///   off — NOT `id`.
///
/// System-owned fields (`isBlacklisted`, `verificationStatus`,
/// `verificationMethod`, `collegeVerified`, `referralCode`,
/// `referredByCode`, `referralCount`, `createdAt`, `id`) are read-only
/// here: the model exposes them for display, but ProfileService's
/// write payload deliberately excludes them so student-side code can
/// never overwrite values that admin/backend logic owns. See
/// ProfileService.toWritableMap().
///
/// `skills`, `projects`, `certifications`, and `achievements` are all
/// plain `text` columns in the real schema, not arrays/jsonb — each is
/// JSON-encoded to a string on save and decoded back on load (see the
/// `Json` helpers below), so this model still exposes them as proper
/// Dart lists.
class StudentProfile {
  final String? id; // students.id — read-only, system-assigned
  final String profileId; // students.profile_id — the key we query/update on

  // Basic info
  String fullName;
  String countryCode;
  String phone;

  // Education / college verification
  String course; // e.g. "B.E. Computer Science" — was "degree" in an earlier draft
  String branch;
  int? graduationYear;
  double? cgpa;
  String collegeName;
  String collegeState;
  String collegeCity;
  String collegeEmail;
  String? collegeIdPath; // storage path, not a public URL

  // System-owned, read-only — see class doc
  final bool isBlacklisted;
  final String verificationStatus; // enum in DB — confirm exact labels with Core Architecture
  final String verificationMethod; // enum in DB — confirm exact labels with Core Architecture
  final bool collegeVerified;
  final String? referralCode;
  final String? referredByCode;
  final int referralCount;
  final DateTime? createdAt;

  // Profile content
  String aboutMe;
  List<String> skills;
  List<ProjectEntry> projects;
  List<String> certifications;
  List<String> achievements;

  // Resume — storage path, not a public URL (matches resume_path column)
  String? resumePath;

  // Links
  String linkedinUrl;

  StudentProfile({
    this.id,
    required this.profileId,
    this.fullName = '',
    this.countryCode = '',
    this.phone = '',
    this.course = '',
    this.branch = '',
    this.graduationYear,
    this.cgpa,
    this.collegeName = '',
    this.collegeState = '',
    this.collegeCity = '',
    this.collegeEmail = '',
    this.collegeIdPath,
    this.isBlacklisted = false,
    this.verificationStatus = 'pending',
    this.verificationMethod = 'none',
    this.collegeVerified = false,
    this.referralCode,
    this.referredByCode,
    this.referralCount = 0,
    this.createdAt,
    this.aboutMe = '',
    List<String>? skills,
    List<ProjectEntry>? projects,
    List<String>? certifications,
    List<String>? achievements,
    this.resumePath,
    this.linkedinUrl = '',
  })  : skills = skills ?? [],
        projects = projects ?? [],
        certifications = certifications ?? [],
        achievements = achievements ?? [];

  factory StudentProfile.empty(String profileId) => StudentProfile(profileId: profileId);

  /// Display-only headline — there is no `headline` column in the
  /// real schema, so this is derived rather than stored/editable.
  /// Matches the spirit of Section 2.2's "name + one-line role/college
  /// tag" without needing a new column.
  String get displayHeadline {
    if (course.trim().isEmpty && collegeName.trim().isEmpty) return '';
    if (course.trim().isEmpty) return collegeName;
    if (collegeName.trim().isEmpty) return course;
    return '$course @ $collegeName';
  }

  factory StudentProfile.fromMap(Map<String, dynamic> map) {
    return StudentProfile(
      id: map['id'] as String?,
      profileId: map['profile_id'] as String,
      fullName: map['full_name'] as String? ?? '',
      countryCode: map['country_code'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      course: map['course'] as String? ?? '',
      branch: map['branch'] as String? ?? '',
      graduationYear: map['graduation_year'] as int?,
      cgpa: (map['cgpa'] as num?)?.toDouble(),
      collegeName: map['college_name'] as String? ?? '',
      collegeState: map['college_state'] as String? ?? '',
      collegeCity: map['college_city'] as String? ?? '',
      collegeEmail: map['college_email'] as String? ?? '',
      collegeIdPath: map['college_id_path'] as String?,
      isBlacklisted: map['is_blacklisted'] as bool? ?? false,
      verificationStatus: map['verification_status'] as String? ?? 'pending',
      verificationMethod: map['verification_method'] as String? ?? 'none',
      collegeVerified: map['college_verified'] as bool? ?? false,
      referralCode: map['referral_code'] as String?,
      referredByCode: map['referred_by_code'] as String?,
      referralCount: map['referral_count'] as int? ?? 0,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) : null,
      aboutMe: map['about_me'] as String? ?? '',
      skills: JsonListColumn.decodeStrings(map['skills'] as String?),
      projects: JsonListColumn.decodeMaps(map['projects'] as String?)
          .map(ProjectEntry.fromMap)
          .toList(),
      certifications: JsonListColumn.decodeStrings(map['certifications'] as String?),
      achievements: JsonListColumn.decodeStrings(map['achievements'] as String?),
      resumePath: map['resume_path'] as String?,
      linkedinUrl: map['linkedin_url'] as String? ?? '',
    );
  }

  /// Full read-shaped map, for local debugging only — NOT what gets
  /// sent to Supabase on save. See ProfileService.toWritableMap() for
  /// the actual write payload, which excludes system-owned columns.
  Map<String, dynamic> toMap() => {
        'id': id,
        'profile_id': profileId,
        'full_name': fullName,
        'country_code': countryCode,
        'phone': phone,
        'course': course,
        'branch': branch,
        'graduation_year': graduationYear,
        'cgpa': cgpa,
        'college_name': collegeName,
        'college_state': collegeState,
        'college_city': collegeCity,
        'college_email': collegeEmail,
        'college_id_path': collegeIdPath,
        'is_blacklisted': isBlacklisted,
        'verification_status': verificationStatus,
        'verification_method': verificationMethod,
        'college_verified': collegeVerified,
        'referral_code': referralCode,
        'referred_by_code': referredByCode,
        'referral_count': referralCount,
        'created_at': createdAt?.toIso8601String(),
        'about_me': aboutMe,
        'skills': JsonListColumn.encodeStrings(skills),
        'projects': JsonListColumn.encodeMaps(projects.map((p) => p.toMap()).toList()),
        'certifications': JsonListColumn.encodeStrings(certifications),
        'achievements': JsonListColumn.encodeStrings(achievements),
        'resume_path': resumePath,
        'linkedin_url': linkedinUrl,
      };

  /// True once Education (course, branch, college name, graduation
  /// year, CGPA) + at least 3 skills + a resume are present — the
  /// guided-setup minimum from Section 2.4.
  bool get hasGuidedSetupMinimum =>
      course.trim().isNotEmpty &&
      branch.trim().isNotEmpty &&
      collegeName.trim().isNotEmpty &&
      graduationYear != null &&
      cgpa != null &&
      skills.length >= 3 &&
      resumePath != null &&
      resumePath!.isNotEmpty;
}

/// Small helpers for the JSON-in-text-column convention used by
/// `skills`, `projects`, `certifications`, and `achievements`.
class JsonListColumn {
  JsonListColumn._();

  static List<String> decodeStrings(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.map((e) => e.toString()).toList();
      return [];
    } catch (_) {
      return [];
    }
  }

  static String encodeStrings(List<String> values) => jsonEncode(values);

  static List<Map<String, dynamic>> decodeMaps(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static String encodeMaps(List<Map<String, dynamic>> values) => jsonEncode(values);
}
