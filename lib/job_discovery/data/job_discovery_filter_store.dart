import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/job_discovery_filters.dart';

/// Persists the two discovery filters locally so they survive navigation and
/// app restarts. The filters themselves are still applied by Supabase.
class JobDiscoveryFilterStore {
  static const _locationKeyPrefix = 'job_discovery_filter_location';
  static const _ctcKeyPrefix = 'job_discovery_filter_ctc';

  String _key(String prefix) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    return userId == null ? prefix : '$prefix:$userId';
  }

  Future<JobDiscoveryFilters> load() async {
    final prefs = await SharedPreferences.getInstance();

    return JobDiscoveryFilters(
      location: prefs.getString(_key(_locationKeyPrefix)) ?? '',
      ctc: prefs.getString(_key(_ctcKeyPrefix)) ?? '',
    );
  }

  Future<void> save(JobDiscoveryFilters filters) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_key(_locationKeyPrefix), filters.location.trim());
    await prefs.setString(_key(_ctcKeyPrefix), filters.ctc.trim());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_key(_locationKeyPrefix));
    await prefs.remove(_key(_ctcKeyPrefix));
  }
}
