import 'models/job_discovery_filters.dart';
import 'models/placement_drive.dart';
import 'models/swipe_action.dart';

abstract interface class JobDiscoveryRepository {
  /// Fetches the next ranked batch for the signed-in student.
  ///
  /// Results are approved drives ordered by match_scores.final_score
  /// descending, with applications and persisted swipes excluded.
  Future<List<PlacementDrive>> fetchNextBatch({
    int limit = 50,
    JobDiscoveryFilters filters = const JobDiscoveryFilters(),
  });

  Future<void> reset();

  Future<PersistenceResult> recordSwipe(
    String driveId,
    SwipeDirection direction,
  );

  Future<PersistenceResult> applyToDrive(String driveId);

  Future<void> deleteSwipe(String driveId);

  Future<void> deleteApplication(String driveId);

  Future<List<PlacementDrive>> fetchSavedJobs();

  Future<PlacementDrive?> fetchDriveById(String driveId);
}
