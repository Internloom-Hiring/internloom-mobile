import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase Auth that centralizes every way a student
/// can sign into Internloom: email/password, Google OAuth, and LinkedIn
/// OAuth (OIDC). Keeping every auth call in one place means the Bloc layer
/// never has to know anything about Supabase directly.
class AuthenticationRepository {
  final SupabaseClient _supabaseClient;

  AuthenticationRepository({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  /// Where the browser should send the user back to after they finish
  /// authenticating with an external OAuth provider.
  ///
  /// - On web, we redirect to whatever origin the app is currently running
  ///   on (e.g. http://localhost:3000), so local dev and each deployed
  ///   environment redirect correctly without hardcoding a URL.
  /// - On Android/iOS, we redirect to our registered custom URI scheme,
  ///   which the OS hands back to this app instead of a browser tab.
  static String get _oauthRedirectUri =>
      kIsWeb ? Uri.base.origin : 'io.internloom.app://login-callback';

  /// The redirect target used specifically for the "reset password" email
  /// link, kept separate from OAuth so the app can tell the two flows apart.
  static String get _passwordResetRedirectUri => kIsWeb
      ? Uri.base.origin
      : 'io.internloom.app://reset-password-callback';

  User? get currentAuthenticatedUser => _supabaseClient.auth.currentUser;
  Session? get currentUserSession => _supabaseClient.auth.currentSession;
  bool get hasActiveSession => currentUserSession != null;

  /// Fires whenever Supabase's underlying auth state changes — sign in,
  /// sign out, token refresh, or password-recovery mode being entered.
  Stream<AuthState> get authenticationStateStream =>
      _supabaseClient.auth.onAuthStateChange;

  /// Creates a brand-new account with email + password, storing the
  /// student's full name as user metadata.
  Future<AuthResponse> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _supabaseClient.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim()},
    );
  }

  /// Signs an existing student in using their email + password.
  Future<AuthResponse> authenticateWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _supabaseClient.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Kicks off the Google OAuth flow through Supabase.
  ///
  /// Flow: opens the system browser → student authenticates with Google →
  /// browser redirects to [_oauthRedirectUri] → the OS hands that deep link
  /// back to this app → Supabase exchanges the returned code for a session.
  Future<bool> authenticateWithGoogleOAuth() async {
    return await _supabaseClient.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _oauthRedirectUri,
    );
  }

  /// Kicks off the LinkedIn OIDC flow through Supabase. Same round-trip as
  /// Google above, just against LinkedIn's OpenID Connect provider.
  Future<bool> authenticateWithLinkedInOAuth() async {
    return await _supabaseClient.auth.signInWithOAuth(
      OAuthProvider.linkedinOidc,
      redirectTo: _oauthRedirectUri,
    );
  }

  /// Sends a password-reset email to the given address. The link inside
  /// that email will eventually redirect to [_passwordResetRedirectUri].
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _supabaseClient.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: _passwordResetRedirectUri,
    );
  }

  /// Sets a new password for the currently authenticated user — used at
  /// the end of the "forgot password" recovery flow.
  Future<UserResponse> updateUserPassword(String newPassword) async {
    return await _supabaseClient.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Ends the current session and clears local auth state.
  Future<void> signOutCurrentUser() async {
    await _supabaseClient.auth.signOut();
  }
}
