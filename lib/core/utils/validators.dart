import '../constants/app_strings.dart';

/// Pure validation utilities for authentication forms
class Validators {
  Validators._();

  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%& me*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
  );

  static String? validateName(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return AppStrings.errRequiredField;
    }
    if (trimmed.length < 2) {
      return 'Name must be at least 2 characters.';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return AppStrings.errRequiredField;
    }
    if (!_emailRegExp.hasMatch(trimmed)) {
      return AppStrings.errInvalidEmail;
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.errRequiredField;
    }
    if (value.length < 8) {
      return AppStrings.errWeakPassword;
    }
    return null;
  }

  static String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return AppStrings.errRequiredField;
    }
    if (password != confirmPassword) {
      return AppStrings.errPasswordMismatch;
    }
    return null;
  }
}
