import 'package:postgrest/postgrest.dart';

import '../../features/profile/data/supabase_client_provider.dart';
import 'job_discovery_repository.dart';
import 'models/job_discovery_filters.dart';
import 'models/placement_drive.dart';
import 'models/swipe_action.dart';
import 'student_identity_service.dart';
import 'package:flutter/foundation.dart';

/// Supabase data source for the complete Developer 2 discovery flow.
///
/// The mobile app consumes match_scores.final_score. It never calculates
/// matching scores.
class SupabaseJobDiscoveryRepository implements JobDiscoveryRepository {
  SupabaseJobDiscoveryRepository({
    StudentIdentityService? identityService,
  }) : _identityService = identityService ?? StudentIdentityService();

  static const _matchScoreTable = 'match_scores';
  static const _applicationsTable = 'applications';
  static const _swipesTable = 'swipes';

  final StudentIdentityService _identityService;

  int _offset = 0;
  bool _exclusionsLoaded = false;
  Set<String> _appliedDriveIds = <String>{};
  Set<String> _swipedDriveIds = <String>{};

  @override
  Future<List<PlacementDrive>> fetchNextBatch({
    int limit = 50,
    JobDiscoveryFilters filters = const JobDiscoveryFilters(),
  }) async {
    if (limit <= 0) return const <PlacementDrive>[];

    final studentId = await _identityService.resolveStudentId();
    await _loadExclusions(studentId);

    final results = <PlacementDrive>[];
    var exhausted = false;

    while (results.length < limit && !exhausted) {
      final pageSize = limit;
      final rows = await _fetchRankedPage(
        studentId: studentId,
        offset: _offset,
        limit: pageSize,
        filters: filters,
      );

      _offset += rows.length;
      if (rows.length < pageSize) exhausted = true;

      for (final row in rows) {
        final drive = PlacementDrive.fromMatchScoreRow(row);

        if (drive.status != 'approved') continue;
        if (_appliedDriveIds.contains(drive.id)) continue;
        if (_swipedDriveIds.contains(drive.id)) continue;

        results.add(drive);
        if (results.length == limit) break;
      }

      if (rows.isEmpty) exhausted = true;
    }

    return results;
  }

  Future<List<Map<String, dynamic>>> _fetchRankedPage({
    required String studentId,
    required int offset,
    required int limit,
    required JobDiscoveryFilters filters,
  }) async {
    var query = AppSupabase.client
        .from(_matchScoreTable)
        .select('''
          student_id,
          drive_id,
          final_score,
          placement_drives!inner(
            id,
            company_id,
            job_title,
            job_description,
            eligibility_criteria,
            ctc,
            location,
            application_deadline,
            status
          )
        ''')
        .eq('student_id', studentId)
        .eq('placement_drives.status', 'approved');

    final location = _escapeLike(filters.location);
    if (location.isNotEmpty) {
      query = query.ilike(
        'placement_drives.location',
        '%$location%',
      );
    }

    final ctc = _escapeLike(filters.ctc);
    if (ctc.isNotEmpty) {
      query = query.ilike(
        'placement_drives.ctc',
        '%$ctc%',
      );
    }

    final rows = await query
        .order('final_score', ascending: false)
        .range(offset, offset + limit - 1);

    return rows.cast<Map<String, dynamic>>();
  }

  String _escapeLike(String value) {
    return value
        .trim()
        .replaceAll('\\', '\\\\')
        .replaceAll('%', '\\%')
        .replaceAll('_', '\\_');
  }

  Future<void> _loadExclusions(String studentId) async {
    if (_exclusionsLoaded) return;

    try {
      debugPrint('DEV2: loading applications for student $studentId');

      final applicationRows = await AppSupabase.client
          .from(_applicationsTable)
          .select('drive_id')
          .eq('student_id', studentId);

      debugPrint(
        'DEV2: applications loaded: ${applicationRows.length}',
      );

      _appliedDriveIds = applicationRows
          .map((row) => row['drive_id'] as String?)
          .whereType<String>()
          .toSet();
    } on PostgrestException catch (e, stack) {
      debugPrint('DEV2 APPLICATIONS ERROR');
      debugPrint('code: ${e.code}');
      debugPrint('message: ${e.message}');
      debugPrint('details: ${e.details}');
      debugPrint('hint: ${e.hint}');
      debugPrintStack(stackTrace: stack);
      rethrow;
    }

    try {
      debugPrint('DEV2: loading swipes for student $studentId');

      final swipeRows = await AppSupabase.client
          .from(_swipesTable)
          .select('drive_id')
          .eq('student_id', studentId);

      debugPrint(
        'DEV2: swipes loaded: ${swipeRows.length}',
      );

      _swipedDriveIds = swipeRows
          .map((row) => row['drive_id'] as String?)
          .whereType<String>()
          .toSet();
    } on PostgrestException catch (e, stack) {
      debugPrint('DEV2 SWIPES ERROR');
      debugPrint('code: ${e.code}');
      debugPrint('message: ${e.message}');
      debugPrint('details: ${e.details}');
      debugPrint('hint: ${e.hint}');
      debugPrintStack(stackTrace: stack);
      rethrow;
    }

    _exclusionsLoaded = true;
  }

  @override
  Future<PersistenceResult> recordSwipe(
    String driveId,
    SwipeDirection direction,
  ) async {
    if (direction == SwipeDirection.right) {
      throw ArgumentError('Right swipe must create an application.');
    }

    final studentId = await _identityService.resolveStudentId();

    try {
      await AppSupabase.client.from(_swipesTable).insert({
        'student_id': studentId,
        'drive_id': driveId,
        'direction': direction == SwipeDirection.left ? 'left' : 'up',
      });

      _swipedDriveIds.add(driveId);
      _exclusionsLoaded = true;

      return const PersistenceResult(created: true);
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        _swipedDriveIds.add(driveId);
        _exclusionsLoaded = true;
        return const PersistenceResult(created: false);
      }
      rethrow;
    }
  }

  @override
  Future<PersistenceResult> applyToDrive(String driveId) async {
    final studentId = await _identityService.resolveStudentId();

    try {
      await AppSupabase.client.from(_applicationsTable).insert({
        'student_id': studentId,
        'drive_id': driveId,
      });

      _appliedDriveIds.add(driveId);
      _exclusionsLoaded = true;

      return const PersistenceResult(created: true);
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        _appliedDriveIds.add(driveId);
        _exclusionsLoaded = true;
        return const PersistenceResult(created: false);
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteSwipe(String driveId) async {
    final studentId = await _identityService.resolveStudentId();

    await AppSupabase.client
        .from(_swipesTable)
        .delete()
        .eq('student_id', studentId)
        .eq('drive_id', driveId);

    _swipedDriveIds.remove(driveId);
    _exclusionsLoaded = true;
  }

  @override
  Future<void> deleteApplication(String driveId) async {
    final studentId = await _identityService.resolveStudentId();

    await AppSupabase.client
        .from(_applicationsTable)
        .delete()
        .eq('student_id', studentId)
        .eq('drive_id', driveId);

    _appliedDriveIds.remove(driveId);
    _exclusionsLoaded = true;
  }

  @override
  Future<List<PlacementDrive>> fetchSavedJobs() async {
    final studentId = await _identityService.resolveStudentId();

    final rows = await AppSupabase.client
        .from(_swipesTable)
        .select('''
          drive_id,
          direction,
          created_at,
          placement_drives!inner(
            id,
            company_id,
            job_title,
            job_description,
            eligibility_criteria,
            ctc,
            location,
            application_deadline,
            status
          )
        ''')
        .eq('student_id', studentId)
        .eq('direction', 'up')
        .order('created_at', ascending: false);

    final applicationRows = await AppSupabase.client
        .from(_applicationsTable)
        .select('drive_id')
        .eq('student_id', studentId);

    final appliedIds = applicationRows
        .map((row) => row['drive_id'] as String?)
        .whereType<String>()
        .toSet();

    final now = DateTime.now();

    return rows
        .map((row) => PlacementDrive.fromMatchScoreRow({
              'final_score': 0,
              'placement_drives': row['placement_drives'],
            }))
        .where((drive) {
          if (appliedIds.contains(drive.id)) return false;
          if (drive.status != 'approved') return false;

          final deadline = drive.applicationDeadline;
          if (deadline == null) return true;
          return deadline.isAfter(now);
        })
        .toList();
  }

  @override
  Future<PlacementDrive?> fetchDriveById(String driveId) async {
    final row = await AppSupabase.client
        .from('placement_drives')
        .select('''
          id,
          company_id,
          job_title,
          job_description,
          eligibility_criteria,
          ctc,
          location,
          application_deadline,
          status
        ''')
        .eq('id', driveId)
        .maybeSingle();

    if (row == null) return null;

    return PlacementDrive(
      id: row['id'] as String,
      companyId: row['company_id'] as String,
      jobTitle: row['job_title'] as String? ?? '',
      jobDescription: row['job_description'] as String? ?? '',
      eligibilityCriteria: row['eligibility_criteria'] as String?,
      ctc: row['ctc'] as String?,
      location: row['location'] as String?,
      applicationDeadline: _parseDate(row['application_deadline']),
      status: row['status'] as String? ?? '',
      finalScore: 0,
    );
  }

  DateTime? _parseDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  Future<void> reset() async {
    _offset = 0;
    _exclusionsLoaded = false;
    _appliedDriveIds = <String>{};
    _swipedDriveIds = <String>{};
    _identityService.clear();
  }
}
