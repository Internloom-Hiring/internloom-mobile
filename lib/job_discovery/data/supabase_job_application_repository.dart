import 'package:postgrest/postgrest.dart';

import '../../features/profile/data/supabase_client_provider.dart';
import 'job_application_repository.dart';
import 'models/placement_drive.dart';
import 'student_identity_service.dart';

/// Persists a right-swipe as a real application.
///
/// The repository deliberately resolves the internal students.id through
/// StudentIdentityService. The auth UUID is students.profile_id and must not
/// be written into applications.student_id.
class SupabaseJobApplicationRepository implements JobApplicationRepository {
  SupabaseJobApplicationRepository({
    StudentIdentityService? identityService,
  }) : _identityService = identityService ?? StudentIdentityService();

  static const _applicationsTable = 'applications';

  final StudentIdentityService _identityService;

  @override
  Future<ApplicationWriteResult> apply(PlacementDrive drive) async {
    final studentId = await _identityService.resolveStudentId();

    try {
      await AppSupabase.client.from(_applicationsTable).insert({
        'student_id': studentId,
        'drive_id': drive.id,
      });

      return ApplicationWriteResult.created;
    } on PostgrestException catch (error) {
      // applications has UNIQUE(student_id, drive_id). A duplicate right
      // swipe is already in the desired final state, so treat it as success
      // rather than surfacing an error to the student.
      if (_isDuplicateApplication(error)) {
        return ApplicationWriteResult.alreadyApplied;
      }

      rethrow;
    }
  }

  bool _isDuplicateApplication(PostgrestException error) {
    if (error.code != '23505') return false;

    final message = error.message.toLowerCase();
    return message.contains('student_id') && message.contains('drive_id');
  }
}
