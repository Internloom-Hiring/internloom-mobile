import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around the shared Supabase project.
///
/// This is currently scoped under `features/profile/data/` because
/// only this feature's code uses it so far — Authentication's own
/// `AuthRepository` just calls `Supabase.instance.client` directly and
/// has no equivalent wrapper. If Company Side or another feature wants
/// the same `currentUserId` convenience, this is a good candidate to
/// hoist up into `core/` — not done unilaterally here since that's a
/// cross-feature decision, not this feature's to make alone.
///
/// NOTE for the team: Authentication owns the real
/// `Supabase.initialize(...)` call as part of app startup (confirmed —
/// see their `lib/main.dart` / `core/constants/supabase_config.dart`).
/// This file's `initForStandaloneTesting` exists so this feature can
/// run and be tested on its own before merging — once merged, delete
/// `initForStandaloneTesting` and just keep the `client`/`currentUserId`
/// getters, which point at whatever `Supabase.initialize` Authentication
/// already ran.
class AppSupabase {
  AppSupabase._();

  static SupabaseClient get client => Supabase.instance.client;

  /// The live, authenticated user's id — i.e. what `auth.uid()`
  /// resolves to on the database side. This is the ONLY source of
  /// identity every write in this feature should use (see
  /// ProfileService), rather than any id threaded through app state,
  /// so a stale or mismatched value can never be written under RLS
  /// policies keyed on `auth.uid() = profile_id`.
  ///
  /// Confirmed equivalent to Authentication's own
  /// `AuthRepository.currentUser`/`currentSession` — both read the
  /// same underlying `Supabase.instance.client.auth` session.
  static String? get currentUserId => client.auth.currentSession?.user.id;

  /// Reads the URL/anon key from --dart-define so nothing secret is
  /// committed. Run with:
  ///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  static Future<void> initForStandaloneTesting() async {
    const url = String.fromEnvironment('SUPABASE_URL');
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    assert(
      url.isNotEmpty && anonKey.isNotEmpty,
      'Pass --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... '
      'when running this module standalone. In the merged app, remove this '
      'call and rely on Authentication\'s Supabase.initialize instead.',
    );
    // publishableKey, not the deprecated anonKey param — matches
    // Authentication's own real Supabase.initialize() call in main.dart.
    await Supabase.initialize(url: url, publishableKey: anonKey);
  }
}
