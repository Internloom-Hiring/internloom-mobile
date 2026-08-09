import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/branded_loading.dart';
import '../../bloc/authentication_bloc.dart';
import '../../bloc/authentication_event.dart';
import '../../bloc/authentication_state.dart';
import '../../../profile/presentation/screens/profile_gate.dart';
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
    context.read<AuthenticationBloc>().add(const ApplicationLaunched());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listener: (context, authState) {
        if (authState is PasswordRecoveryModeActive) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const UpdatePasswordScreen(),
            ),
          );
        } else if (authState is UserAuthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const ProfileGate(),
            ),
          );
        } else if (authState is AuthenticationFailed) {
          // Surface the error on the login screen (e.g. expired recovery link).
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => LoginScreen(initialError: authState.errorMessage),
            ),
          );
        } else if (authState is UserNotAuthenticated) {
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
