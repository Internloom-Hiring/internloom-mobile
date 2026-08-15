import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/branded_loading.dart';
import '../../../profile/presentation/screens/profile_gate.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';
import 'login_screen.dart';
import 'update_password_screen.dart';

/// Branded Splash screen checking session status on application open
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AppStarted());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is PasswordRecoveryRequired) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const UpdatePasswordScreen(),
            ),
          );
        } else if (state is Authenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const ProfileGate(),
            ),
          );
        } else if (state is AuthFailure) {
          // Surface the error on the login screen (e.g. expired recovery link).
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => LoginScreen(initialError: state.message),
            ),
          );
        } else if (state is Unauthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            ),
          );
        }
      },
      child: const BrandedLoading(text: 'Loading authentication session...'),
    );
  }
}
