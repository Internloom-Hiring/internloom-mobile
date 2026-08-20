import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {
  const AppStarted();
}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  const LoginSubmitted({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class RegisterSubmitted extends AuthEvent {
  final String fullName;
  final String email;
  final String password;
  final String confirmPassword;

  const RegisterSubmitted({
    required this.fullName,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [fullName, email, password, confirmPassword];
}

class CompanyRegisterSubmitted extends AuthEvent {
  final String username;
  final String email;
  final String password;
  final String confirmPassword;
  final String companyName;
  final String hrName;
  final String hrContact;
  final String? website;
  final String? description;
  final String? incorporationCertPath;
  final String? pitchDeckPath;

  const CompanyRegisterSubmitted({
    required this.username,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.companyName,
    required this.hrName,
    required this.hrContact,
    this.website,
    this.description,
    this.incorporationCertPath,
    this.pitchDeckPath,
  });

  @override
  List<Object?> get props => [
        username,
        email,
        password,
        confirmPassword,
        companyName,
        hrName,
        hrContact,
        website,
        description,
        incorporationCertPath,
        pitchDeckPath,
      ];
}

class ForgotPasswordSubmitted extends AuthEvent {
  final String email;

  const ForgotPasswordSubmitted({required this.email});

  @override
  List<Object?> get props => [email];
}

class GoogleLoginSubmitted extends AuthEvent {
  const GoogleLoginSubmitted();
}

class LinkedInLoginSubmitted extends AuthEvent {
  const LinkedInLoginSubmitted();
}

class LogoutSubmitted extends AuthEvent {
  const LogoutSubmitted();
}

class PasswordRecoveryRequested extends AuthEvent {
  const PasswordRecoveryRequested();
}

class UpdatePasswordSubmitted extends AuthEvent {
  final String newPassword;
  final String confirmPassword;

  const UpdatePasswordSubmitted({
    required this.newPassword,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [newPassword, confirmPassword];
}
