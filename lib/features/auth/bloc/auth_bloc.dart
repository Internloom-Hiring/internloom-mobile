import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart'
    show WidgetsBinding, WidgetsBindingObserver, AppLifecycleState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../core/utils/error_formatter.dart';
import '../../../core/utils/validators.dart';
import '../data/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Manages Student Authentication State
class AuthBloc extends Bloc<AuthEvent, AuthState> with WidgetsBindingObserver {
  final AuthRepository authRepository;
  late final StreamSubscription<supabase.AuthState> _authSubscription;

  /// True while a Google/LinkedIn OAuth browser tab is open and we're
  /// waiting for either the deep-link callback (success) or the app to
  /// resume in the foreground without one having arrived (cancelled).
  bool _oauthInProgress = false;

  AuthBloc({required this.authRepository}) : super(const AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<ForgotPasswordSubmitted>(_onForgotPasswordSubmitted);
    on<GoogleLoginSubmitted>(_onGoogleLoginSubmitted);
    on<LinkedInLoginSubmitted>(_onLinkedInLoginSubmitted);
    on<LogoutSubmitted>(_onLogoutSubmitted);
    on<PasswordRecoveryRequested>(_onPasswordRecoveryRequested);
    on<UpdatePasswordSubmitted>(_onUpdatePasswordSubmitted);
    on<_AuthStateChanged>(_onAuthStateChanged);
    on<_OAuthResumeCheck>(_onOAuthResumeCheck);

    // Listen to Supabase auth state stream so OAuth deep link callbacks
    // and Password Recovery events automatically update AuthBloc state.
    _authSubscription = authRepository.authStateChanges.listen(
      (supabase.AuthState authState) {
        final event = authState.event;
        final session = authState.session;

        if (event == supabase.AuthChangeEvent.passwordRecovery) {
          add(const PasswordRecoveryRequested());
        } else if ((event == supabase.AuthChangeEvent.signedIn ||
                event == supabase.AuthChangeEvent.tokenRefreshed) &&
            session != null) {
          if (state is! Authenticated) {
            add(_AuthStateChanged(session: session));
          }
        } else if (event == supabase.AuthChangeEvent.signedOut) {
          if (state is! Unauthenticated) {
            add(const LogoutSubmitted());
          }
        }
      },
    );

    WidgetsBinding.instance.addObserver(this);
  }

  /// Detects the app resuming to the foreground (e.g. the user closed the
  /// Google/LinkedIn browser tab without picking an account) while an OAuth
  /// flow is in progress. A short delay lets a genuine successful callback
  /// (which also resumes the app) be processed first; if we're still stuck
  /// on AuthLoading afterwards with no session, the flow was cancelled.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _oauthInProgress) {
      _oauthInProgress = false;
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!isClosed) add(const _OAuthResumeCheck());
      });
    }
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription.cancel();
    return super.close();
  }


  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    try {
      if (kIsWeb) {
        // Check for error redirects from Supabase (e.g. ?error=access_denied&error_code=otp_expired).
        // This happens when a recovery/magic link has expired or been used already.
        final queryParams = Uri.base.queryParameters;
        if (queryParams.containsKey('error')) {
          final code = queryParams['error_code'] ?? queryParams['error'] ?? '';
          final desc = queryParams['error_description']
                  ?.replaceAll('+', ' ')
                  .replaceAll('%20', ' ') ??
              'The link has expired or is invalid.';
          if (code == 'otp_expired' || code == 'access_denied') {
            emit(AuthFailure(
              'This password reset link has expired or was already used. '
              'Please request a new one. ($desc)',
            ));
            return;
          }
          emit(AuthFailure(desc));
          return;
        }

        // Check the URL fragment for an active recovery session.
        // In implicit flow, Supabase redirects with
        // #access_token=...&type=recovery after verifying the OTP.
        final fragment = Uri.base.fragment;
        if (fragment.contains('type=recovery') ||
            fragment.contains('reset-password-callback')) {
          emit(const PasswordRecoveryRequired());
          return;
        }
      }

      if (authRepository.isAuthenticated && authRepository.currentUser != null) {
        emit(Authenticated(authRepository.currentUser!));
      } else {
        emit(const Unauthenticated());
      }
    } catch (_) {
      emit(const Unauthenticated());
    }
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final emailError = Validators.validateEmail(event.email);
    if (emailError != null) {
      emit(AuthFailure(emailError));
      return;
    }

    final passwordError = Validators.validatePassword(event.password);
    if (passwordError != null) {
      emit(AuthFailure(passwordError));
      return;
    }

    emit(const AuthLoading());

    try {
      final response = await authRepository.signInWithEmailPassword(
        email: event.email,
        password: event.password,
      );

      if (response.user != null) {
        emit(Authenticated(response.user!));
      } else {
        emit(const AuthFailure('Login failed. Please check your credentials.'));
      }
    } catch (e) {
      emit(AuthFailure(ErrorFormatter.format(e)));
    }
  }

  Future<void> _onRegisterSubmitted(
    RegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final nameError = Validators.validateName(event.fullName);
    if (nameError != null) {
      emit(AuthFailure(nameError));
      return;
    }

    final emailError = Validators.validateEmail(event.email);
    if (emailError != null) {
      emit(AuthFailure(emailError));
      return;
    }

    final passwordError = Validators.validatePassword(event.password);
    if (passwordError != null) {
      emit(AuthFailure(passwordError));
      return;
    }

    final confirmError = Validators.validateConfirmPassword(
      event.password,
      event.confirmPassword,
    );
    if (confirmError != null) {
      emit(AuthFailure(confirmError));
      return;
    }

    emit(const AuthLoading());

    try {
      final response = await authRepository.signUpWithEmailPassword(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
      );

      if (response.user != null) {
        // If session is null, Supabase requires email verification
        if (response.session == null) {
          emit(EmailVerificationRequired(event.email));
        } else {
          emit(Authenticated(response.user!));
        }
      } else {
        emit(const AuthFailure('Registration failed. Please try again.'));
      }
    } catch (e) {
      emit(AuthFailure(ErrorFormatter.format(e)));
    }
  }

  Future<void> _onForgotPasswordSubmitted(
    ForgotPasswordSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final emailError = Validators.validateEmail(event.email);
    if (emailError != null) {
      emit(AuthFailure(emailError));
      return;
    }

    emit(const AuthLoading());

    try {
      await authRepository.resetPasswordForEmail(email: event.email);
      emit(PasswordResetSent(event.email));
    } catch (e) {
      emit(AuthFailure(ErrorFormatter.format(e)));
    }
  }

  Future<void> _onGoogleLoginSubmitted(
    GoogleLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    _oauthInProgress = true;
    try {
      final success = await authRepository.signInWithGoogle();
      if (!success) {
        _oauthInProgress = false;
        emit(const AuthFailure('Google sign-in was cancelled or failed.'));
      }
    } catch (e) {
      _oauthInProgress = false;
      emit(AuthFailure(ErrorFormatter.format(e)));
    }
  }

  Future<void> _onLinkedInLoginSubmitted(
    LinkedInLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    _oauthInProgress = true;
    try {
      final success = await authRepository.signInWithLinkedIn();
      if (!success) {
        _oauthInProgress = false;
        emit(const AuthFailure('LinkedIn sign-in was cancelled or failed.'));
      }
    } catch (e) {
      _oauthInProgress = false;
      emit(AuthFailure(ErrorFormatter.format(e)));
    }
  }

  Future<void> _onLogoutSubmitted(
    LogoutSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await authRepository.signOut();
      emit(const Unauthenticated());
    } catch (e) {
      emit(const Unauthenticated());
    }
  }

  /// Internal handler: fired when Supabase auth stream emits signedIn
  /// (e.g., after Google/LinkedIn OAuth deep link callback completes).
  Future<void> _onAuthStateChanged(
    _AuthStateChanged event,
    Emitter<AuthState> emit,
  ) async {
    _oauthInProgress = false;
    final user = event.session.user;
    emit(Authenticated(user));
  }

  void _onPasswordRecoveryRequested(
    PasswordRecoveryRequested event,
    Emitter<AuthState> emit,
  ) {
    emit(const PasswordRecoveryRequired());
  }

  /// Fired ~700ms after the app resumes while an OAuth flow was pending.
  /// If no deep-link callback has arrived by then (no session, still
  /// loading), the user closed the browser tab without picking an account,
  /// so we surface that instead of spinning forever.
  void _onOAuthResumeCheck(
    _OAuthResumeCheck event,
    Emitter<AuthState> emit,
  ) {
    if (state is AuthLoading && authRepository.currentSession == null) {
      emit(const AuthFailure('Sign-in was cancelled.'));
    }
  }

  Future<void> _onUpdatePasswordSubmitted(
    UpdatePasswordSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final passwordError = Validators.validatePassword(event.newPassword);
    if (passwordError != null) {
      emit(AuthFailure(passwordError));
      return;
    }

    final confirmError = Validators.validateConfirmPassword(
      event.newPassword,
      event.confirmPassword,
    );
    if (confirmError != null) {
      emit(AuthFailure(confirmError));
      return;
    }

    emit(const AuthLoading());

    try {
      await authRepository.updatePassword(event.newPassword);
      emit(const PasswordUpdatedSuccess());
    } catch (e) {
      emit(AuthFailure(ErrorFormatter.format(e)));
    }
  }
}

/// Private internal event — not dispatched by UI, only by Supabase stream listener.
class _AuthStateChanged extends AuthEvent {
  final supabase.Session session;
  const _AuthStateChanged({required this.session});

  @override
  List<Object?> get props => [session.accessToken];
}

/// Private internal event — dispatched by AuthBloc itself when the app
/// resumes after an OAuth browser tab closes without a callback.
class _OAuthResumeCheck extends AuthEvent {
  const _OAuthResumeCheck();
}
