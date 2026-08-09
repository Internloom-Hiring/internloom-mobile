import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads and exposes the Supabase project credentials that the whole app
/// depends on for authentication (email/password + Google + LinkedIn OAuth).
///
/// Credentials are resolved in this order of priority:
///   1. `--dart-define` values passed in at build time (used for CI/CD and
///      release builds so secrets never live in the repo).
///   2. Values loaded from the local `.env` file (used during development).
///   3. Obvious placeholder fallbacks, so the app can still boot and show a
///      helpful "not configured" state instead of crashing on startup.
class BackendConfiguration {
  BackendConfiguration._();

  /// The Supabase project URL, e.g. https://xxxxx.supabase.co
  static String get supabaseProjectUrl {
    const buildTimeUrl = String.fromEnvironment('SUPABASE_URL');
    if (buildTimeUrl.isNotEmpty) return buildTimeUrl;
    return dotenv.env['SUPABASE_URL'] ?? 'https://your-project-id.supabase.co';
  }

  /// The Supabase public (anonymous) API key — safe to ship in the client.
  static String get supabaseAnonymousKey {
    const buildTimeKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (buildTimeKey.isNotEmpty) return buildTimeKey;
    return dotenv.env['SUPABASE_ANON_KEY'] ?? 'your-actual-anon-key-here';
  }

  /// True once real project credentials have been supplied, false while
  /// we're still looking at the placeholder defaults above.
  static bool get hasValidCredentials {
    final urlLooksReal =
        supabaseProjectUrl.isNotEmpty && !supabaseProjectUrl.contains('your-project-id');
    final keyLooksReal =
        supabaseAnonymousKey.isNotEmpty && !supabaseAnonymousKey.contains('your-actual-anon-key');
    return urlLooksReal && keyLooksReal;
  }
}
