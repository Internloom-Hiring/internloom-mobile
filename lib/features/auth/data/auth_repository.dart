import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Concrete repository wrapping Supabase Auth APIs
class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  /// Returns the appropriate redirect URL for OAuth flows.
  /// On web, Supabase handles redirects natively (null = use Supabase default).
  /// On mobile, we use a custom URI scheme registered in AndroidManifest.xml / Info.plist.
  static String? get _redirectTo =>
      kIsWeb ? null : 'io.internloom.app://login-callback';

  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
  bool get isAuthenticated => currentSession != null;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Signs up with email and password, sending user full_name in data metadata
  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim()},
    );
  }

  /// Signs in with email and password
  Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Initiates Google OAuth flow via Supabase.
  /// Opens browser → user authenticates → browser redirects to
  /// io.internloom.app://login-callback → Android/iOS intercepts deep link
  /// → app receives URI → Supabase exchanges code for session.
  Future<bool> signInWithGoogle() async {
    return await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _redirectTo,
    );
  }

  /// Initiates LinkedIn OIDC flow via Supabase
  Future<bool> signInWithLinkedIn() async {
    return await _supabase.auth.signInWithOAuth(
      OAuthProvider.linkedin,
      redirectTo: _redirectTo,
    );
  }

  /// Triggers password reset email via Supabase Auth.
  /// Uses deep link scheme on mobile (io.internloom.app://reset-password-callback)
  /// or null on Web so Supabase uses current origin.
  Future<void> resetPasswordForEmail({required String email}) async {
    final String? redirect =
        kIsWeb ? null : 'io.internloom.app://reset-password-callback';
    await _supabase.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirect,
    );
  }

  /// Updates the authenticated user's password (used during password recovery flow)
  Future<UserResponse> updatePassword(String newPassword) async {
    return await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Signs out current session
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
