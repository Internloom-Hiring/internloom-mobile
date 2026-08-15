import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internloom_mobile/core/theme/app_theme.dart';
import 'package:internloom_mobile/features/auth/bloc/auth_bloc.dart';
import 'package:internloom_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:internloom_mobile/features/auth/presentation/screens/register_screen.dart';
import 'auth_bloc_test.dart';

void main() {
  testWidgets('LoginScreen renders brand components correctly', (WidgetTester tester) async {
    final fakeRepo = FakeAuthRepository();
    final authBloc = AuthBloc(authRepository: fakeRepo);

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      ),
    );

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with LinkedIn'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);

    authBloc.close();
  });

  testWidgets('RegisterScreen renders input fields correctly', (WidgetTester tester) async {
    final fakeRepo = FakeAuthRepository();
    final authBloc = AuthBloc(authRepository: fakeRepo);

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const RegisterScreen(),
        ),
      ),
    );

    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Create Student Account'), findsOneWidget);

    authBloc.close();
  });
}
