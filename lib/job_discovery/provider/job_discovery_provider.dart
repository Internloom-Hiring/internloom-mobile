import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/job_discovery_filter_store.dart';
import '../data/job_discovery_repository.dart';
import '../data/models/job_discovery_filters.dart';
import '../data/models/placement_drive.dart';
import '../data/models/swipe_action.dart';
import '../data/supabase_job_discovery_repository.dart';

enum JobDiscoveryLoadState {
  initial,
  loading,
  loaded,
  loadingMore,
  error,
}

/// Owns the local ranked feed and the asynchronous swipe persistence.
///
/// Card movement is local and immediate. Supabase writes run independently
/// so a network round trip never blocks the swipe animation.
class JobDiscoveryProvider extends ChangeNotifier {
  JobDiscoveryProvider({
    JobDiscoveryRepository? repository,
    JobDiscoveryFilterStore? filterStore,
    this.batchSize = 50,
    this.prefetchThreshold = 10,
  })  : _repository = repository ?? SupabaseJobDiscoveryRepository(),
        _filterStore = filterStore ?? JobDiscoveryFilterStore();

  final JobDiscoveryRepository _repository;
  final JobDiscoveryFilterStore _filterStore;
  final int batchSize;
  final int prefetchThreshold;

  final List<PlacementDrive> _cards = <PlacementDrive>[];

  JobDiscoveryLoadState _loadState = JobDiscoveryLoadState.initial;
  JobDiscoveryFilters _filters = const JobDiscoveryFilters();
  String? _errorMessage;
  bool _hasReachedEnd = false;
  bool _requestInFlight = false;
  bool _filtersLoaded = false;

  _LastSwipe? _lastSwipe;
  int _swipeSequence = 0;

  List<PlacementDrive> get cards => List.unmodifiable(_cards);
  JobDiscoveryLoadState get loadState => _loadState;
  JobDiscoveryFilters get filters => _filters;
  String? get errorMessage => _errorMessage;
  bool get hasReachedEnd => _hasReachedEnd;
  bool get isLoading => _requestInFlight;
  bool get hasActiveFilters => !_filters.isEmpty;
  bool get canUndo => _lastSwipe != null;

  Future<void> loadInitial() async {
    if (_requestInFlight) return;

    if (!_filtersLoaded) {
      _filters = await _filterStore.load();
      _filtersLoaded = true;
    }

    await _repository.reset();

    _cards.clear();
    _hasReachedEnd = false;
    _errorMessage = null;
    _loadState = JobDiscoveryLoadState.loading;
    notifyListeners();

    await _fetchNext();
  }

  Future<void> applyFilters({
    required String location,
    required String ctc,
  }) async {
    _filters = JobDiscoveryFilters(
      location: location.trim(),
      ctc: ctc.trim(),
    );

    _filtersLoaded = true;
    await _filterStore.save(_filters);

    await _repository.reset();

    _cards.clear();
    _hasReachedEnd = false;
    _errorMessage = null;
    _loadState = JobDiscoveryLoadState.loading;
    notifyListeners();

    await _fetchNext();
  }

  Future<void> clearFilters() async {
    _filters = const JobDiscoveryFilters();
    _filtersLoaded = true;
    await _filterStore.clear();

    await _repository.reset();

    _cards.clear();
    _hasReachedEnd = false;
    _errorMessage = null;
    _loadState = JobDiscoveryLoadState.loading;
    notifyListeners();

    await _fetchNext();
  }

  Future<void> maybePrefetch(int remainingCards) async {
    if (_hasReachedEnd || _requestInFlight) return;
    if (remainingCards > prefetchThreshold) return;

    await _fetchNext();
  }

  Future<void> _fetchNext() async {
    _requestInFlight = true;
    _loadState = _cards.isEmpty
        ? JobDiscoveryLoadState.loading
        : JobDiscoveryLoadState.loadingMore;
    notifyListeners();

    try {
      final batch = await _repository.fetchNextBatch(
        limit: batchSize,
        filters: _filters,
      );

      _cards.addAll(batch);
      _hasReachedEnd = batch.length < batchSize;
      _errorMessage = null;
      _loadState = JobDiscoveryLoadState.loaded;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      _loadState = JobDiscoveryLoadState.error;
    } finally {
      _requestInFlight = false;
      notifyListeners();
    }
  }

  /// Immediately removes the top card and starts its database write.
  ///
  /// Only one action is undoable. The 3-second timer is independent of the
  /// network request.
  void swipeTop(SwipeDirection direction) {
    if (_cards.isEmpty) return;

    final drive = _cards.removeAt(0);
    final action = _LastSwipe(
      id: ++_swipeSequence,
      drive: drive,
      direction: direction,
    );

    _lastSwipe?.timer?.cancel();
    _lastSwipe = action;

    notifyListeners();
    unawaited(maybePrefetch(_cards.length));

    final persistence = _persistSwipe(action);
    action.persistence = persistence;

    unawaited(persistence.catchError((Object error) {
      _restoreFailedSwipe(action, error);
    }));

    action.timer = Timer(const Duration(seconds: 3), () {
      if (identical(_lastSwipe, action)) {
        _lastSwipe = null;
        notifyListeners();
      }
    });
  }

  Future<void> _persistSwipe(_LastSwipe action) async {
    if (action.direction == SwipeDirection.right) {
      action.result = await _repository.applyToDrive(action.drive.id);
    } else {
      action.result = await _repository.recordSwipe(
        action.drive.id,
        action.direction,
      );
    }
  }

  void _restoreFailedSwipe(_LastSwipe action, Object error) {
    if (!identical(_lastSwipe, action)) return;

    action.timer?.cancel();
    _lastSwipe = null;
    _cards.insert(0, action.drive);
    _errorMessage = _friendlyError(error);
    notifyListeners();
  }

  /// Reverses the most recent persisted action if still inside the 3-second
  /// window. If the database write is still running, undo waits for that write
  /// to finish before reversing it.
  Future<bool> undoLastSwipe() async {
    final action = _lastSwipe;
    if (action == null) return false;

    action.timer?.cancel();
    _lastSwipe = null;
    notifyListeners();

    try {
      await action.persistence;

      final result = action.result;
      if (result?.created != true) {
        // The row/application existed before this swipe. Never delete an
        // existing application or swipe just because undo was requested.
        _cards.insert(0, action.drive);
        notifyListeners();
        return false;
      }

      if (action.direction == SwipeDirection.right) {
        await _repository.deleteApplication(action.drive.id);
      } else {
        await _repository.deleteSwipe(action.drive.id);
      }

      _cards.insert(0, action.drive);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      _cards.insert(0, action.drive);
      _errorMessage = _friendlyError(error);
      notifyListeners();
      return false;
    }
  }

  Future<void> retry() async {
    await loadInitial();
  }

  String _friendlyError(Object error, [StackTrace? stackTrace]) {
    debugPrint('JOB DISCOVERY ERROR: $error');
    if (stackTrace != null) {
      debugPrint('JOB DISCOVERY STACK: $stackTrace');
    }

    if (error is StateError) return error.message;
    if (error is Exception) {
      final message = error.toString();
      if (message.contains('No student record')) {
        return 'Your student profile could not be resolved. Complete your student profile and try again.';
      }
    }
    return 'DEV2 ERROR: $error';
  }

  @override
  void dispose() {
    _lastSwipe?.timer?.cancel();
    super.dispose();
  }
}

class _LastSwipe {
  _LastSwipe({
    required this.id,
    required this.drive,
    required this.direction,
  });

  final int id;
  final PlacementDrive drive;
  final SwipeDirection direction;

  PersistenceResult? result;
  late Future<void> persistence;
  Timer? timer;
}
