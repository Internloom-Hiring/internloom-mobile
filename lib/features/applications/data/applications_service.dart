import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/application_entry.dart';

/// Data layer for Task 1 (list) and Task 3 (realtime) — Developer 3.
///
/// Resolves and caches `students.id` from the signed-in user's
/// `profile_id` (== auth.uid()), same pattern Developer 2 uses for the
/// swipe feed: every student-scoped query uses students.id, never
/// auth.uid() directly, so a stale/mismatched id can't slip through
/// under RLS policies keyed on the resolved id.
class ApplicationsService {
  ApplicationsService(this._client);

  final SupabaseClient _client;

  String? _cachedStudentId;

  Future<String> _studentId() async {
    if (_cachedStudentId != null) return _cachedStudentId!;
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('ApplicationsService used before a user is signed in.');
    }
    final row = await _client
        .from('students')
        .select('id')
        .eq('profile_id', uid)
        .single();
    _cachedStudentId = row['id'] as String;
    return _cachedStudentId!;
  }

  /// Task 1 — single applications list, no separate "interested" list.
  /// This never writes to `applications`; Developer 2's swipe-right is
  /// the only thing that creates rows here.
  Future<List<ApplicationEntry>> fetchApplications() async {
    final studentId = await _studentId();
    final rows = await _client
        .from('applications')
        .select(
          'id, drive_id, status, application_date, '
          'placement_drives(job_title, companies(company_name))',
        )
        .eq('student_id', studentId)
        .order('application_date', ascending: false);

    return (rows as List)
        .map((r) => ApplicationEntry.fromJoinedRow(r as Map<String, dynamic>))
        .toList();
  }

  /// Task 3 — realtime status updates. A raw postgres_changes payload
  /// only carries the columns that changed on `applications`, not the
  /// joined drive title / company name the list needs to render, so
  /// each event triggers a full re-fetch of the joined list rather than
  /// trying to patch one row in place. Simpler and correct; the list is
  /// small enough (one student's own applications) that this is cheap.
  Stream<List<ApplicationEntry>> watchApplications() {
    final controller = StreamController<List<ApplicationEntry>>();

    _studentId().then((studentId) {
      fetchApplications().then(controller.add).catchError(controller.addError);

      _client
          .channel('applications-student-$studentId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'applications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'student_id',
              value: studentId,
            ),
            callback: (_) {
              fetchApplications().then(controller.add).catchError(controller.addError);
            },
          )
          .subscribe();
    }).catchError(controller.addError);

    return controller.stream;
  }
}
