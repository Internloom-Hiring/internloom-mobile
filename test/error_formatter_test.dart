import 'dart:io';
import 'package:flutter_test/flutter_test.dart' hide ErrorFormatter;
import 'package:internloom_mobile/core/constants/app_strings.dart';
import 'package:internloom_mobile/core/utils/error_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('ErrorFormatter Unit Tests', () {
    test('formats invalid credentials error', () {
      const authException = AuthException(
        'Invalid login credentials',
        statusCode: '400',
      );
      expect(
        ErrorFormatter.format(authException),
        AppStrings.errInvalidCredentials,
      );
    });

    test('formats user already exists error', () {
      const authException = AuthException(
        'User already registered',
        statusCode: '400',
      );
      expect(
        ErrorFormatter.format(authException),
        AppStrings.errUserExists,
      );
    });

    test('formats network socket exception', () {
      const socketException = SocketException('Failed host lookup');
      expect(
        ErrorFormatter.format(socketException),
        AppStrings.errNetwork,
      );
    });

    test('formats generic unexpected error without exposing raw traces', () {
      final unknownError = Exception('http internal crash {raw}');
      expect(
        ErrorFormatter.format(unknownError),
        AppStrings.errUnexpected,
      );
    });
  });
}
