/// Centralized user-facing strings and error messages
class AppStrings {
  AppStrings._();

  static const String appName = 'Internloom';
  static const String studentPortal = 'Student Portal';

  // User-Friendly Error Messages
  static const String errInvalidCredentials = 'Incorrect email or password.';
  static const String errNetwork =
      'Unable to connect. Please check your internet connection and try again.';
  static const String errUnexpected = 'Something went wrong. Please try again.';
  static const String errUserExists = 'An account with this email already exists.';
  static const String errInvalidEmail = 'Please enter a valid email address.';
  static const String errWeakPassword =
      'Password must be at least 8 characters long and contain numbers or letters.';
  static const String errPasswordMismatch = 'Passwords do not match.';
  static const String errRequiredField = 'This field is required.';
  static const String errOAuthCancelled = 'Authentication was cancelled.';
  static const String errOAuthFailed = 'Social login failed. Please try again.';

  // General Messages
  static const String msgPasswordResetSent =
      'Password reset link sent! Please check your email inbox.';
  static const String msgEmailVerificationRequired =
      'Registration successful! Please check your email to confirm your account.';
}
