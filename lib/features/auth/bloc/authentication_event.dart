import 'package:equatable/equatable.dart';

/// Base type for every action that can be dispatched to [AuthenticationBloc].
abstract class AuthenticationEvent extends Equatable {
  const AuthenticationEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched once when the app boots, so the Bloc can figure out whether
/// there's already an active session (and whether we're mid password-reset).
class ApplicationLaunched extends AuthenticationEvent {
  const ApplicationLaunched();
}

/// The student tapped "Log In" on the email/password form.
class EmailPasswordLoginRequested extends AuthenticationEvent {
  final String email;
  final String password;

  const EmailPasswordLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// The student submitted the registration form.
class EmailPasswordRegistrationRequested extends AuthenticationEvent {
  final String fullName;
  final String email;
  final String password;
  final String confirmPassword;

  const EmailPasswordRegistrationRequested({
    required this.fullName,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [fullName, email, password, confirmPassword];
}

/// The student asked for a password-reset email to be sent.
class PasswordResetEmailRequested extends AuthenticationEvent {
  final String email;

  const PasswordResetEmailRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

/// The student tapped "Continue with Google".
class GoogleOAuthLoginRequested extends AuthenticationEvent {
  const GoogleOAuthLoginRequested();
}

/// The student tapped "Continue with LinkedIn".
class LinkedInOAuthLoginRequested extends AuthenticationEvent {
  const LinkedInOAuthLoginRequested();
}

/// The student asked to sign out.
class UserLogoutRequested extends AuthenticationEvent {
  const UserLogoutRequested();
}

/// Internally triggered when Supabase reports the session has entered
/// password-recovery mode (i.e. the user clicked a valid reset-password link).
class PasswordRecoveryModeTriggered extends AuthenticationEvent {
  const PasswordRecoveryModeTriggered();
}

/// The student submitted a new password from the recovery screen.
class NewPasswordSubmitted extends AuthenticationEvent {
  final String newPassword;
  final String confirmPassword;

  const NewPasswordSubmitted({
    required this.newPassword,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [newPassword, confirmPassword];
}
