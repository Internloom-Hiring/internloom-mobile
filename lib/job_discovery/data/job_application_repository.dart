import 'models/placement_drive.dart';

enum ApplicationWriteResult {
  created,
  alreadyApplied,
}

/// Writes a swipe-right directly to the real applications table.
abstract interface class JobApplicationRepository {
  Future<ApplicationWriteResult> apply(PlacementDrive drive);
}
