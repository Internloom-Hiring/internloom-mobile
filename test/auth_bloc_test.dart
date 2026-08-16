import 'package:flutter_test/flutter_test.dart';
import 'package:internloom_mobile/core/constants/app_strings.dart';
import 'package:internloom_mobile/features/auth/bloc/auth_bloc.dart';
import 'package:internloom_mobile/features/auth/bloc/auth_event.dart';
import 'package:internloom_mobile/features/auth/bloc/auth_state.dart';
import 'package:internloom_mobile/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class FakeAuthRepository implements AuthRepository {
  bool isAuth = false;
  supabase.User? mockUser;
  bool shouldThrow = false;
  String? errorMessage;

  @override
  supabase.User? get currentUser => mockUser;

  @override
  supabase.Session? get currentSession => null;

  @override
  bool get isAuthenticated => isAuth;

  @override
  Stream<supabase.AuthState> get authStateChanges => const Stream.empty();

  @override
  Future<supabase.AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (shouldThrow) {
      throw supabase.AuthException(
        errorMessage ?? 'Invalid login credentials',
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
  Future<supabase.AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    if (shouldThrow) {
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
  Future<bool> signInWithGoogle() async => true;

  @override
  Future<bool> signInWithLinkedIn() async => true;

  @override
  Future<void> resetPasswordForEmail({required String email}) async {
    if (shouldThrow) {
      throw const supabase.AuthException('Invalid email');
    }
  }

  @override
  Future<supabase.UserResponse> updatePassword(String newPassword) async {
    if (shouldThrow) {
      throw const supabase.AuthException('Failed to update password');
    }
    return supabase.UserResponse.fromJson({'user': null});
  }

  @override
  Future<void> signOut() async {
    isAuth = false;
    mockUser = null;
  }
}

void main() {
  group('AuthBloc Unit Tests', () {
    late FakeAuthRepository fakeRepository;
    late AuthBloc authBloc;

    setUp(() {
      fakeRepository = FakeAuthRepository();
      authBloc = AuthBloc(authRepository: fakeRepository);
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state is AuthInitial', () {
      expect(authBloc.state, const AuthInitial());
    });

    test('AppStarted emits Unauthenticated when unauthenticated', () async {
      authBloc.add(const AppStarted());
      await expectLater(
        authBloc.stream,
        emitsInOrder([const Unauthenticated()]),
      );
    });

    test('LoginSubmitted emits AuthFailure when email is invalid', () async {
      authBloc.add(
        const LoginSubmitted(email: 'invalid-email', password: 'password123'),
      );
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          const AuthFailure(AppStrings.errInvalidEmail),
        ]),
      );
    });

    test('LoginSubmitted emits AuthFailure on invalid credentials', () async {
      fakeRepository.shouldThrow = true;
      authBloc.add(
        const LoginSubmitted(
          email: 'valid@university.edu',
          password: 'password123',
        ),
      );
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          const AuthLoading(),
          const AuthFailure(AppStrings.errInvalidCredentials),
        ]),
      );
    });

    test('LoginSubmitted emits Authenticated on success', () async {
      authBloc.add(
        const LoginSubmitted(
          email: 'valid@university.edu',
          password: 'password123',
        ),
      );
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          const AuthLoading(),
          isA<Authenticated>(),
        ]),
      );
    });

    test('RegisterSubmitted emits EmailVerificationRequired when session is null',
        () async {
      authBloc.add(
        const RegisterSubmitted(
          fullName: 'Alex Johnson',
          email: 'alex@university.edu',
          password: 'password123',
          confirmPassword: 'password123',
        ),
      );
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          const AuthLoading(),
          const EmailVerificationRequired('alex@university.edu'),
        ]),
      );
    });

    test('ForgotPasswordSubmitted emits PasswordResetSent on success', () async {
      authBloc.add(
        const ForgotPasswordSubmitted(email: 'alex@university.edu'),
      );
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          const AuthLoading(),
          const PasswordResetSent('alex@university.edu'),
        ]),
      );
    });

    test('LogoutSubmitted emits Unauthenticated', () async {
      authBloc.add(const LogoutSubmitted());
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          const AuthLoading(),
          const Unauthenticated(),
        ]),
      );
    });

    test('PasswordRecoveryRequested emits PasswordRecoveryRequired', () async {
      authBloc.add(const PasswordRecoveryRequested());
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          const PasswordRecoveryRequired(),
        ]),
      );
    });

    test('UpdatePasswordSubmitted emits PasswordUpdatedSuccess on success', () async {
      authBloc.add(
        const UpdatePasswordSubmitted(
          newPassword: 'NewStrongPassword123!',
          confirmPassword: 'NewStrongPassword123!',
        ),
      );
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          const AuthLoading(),
          const PasswordUpdatedSuccess(),
        ]),
      );
    });
  });
}
