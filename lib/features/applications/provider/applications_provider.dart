import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/applications_service.dart';
import '../data/models/application_entry.dart';

/// ChangeNotifier, not bloc — matches the Student Side profile module's
/// existing pattern (features/profile/provider/), which already coexists
/// fine with Authentication's BlocProvider in main.dart. No reason to
/// force this feature into bloc either.
class ApplicationsProvider extends ChangeNotifier {
  ApplicationsProvider({ApplicationsService? service})
      : _service = service ?? ApplicationsService(Supabase.instance.client);

  final ApplicationsService _service;
  StreamSubscription<List<ApplicationEntry>>? _sub;

  List<ApplicationEntry> applications = const [];
  bool isLoading = true;
  String? errorMessage;

  /// Kicks off the initial fetch and the realtime subscription together
  /// (Task 1 + Task 3 share one stream). Call once, e.g. from the
  /// screen's initState via a post-frame callback.
  void start() {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    _sub?.cancel();
    _sub = _service.watchApplications().listen(
      (list) {
        applications = list;
        isLoading = false;
        errorMessage = null;
        notifyListeners();
      },
      onError: (Object error, StackTrace stack) {
        debugPrint('[ApplicationsProvider] watchApplications failed: $error\n$stack');
        isLoading = false;
        errorMessage = 'Could not load applications. Pull down to retry.';
        notifyListeners();
      },
    );
  }

  Future<void> refresh() async {
    try {
      applications = await _service.fetchApplications();
      errorMessage = null;
    } catch (error, stack) {
      debugPrint('[ApplicationsProvider] refresh failed: $error\n$stack');
      errorMessage = 'Could not refresh applications.';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
