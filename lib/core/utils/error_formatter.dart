import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_strings.dart';

/// Transforms exceptions into user-friendly localized error messages
class ErrorFormatter {
  ErrorFormatter._();

  static String format(dynamic error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      final code = error.statusCode;

      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid_credentials') ||
          code == '400' && msg.contains('grant_type')) {
        return AppStrings.errInvalidCredentials;
      }

      if (msg.contains('user already registered') ||
          msg.contains('email_exists') ||
          msg.contains('already exists')) {
        return AppStrings.errUserExists;
      }

      if (msg.contains('password should be at least')) {
        return AppStrings.errWeakPassword;
      }

      if (msg.contains('invalid email') || msg.contains('format')) {
        return AppStrings.errInvalidEmail;
      }

      if (msg.contains('rate limit') || msg.contains('too many requests')) {
        return 'Too many requests. Please wait a moment and try again.';
      }

      return error.message.isNotEmpty
          ? _cleanRawMessage(error.message)
          : AppStrings.errUnexpected;
    }

    if (error is SocketException) {
      return AppStrings.errNetwork;
    }

    final String errString = error.toString().toLowerCase();
    if (errString.contains('socketexception') ||
        errString.contains('failed host lookup') ||
        errString.contains('connection timed out') ||
        errString.contains('network_error')) {
      return AppStrings.errNetwork;
    }

    return AppStrings.errUnexpected;
  }

  static String _cleanRawMessage(String raw) {
    if (raw.contains('http') || raw.contains('Exception') || raw.contains('{')) {
      return AppStrings.errUnexpected;
    }
    return raw;
  }
}
