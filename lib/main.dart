import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/backend_configuration.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/authentication_bloc.dart';
import 'features/auth/bloc/authentication_event.dart';
import 'features/auth/data/authentication_repository.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables if a local .env asset exists (dev builds).
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // No .env present — falls back to --dart-define values or the
    // placeholder defaults in BackendConfiguration.
  }

  await _initializeSupabaseIfConfigured();

  runApp(const InternloomApp());
}

/// Boots the Supabase SDK, choosing the right OAuth flow per platform.
///
/// - Web uses the implicit flow: password-recovery links embed the token
///   directly in the URL fragment (#access_token=...&type=recovery), so no
///   locally-stored code_verifier is needed — this makes clicking the link
///   in any tab/window work reliably.
/// - Mobile uses PKCE, the recommended secure flow for native apps, since
///   the code_verifier can safely live in app-local storage between the
///   browser hand-off and the deep-link callback.
Future<void> _initializeSupabaseIfConfigured() async {
  if (!BackendConfiguration.hasValidCredentials) return;

  try {
    await Supabase.initialize(
      url: BackendConfiguration.supabaseProjectUrl,
      publishableKey: BackendConfiguration.supabaseAnonymousKey,
      authOptions: FlutterAuthClientOptions(
        authFlowType: kIsWeb ? AuthFlowType.implicit : AuthFlowType.pkce,
      ),
    );
  } catch (_) {
    // Any startup failure here is surfaced later when a screen actually
    // tries to perform an auth operation, rather than crashing the app.
  }
}

class InternloomApp extends StatefulWidget {
  const InternloomApp({super.key});

  @override
  State<InternloomApp> createState() => _InternloomAppState();
}

class _InternloomAppState extends State<InternloomApp> {
  final _deepLinkListener = AppLinks();

  @override
  void initState() {
    super.initState();
    _listenForIncomingOAuthCallbacks();
  }

  /// Listens for deep links arriving while the app is already running —
  /// this is how Google/LinkedIn OAuth callbacks and password-recovery
  /// links reach the app after the user finishes in the browser.
  void _listenForIncomingOAuthCallbacks() {
    _deepLinkListener.uriLinkStream.listen(
      _handleIncomingDeepLink,
      onError: (_) {
        // Malformed or unexpected links are ignored rather than crashing
        // the auth flow.
      },
    );
  }

  Future<void> _handleIncomingDeepLink(Uri uri) async {
    final rawUri = uri.toString();

    final isPasswordRecoveryLink =
        rawUri.contains('reset-password-callback') || rawUri.contains('type=recovery');
    if (isPasswordRecoveryLink && mounted) {
      context.read<AuthenticationBloc>().add(const PasswordRecoveryModeTriggered());
    }

    final isAppOAuthCallback = rawUri.startsWith('io.internloom.app://');
    if (isAppOAuthCallback) {
      try {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
      } catch (_) {
        // Invalid/expired token in the callback URL — nothing to recover
        // here, the auth screen will simply stay in its current state.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => AuthenticationRepository(),
      child: BlocProvider(
        create: (context) => AuthenticationBloc(
          authenticationRepository: context.read<AuthenticationRepository>(),
        ),
        child: MaterialApp(
          title: 'Internloom Student Portal',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
