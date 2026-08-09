import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internloom_mobile/core/theme/app_theme.dart';
import 'package:internloom_mobile/features/auth/bloc/authentication_bloc.dart';
import 'package:internloom_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:internloom_mobile/features/auth/presentation/screens/register_screen.dart';
import 'authentication_bloc_test.dart';

void main() {
  testWidgets('LoginScreen renders brand components correctly', (WidgetTester tester) async {
    final fakeRepository = FakeAuthenticationRepository();
    final authenticationBloc =
        AuthenticationBloc(authenticationRepository: fakeRepository);

    await tester.pumpWidget(
      BlocProvider<AuthenticationBloc>.value(
        value: authenticationBloc,
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

    authenticationBloc.close();
  });

  testWidgets('RegisterScreen renders input fields correctly', (WidgetTester tester) async {
    final fakeRepository = FakeAuthenticationRepository();
    final authenticationBloc =
        AuthenticationBloc(authenticationRepository: fakeRepository);

    await tester.pumpWidget(
      BlocProvider<AuthenticationBloc>.value(
        value: authenticationBloc,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const RegisterScreen(),
        ),
      ),
    );

    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Create Student Account'), findsOneWidget);

    authenticationBloc.close();
  });
}
