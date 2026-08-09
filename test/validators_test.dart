import 'package:flutter_test/flutter_test.dart';
import 'package:internloom_mobile/core/utils/validators.dart';

void main() {
  group('Validators Unit Tests', () {
    test('validateEmail returns error for empty or null email', () {
      expect(Validators.validateEmail(null), isNotNull);
      expect(Validators.validateEmail(''), isNotNull);
      expect(Validators.validateEmail('   '), isNotNull);
    });

    test('validateEmail returns error for invalid email formats', () {
      expect(Validators.validateEmail('invalid'), isNotNull);
      expect(Validators.validateEmail('user@'), isNotNull);
      expect(Validators.validateEmail('@domain.com'), isNotNull);
      expect(Validators.validateEmail('user@domain'), isNotNull);
    });

    test('validateEmail returns null for valid email formats', () {
      expect(Validators.validateEmail('student@university.edu'), null);
      expect(Validators.validateEmail('john.doe@internloom.com'), null);
      expect(Validators.validateEmail('user+tag@domain.co.in'), null);
    });

    test('validatePassword enforces minimum 8 characters', () {
      expect(Validators.validatePassword(null), isNotNull);
      expect(Validators.validatePassword('1234567'), isNotNull);
      expect(Validators.validatePassword('12345678'), null);
      expect(Validators.validatePassword('StrongPassword123!'), null);
    });

    test('validateConfirmPassword enforces matching passwords', () {
      expect(
        Validators.validateConfirmPassword('pass1234', 'different'),
        isNotNull,
      );
      expect(
        Validators.validateConfirmPassword('pass1234', 'pass1234'),
        null,
      );
    });

    test('validateName enforces non-empty minimum length', () {
      expect(Validators.validateName(''), isNotNull);
      expect(Validators.validateName('A'), isNotNull);
      expect(Validators.validateName('Alex Johnson'), null);
    });
  });
}
