/// Field-level validators shared by every edit screen. Each returns
/// `null` when valid, or an error string to show under the field —
/// matches Flutter's `FormField.validator` signature so these drop
/// straight into `TextFormField(validator: ...)`.
///
/// NAMING NOTE: Authentication's repo also has a `Validators` class
/// (`core/utils/validators.dart`, for email/password/name checks).
/// Two different classes with the same name — harmless while this
/// stays under `features/profile/utils/`, but if a single file ever
/// needs both, one import will need an `as` prefix.
class Validators {
  Validators._();

  static String? requiredText(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  static String? requiredMinLength(String? value, int minLength, {String label = 'This field'}) {
    final requiredCheck = requiredText(value, label: label);
    if (requiredCheck != null) return requiredCheck;
    if (value!.trim().length < minLength) {
      return '$label must be at least $minLength characters';
    }
    return null;
  }

  static String? optionalMaxLength(String? value, int maxLength, {String label = 'This field'}) {
    if (value == null || value.isEmpty) return null;
    if (value.length > maxLength) {
      return '$label must be $maxLength characters or fewer';
    }
    return null;
  }

  static String? graduationYear(String? value) {
    final requiredCheck = requiredText(value, label: 'Graduation year');
    if (requiredCheck != null) return requiredCheck;
    final year = int.tryParse(value!.trim());
    if (year == null) return 'Enter a valid year';
    final currentYear = DateTime.now().year;
    if (year < currentYear - 10 || year > currentYear + 10) {
      return 'Enter a realistic graduation year';
    }
    return null;
  }

  static String? cgpa(String? value) {
    final requiredCheck = requiredText(value, label: 'CGPA');
    if (requiredCheck != null) return requiredCheck;
    final parsed = double.tryParse(value!.trim());
    if (parsed == null) return 'Enter a valid number';
    if (parsed < 0 || parsed > 10) return 'CGPA must be between 0 and 10';
    return null;
  }

  /// Optional field, but if the student typed something, it must look
  /// like a real URL (Section 2.2: social links are "optional,
  /// low-effort trust signal" — optional to fill in, not optional to
  /// be well-formed once filled in).
  static String? optionalUrl(String? value, {String label = 'Link'}) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    final looksValid = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.contains('.');
    if (!looksValid) {
      return '$label must be a valid URL (e.g. https://...)';
    }
    return null;
  }

  static String? requiredUrl(String? value, {String label = 'Link'}) {
    final requiredCheck = requiredText(value, label: label);
    if (requiredCheck != null) return requiredCheck;
    return optionalUrl(value, label: label);
  }

  /// Skills validation isn't a single-field TextFormField — surfaced
  /// separately so the Skills screen can show it near the chip list.
  static String? skillsMinimum(List<String> skills, {int minimum = 3}) {
    if (skills.length < minimum) {
      return 'Add at least $minimum skills (${skills.length}/$minimum so far)';
    }
    return null;
  }

  static String? countryCode(String? value) {
    final requiredCheck = requiredText(value, label: 'Country code');
    if (requiredCheck != null) return requiredCheck;
    final trimmed = value!.trim();
    if (!RegExp(r'^\+\d{1,4}$').hasMatch(trimmed)) {
      return 'Use a format like +91';
    }
    return null;
  }

  static String? phoneNumber(String? value) {
    final requiredCheck = requiredText(value, label: 'Phone number');
    if (requiredCheck != null) return requiredCheck;
    final digitsOnly = value!.trim().replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 7 || digitsOnly.length > 15) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  /// College email is a distinct verification field, separate from
  /// whatever email the student signed up with (Authentication's
  /// concern) — required once the student starts the college
  /// verification flow, but the field itself is optional at the
  /// model level since verification is opt-in-when-ready.
  static String? collegeEmail(String? value) {
    final requiredCheck = requiredText(value, label: 'College email');
    if (requiredCheck != null) return requiredCheck;
    final trimmed = value!.trim();
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(trimmed)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static const int maxResumeSizeBytes = 5 * 1024 * 1024; // 5 MB

  static String? resumeFile({required String? fileName, required int? sizeBytes}) {
    if (fileName == null) return 'A resume (PDF) is required';
    if (!fileName.toLowerCase().endsWith('.pdf')) {
      return 'Resume must be a PDF file';
    }
    if (sizeBytes != null && sizeBytes > maxResumeSizeBytes) {
      return 'Resume must be under 5 MB';
    }
    return null;
  }
}
