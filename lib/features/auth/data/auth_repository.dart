import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Concrete repository wrapping Supabase Auth APIs
class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  /// Returns the appropriate redirect URL for OAuth and email flows.
  /// On web, we use the current page origin (e.g. http://localhost:3000) so
  /// Supabase redirects back to the running dev server and NOT the Site URL.
  /// On mobile, we use a custom URI scheme registered in AndroidManifest / Info.plist.
  static String get _redirectTo =>
      kIsWeb ? Uri.base.origin : 'io.internloom.app://login-callback';

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

  /// Signs up a company, inserting into profiles and companies table.
  /// Skips actual file upload for now due to missing storage bucket.
  Future<AuthResponse> signUpCompany({
    required String username,
    required String email,
    required String password,
    required String companyName,
    required String hrName,
    required String hrContact,
    String? website,
    String? description,
    String? incorporationCertPath,
    String? pitchDeckPath,
  }) async {
    // 1. Sign up the user
    final response = await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': hrName.trim()},
    );

    final user = response.user;
    if (user != null) {
      // 2. Insert into profiles
      await _supabase.from('profiles').insert({
        'id': user.id,
        'username': username.trim(),
        'role': 'company',
        'is_active': true,
      });

      // 3. (Skipped) File uploads would go here, updating incorporationCertPath / pitchDeckPath
      // PENDING: Storage bucket needs to be created first (e.g. company-verification-docs)

      // 4. Insert into companies
      await _supabase.from('companies').insert({
        'profile_id': user.id,
        'company_name': companyName.trim(),
        'hr_name': hrName.trim(),
        'hr_contact': hrContact.trim(),
        'website': website?.trim(),
        'description': description?.trim(),
        'incorporation_cert_path': incorporationCertPath,
        'pitch_deck_path': pitchDeckPath,
        // approval_status uses default 'pending'
      });
    }

    return response;
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
      OAuthProvider.linkedinOidc,
      redirectTo: _redirectTo,
    );
  }

  /// Triggers password reset email via Supabase Auth.
  /// redirectTo is derived from _redirectTo: web → current origin, mobile → custom scheme.
  Future<void> resetPasswordForEmail({required String email}) async {
    final String passwordResetRedirect = kIsWeb
        ? Uri.base.origin
        : 'io.internloom.app://reset-password-callback';
    await _supabase.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: passwordResetRedirect,
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
