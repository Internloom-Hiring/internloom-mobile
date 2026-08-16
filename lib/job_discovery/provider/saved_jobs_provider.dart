import 'package:flutter/foundation.dart';

import '../data/job_discovery_repository.dart';
import '../data/models/placement_drive.dart';
import '../data/supabase_job_discovery_repository.dart';

enum SavedJobsLoadState {
  initial,
  loading,
  loaded,
  error,
}

class SavedJobsProvider extends ChangeNotifier {
  SavedJobsProvider({
    JobDiscoveryRepository? repository,
  }) : _repository = repository ?? SupabaseJobDiscoveryRepository();

  final JobDiscoveryRepository _repository;

  List<PlacementDrive> _jobs = <PlacementDrive>[];
  SavedJobsLoadState _loadState = SavedJobsLoadState.initial;
  String? _errorMessage;

  List<PlacementDrive> get jobs => List.unmodifiable(_jobs);
  SavedJobsLoadState get loadState => _loadState;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _loadState = SavedJobsLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _jobs = await _repository.fetchSavedJobs();
      _loadState = SavedJobsLoadState.loaded;
    } catch (error) {
      _errorMessage = 'Could not load saved jobs. Check your connection and try again.';
      _loadState = SavedJobsLoadState.error;
    }

    notifyListeners();
  }

  Future<bool> unsave(PlacementDrive drive) async {
    try {
      await _repository.deleteSwipe(drive.id);
      _jobs = _jobs.where((item) => item.id != drive.id).toList();
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = 'Could not remove this saved job. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> apply(PlacementDrive drive) async {
    try {
      await _repository.applyToDrive(drive.id);

      // Applying always removes an up-swipe from Saved Jobs, including the
      // case where the application already existed.
      await _repository.deleteSwipe(drive.id);

      _jobs = _jobs.where((item) => item.id != drive.id).toList();
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = 'Could not apply to this job. Please try again.';
      notifyListeners();
      return false;
    }
  }
}
