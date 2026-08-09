import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../core/utils/error_formatter.dart';
import '../../../core/utils/validators.dart';
import '../data/authentication_repository.dart';
import 'authentication_event.dart';
import 'authentication_state.dart';

/// Owns every piece of student-authentication state for the app: email
/// login/registration, Google OAuth, LinkedIn OAuth, password reset/update,
/// and logout. UI screens only ever talk to this Bloc — never directly to
/// [AuthenticationRepository] — so validation and error formatting stay
/// consistent everywhere.
class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  final AuthenticationRepository authenticationRepository;
  late final StreamSubscription<supabase.AuthState> _sessionSubscription;

  AuthenticationBloc({required this.authenticationRepository})
      : super(const AuthenticationInitial()) {
    on<ApplicationLaunched>(_handleApplicationLaunched);
    on<EmailPasswordLoginRequested>(_handleEmailPasswordLogin);
    on<EmailPasswordRegistrationRequested>(_handleEmailPasswordRegistration);
    on<PasswordResetEmailRequested>(_handlePasswordResetEmailRequest);
    on<GoogleOAuthLoginRequested>(_handleGoogleOAuthLogin);
    on<LinkedInOAuthLoginRequested>(_handleLinkedInOAuthLogin);
    on<UserLogoutRequested>(_handleUserLogout);
    on<PasswordRecoveryModeTriggered>(_handlePasswordRecoveryModeTriggered);
    on<NewPasswordSubmitted>(_handleNewPasswordSubmitted);
    on<_SupabaseSessionDetected>(_handleSupabaseSessionDetected);

    // Supabase's own auth stream is the source of truth for anything that
    // happens outside a direct button tap — most importantly, the OAuth
    // deep-link callback for Google/LinkedIn landing back in the app, and
    // the moment a password-recovery link is opened.
    _sessionSubscription = authenticationRepository.authenticationStateStream
        .listen(_reactToSupabaseAuthChange);
  }

  void _reactToSupabaseAuthChange(supabase.AuthState authChange) {
    final changeEvent = authChange.event;
    final session = authChange.session;

    if (changeEvent == supabase.AuthChangeEvent.passwordRecovery) {
      add(const PasswordRecoveryModeTriggered());
      return;
    }

    final sessionJustEstablished =
        changeEvent == supabase.AuthChangeEvent.signedIn ||
            changeEvent == supabase.AuthChangeEvent.tokenRefreshed;
    if (sessionJustEstablished && session != null && state is! UserAuthenticated) {
      add(_SupabaseSessionDetected(session: session));
      return;
    }

    if (changeEvent == supabase.AuthChangeEvent.signedOut &&
        state is! UserNotAuthenticated) {
      add(const UserLogoutRequested());
    }
  }

  @override
  Future<void> close() {
    _sessionSubscription.cancel();
    return super.close();
  }

  Future<void> _handleApplicationLaunched(
    ApplicationLaunched event,
    Emitter<AuthenticationState> emit,
  ) async {
    try {
      if (kIsWeb) {
        final recoveryLinkState = _inspectWebRecoveryLink();
        if (recoveryLinkState != null) {
          emit(recoveryLinkState);
          return;
        }
      }

      final alreadySignedIn = authenticationRepository.hasActiveSession &&
          authenticationRepository.currentAuthenticatedUser != null;

      emit(
        alreadySignedIn
            ? UserAuthenticated(authenticationRepository.currentAuthenticatedUser!)
            : const UserNotAuthenticated(),
      );
    } catch (_) {
      emit(const UserNotAuthenticated());
    }
  }

  /// On web, Supabase communicates password-recovery outcomes through the
  /// URL itself rather than a native deep link. This checks both the query
  /// string (for expired/invalid-link errors) and the URL fragment (for a
  /// valid, active recovery session) and returns the matching state, or
  /// null if there's nothing recovery-related to report.
  AuthenticationState? _inspectWebRecoveryLink() {
    final queryParameters = Uri.base.queryParameters;
    if (queryParameters.containsKey('error')) {
      final errorCode =
          queryParameters['error_code'] ?? queryParameters['error'] ?? '';
      final errorDescription = queryParameters['error_description']
              ?.replaceAll('+', ' ')
              .replaceAll('%20', ' ') ??
          'The link has expired or is invalid.';

      final linkIsExpiredOrUsed =
          errorCode == 'otp_expired' || errorCode == 'access_denied';
      if (linkIsExpiredOrUsed) {
        return AuthenticationFailed(
          'This password reset link has expired or was already used. '
          'Please request a new one. ($errorDescription)',
        );
      }
      return AuthenticationFailed(errorDescription);
    }

    final urlFragment = Uri.base.fragment;
    final isActiveRecoveryLink = urlFragment.contains('type=recovery') ||
        urlFragment.contains('reset-password-callback');
    if (isActiveRecoveryLink) {
      return const PasswordRecoveryModeActive();
    }

    return null;
  }

  Future<void> _handleEmailPasswordLogin(
    EmailPasswordLoginRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    final validationError = Validators.validateEmail(event.email) ??
        Validators.validatePassword(event.password);
    if (validationError != null) {
      emit(AuthenticationFailed(validationError));
      return;
    }

    emit(const AuthenticationInProgress());
    try {
      final response = await authenticationRepository.authenticateWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      if (response.user != null) {
        emit(UserAuthenticated(response.user!));
      } else {
        emit(const AuthenticationFailed('Login failed. Please check your credentials.'));
      }
    } catch (e) {
      emit(AuthenticationFailed(ErrorFormatter.format(e)));
    }
  }

  Future<void> _handleEmailPasswordRegistration(
    EmailPasswordRegistrationRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    final validationError = Validators.validateName(event.fullName) ??
        Validators.validateEmail(event.email) ??
        Validators.validatePassword(event.password) ??
        Validators.validateConfirmPassword(event.password, event.confirmPassword);
    if (validationError != null) {
      emit(AuthenticationFailed(validationError));
      return;
    }

    emit(const AuthenticationInProgress());
    try {
      final response = await authenticationRepository.registerWithEmailAndPassword(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
      );

      if (response.user == null) {
        emit(const AuthenticationFailed('Registration failed. Please try again.'));
        return;
      }

      // A null session after sign-up means Supabase is waiting on the
      // student to click the verification link in their inbox.
      final needsEmailVerification = response.session == null;
      emit(
        needsEmailVerification
            ? EmailVerificationPending(event.email)
            : UserAuthenticated(response.user!),
      );
    } catch (e) {
      emit(AuthenticationFailed(ErrorFormatter.format(e)));
    }
  }

  Future<void> _handlePasswordResetEmailRequest(
    PasswordResetEmailRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    final validationError = Validators.validateEmail(event.email);
    if (validationError != null) {
      emit(AuthenticationFailed(validationError));
      return;
    }

    emit(const AuthenticationInProgress());
    try {
      await authenticationRepository.sendPasswordResetEmail(email: event.email);
      emit(PasswordResetEmailSent(event.email));
    } catch (e) {
      emit(AuthenticationFailed(ErrorFormatter.format(e)));
    }
  }

  Future<void> _handleGoogleOAuthLogin(
    GoogleOAuthLoginRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    await _runOAuthFlow(
      emit: emit,
      providerName: 'Google',
      launchOAuth: authenticationRepository.authenticateWithGoogleOAuth,
    );
  }

  Future<void> _handleLinkedInOAuthLogin(
    LinkedInOAuthLoginRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    await _runOAuthFlow(
      emit: emit,
      providerName: 'LinkedIn',
      launchOAuth: authenticationRepository.authenticateWithLinkedInOAuth,
    );
  }

  /// Shared plumbing for every OAuth provider: show the loading state,
  /// launch the browser hand-off, and surface a clear failure message if
  /// the student cancels or the provider rejects the request. The actual
  /// "signed in" state gets emitted separately, once the deep-link callback
  /// comes back through [_reactToSupabaseAuthChange].
  Future<void> _runOAuthFlow({
    required Emitter<AuthenticationState> emit,
    required String providerName,
    required Future<bool> Function() launchOAuth,
  }) async {
    emit(const AuthenticationInProgress());
    try {
      final browserLaunchedSuccessfully = await launchOAuth();
      if (!browserLaunchedSuccessfully) {
        emit(AuthenticationFailed('$providerName sign-in was cancelled or failed.'));
      }
    } catch (e) {
      emit(AuthenticationFailed(ErrorFormatter.format(e)));
    }
  }

  Future<void> _handleUserLogout(
    UserLogoutRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(const AuthenticationInProgress());
    try {
      await authenticationRepository.signOutCurrentUser();
    } catch (_) {
      // Even if the network call fails, we still want the UI to treat the
      // student as signed out locally rather than getting stuck loading.
    }
    emit(const UserNotAuthenticated());
  }

  /// Fired internally once a Supabase session appears via the auth stream
  /// (e.g. right after a Google/LinkedIn OAuth deep-link callback resolves).
  Future<void> _handleSupabaseSessionDetected(
    _SupabaseSessionDetected event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(UserAuthenticated(event.session.user));
  }

  void _handlePasswordRecoveryModeTriggered(
    PasswordRecoveryModeTriggered event,
    Emitter<AuthenticationState> emit,
  ) {
    emit(const PasswordRecoveryModeActive());
  }

  Future<void> _handleNewPasswordSubmitted(
    NewPasswordSubmitted event,
    Emitter<AuthenticationState> emit,
  ) async {
    final validationError =
        Validators.validatePassword(event.newPassword) ??
            Validators.validateConfirmPassword(event.newPassword, event.confirmPassword);
    if (validationError != null) {
      emit(AuthenticationFailed(validationError));
      return;
    }

    emit(const AuthenticationInProgress());
    try {
      await authenticationRepository.updateUserPassword(event.newPassword);
      emit(const PasswordUpdateSucceeded());
    } catch (e) {
      emit(AuthenticationFailed(ErrorFormatter.format(e)));
    }
  }
}

/// Private, stream-only event — never dispatched by the UI, only by
/// [AuthenticationBloc]'s own Supabase auth-state listener.
class _SupabaseSessionDetected extends AuthenticationEvent {
  final supabase.Session session;

  const _SupabaseSessionDetected({required this.session});

  @override
  List<Object?> get props => [session.accessToken];
}
