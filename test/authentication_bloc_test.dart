import 'package:flutter_test/flutter_test.dart';
import 'package:internloom_mobile/core/constants/app_strings.dart';
import 'package:internloom_mobile/features/auth/bloc/authentication_bloc.dart';
import 'package:internloom_mobile/features/auth/bloc/authentication_event.dart';
import 'package:internloom_mobile/features/auth/bloc/authentication_state.dart';
import 'package:internloom_mobile/features/auth/data/authentication_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// In-memory stand-in for [AuthenticationRepository] so bloc tests don't
/// need a real Supabase project or network access.
class FakeAuthenticationRepository implements AuthenticationRepository {
  bool hasSession = false;
  supabase.User? mockUser;
  bool shouldThrowOnNextCall = false;
  String? errorMessageOverride;

  @override
  supabase.User? get currentAuthenticatedUser => mockUser;

  @override
  supabase.Session? get currentUserSession => null;

  @override
  bool get hasActiveSession => hasSession;

  @override
  Stream<supabase.AuthState> get authenticationStateStream => const Stream.empty();

  @override
  Future<supabase.AuthResponse> authenticateWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (shouldThrowOnNextCall) {
      throw supabase.AuthException(
        errorMessageOverride ?? 'Invalid login credentials',
        statusCode: '400',
      );
    }
    return supabase.AuthResponse(
      session: null,
      user: supabase.User(
        id: 'test-user-id',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  @override
  Future<supabase.AuthResponse> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    if (shouldThrowOnNextCall) {
      throw const supabase.AuthException('User already registered');
    }
    return supabase.AuthResponse(
      session: null,
      user: supabase.User(
        id: 'test-user-id',
        appMetadata: {},
        userMetadata: {'full_name': fullName},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  @override
  Future<bool> authenticateWithGoogleOAuth() async => true;

  @override
  Future<bool> authenticateWithLinkedInOAuth() async => true;

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    if (shouldThrowOnNextCall) {
      throw const supabase.AuthException('Invalid email');
    }
  }

  @override
  Future<supabase.UserResponse> updateUserPassword(String newPassword) async {
    if (shouldThrowOnNextCall) {
      throw const supabase.AuthException('Failed to update password');
    }
    return supabase.UserResponse.fromJson({'user': null});
  }

  @override
  Future<void> signOutCurrentUser() async {
    hasSession = false;
    mockUser = null;
  }
}

void main() {
  group('AuthenticationBloc', () {
    late FakeAuthenticationRepository fakeRepository;
    late AuthenticationBloc authenticationBloc;

    setUp(() {
      fakeRepository = FakeAuthenticationRepository();
      authenticationBloc =
          AuthenticationBloc(authenticationRepository: fakeRepository);
    });

    tearDown(() {
      authenticationBloc.close();
    });

    test('starts in AuthenticationInitial', () {
      expect(authenticationBloc.state, const AuthenticationInitial());
    });

    test('ApplicationLaunched emits UserNotAuthenticated when no session exists',
        () async {
      authenticationBloc.add(const ApplicationLaunched());
      await expectLater(
        authenticationBloc.stream,
        emitsInOrder([const UserNotAuthenticated()]),
      );
    });

    test('EmailPasswordLoginRequested emits AuthenticationFailed for an invalid email',
        () async {
      authenticationBloc.add(
        const EmailPasswordLoginRequested(
          email: 'invalid-email',
          password: 'password123',
        ),
      );
      await expectLater(
        authenticationBloc.stream,
        emitsInOrder([
          const AuthenticationFailed(AppStrings.errInvalidEmail),
        ]),
      );
    });

    test('EmailPasswordLoginRequested emits AuthenticationFailed on rejected credentials',
        () async {
      fakeRepository.shouldThrowOnNextCall = true;
      authenticationBloc.add(
        const EmailPasswordLoginRequested(
          email: 'valid@university.edu',
          password: 'password123',
        ),
      );
      await expectLater(
        authenticationBloc.stream,
        emitsInOrder([
          const AuthenticationInProgress(),
          const AuthenticationFailed(AppStrings.errInvalidCredentials),
        ]),
      );
    });

    test('EmailPasswordLoginRequested emits UserAuthenticated on success', () async {
      authenticationBloc.add(
        const EmailPasswordLoginRequested(
          email: 'valid@university.edu',
          password: 'password123',
        ),
      );
      await expectLater(
        authenticationBloc.stream,
        emitsInOrder([
          const AuthenticationInProgress(),
          isA<UserAuthenticated>(),
        ]),
      );
    });

    test(
        'EmailPasswordRegistrationRequested emits EmailVerificationPending when session is null',
        () async {
      authenticationBloc.add(
        const EmailPasswordRegistrationRequested(
          fullName: 'Alex Johnson',
          email: 'alex@university.edu',
          password: 'password123',
          confirmPassword: 'password123',
        ),
      );
      await expectLater(
        authenticationBloc.stream,
        emitsInOrder([
          const AuthenticationInProgress(),
          const EmailVerificationPending('alex@university.edu'),
        ]),
      );
    });

    test('PasswordResetEmailRequested emits PasswordResetEmailSent on success',
        () async {
      authenticationBloc.add(
        const PasswordResetEmailRequested(email: 'alex@university.edu'),
      );
      await expectLater(
        authenticationBloc.stream,
        emitsInOrder([
          const AuthenticationInProgress(),
          const PasswordResetEmailSent('alex@university.edu'),
        ]),
      );
    });

    test('UserLogoutRequested emits UserNotAuthenticated', () async {
      authenticationBloc.add(const UserLogoutRequested());
      await expectLater(
        authenticationBloc.stream,
        emitsInOrder([
          const AuthenticationInProgress(),
          const UserNotAuthenticated(),
        ]),
      );
    });

    test('PasswordRecoveryModeTriggered emits PasswordRecoveryModeActive', () async {
      authenticationBloc.add(const PasswordRecoveryModeTriggered());
      await expectLater(
        authenticationBloc.stream,
        emitsInOrder([
          const PasswordRecoveryModeActive(),
        ]),
      );
    });

    test('NewPasswordSubmitted emits PasswordUpdateSucceeded on success', () async {
      authenticationBloc.add(
        const NewPasswordSubmitted(
          newPassword: 'NewStrongPassword123!',
          confirmPassword: 'NewStrongPassword123!',
        ),
      );
      await expectLater(
        authenticationBloc.stream,
        emitsInOrder([
          const AuthenticationInProgress(),
          const PasswordUpdateSucceeded(),
        ]),
      );
    });
  });
}
