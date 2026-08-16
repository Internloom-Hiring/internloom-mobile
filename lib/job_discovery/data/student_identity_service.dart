import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/profile/data/supabase_client_provider.dart';

/// Resolves the internal `students.id` once for the current authenticated
/// session and keeps it in memory for the lifetime of this service.
///
/// The auth UUID is `students.profile_id`; it must never be sent as
/// `applications.student_id` / `match_scores.student_id`.
class StudentIdentityService {
  StudentIdentityService({SupabaseClient? client})
      : _client = client ?? AppSupabase.client;

  final SupabaseClient _client;

  String? _studentId;
  String? _resolvedForProfileId;

  String? get cachedStudentId => _studentId;

  Future<String> resolveStudentId() async {
    final profileId = _client.auth.currentUser?.id;
    if (profileId == null) {
      throw const StudentIdentityException('Not signed in.');
    }

    if (_studentId != null && _resolvedForProfileId == profileId) {
      return _studentId!;
    }

    final row = await _client
        .from('students')
        .select('id')
        .eq('profile_id', profileId)
        .maybeSingle();

    final studentId = row?['id'] as String?;
    if (studentId == null || studentId.isEmpty) {
      throw const StudentIdentityException(
        'No student record exists for the signed-in account.',
      );
    }

    _studentId = studentId;
    _resolvedForProfileId = profileId;
    return studentId;
  }

  void clear() {
    _studentId = null;
    _resolvedForProfileId = null;
  }
}

class StudentIdentityException implements Exception {
  const StudentIdentityException(this.message);

  final String message;

  @override
  String toString() => message;
}
