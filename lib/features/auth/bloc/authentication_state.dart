import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Base type for every state [AuthenticationBloc] can be in.
abstract class AuthenticationState extends Equatable {
  const AuthenticationState();

  @override
  List<Object?> get props => [];
}

/// Nothing has happened yet — the very first state before we've even
/// checked whether a session already exists.
class AuthenticationInitial extends AuthenticationState {
  const AuthenticationInitial();
}

/// An auth request (login, register, OAuth, password reset, etc.) is
/// currently in flight. UI should show a spinner and disable inputs.
class AuthenticationInProgress extends AuthenticationState {
  const AuthenticationInProgress();
}

/// The student is signed in with a valid session.
class UserAuthenticated extends AuthenticationState {
  final User authenticatedUser;

  const UserAuthenticated(this.authenticatedUser);

  @override
  List<Object?> get props => [authenticatedUser.id, authenticatedUser.email];
}

/// The student is signed out. [reasonMessage] is optionally shown to
/// explain why (e.g. after a manual logout).
class UserNotAuthenticated extends AuthenticationState {
  final String? reasonMessage;

  const UserNotAuthenticated({this.reasonMessage});

  @override
  List<Object?> get props => [reasonMessage];
}

/// A request failed. [errorMessage] is already formatted for display.
class AuthenticationFailed extends AuthenticationState {
  final String errorMessage;

  const AuthenticationFailed(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

/// A password-reset email was successfully sent to [recipientEmail].
class PasswordResetEmailSent extends AuthenticationState {
  final String recipientEmail;

  const PasswordResetEmailSent(this.recipientEmail);

  @override
  List<Object?> get props => [recipientEmail];
}

/// Registration succeeded but Supabase requires the student to verify
/// [pendingEmail] before a session is issued.
class EmailVerificationPending extends AuthenticationState {
  final String pendingEmail;

  const EmailVerificationPending(this.pendingEmail);

  @override
  List<Object?> get props => [pendingEmail];
}

/// The student followed a valid password-recovery link and should now be
/// shown the "set a new password" screen.
class PasswordRecoveryModeActive extends AuthenticationState {
  const PasswordRecoveryModeActive();
}

/// The student's password was successfully updated.
class PasswordUpdateSucceeded extends AuthenticationState {
  const PasswordUpdateSucceeded();
}
