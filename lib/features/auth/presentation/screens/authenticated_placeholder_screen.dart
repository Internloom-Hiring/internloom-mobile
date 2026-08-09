import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../bloc/authentication_bloc.dart';
import '../../bloc/authentication_event.dart';
import '../../bloc/authentication_state.dart';
import 'login_screen.dart';

/// Temporary Authenticated Boundary Placeholder Screen
/// Note: Do NOT implement Home/Jobs/Swipe functionality in this module.
/// This screen exists purely as a boundary interface for session verification
/// and logout, allowing other team modules to cleanly integrate their home views.
class AuthenticatedPlaceholderScreen extends StatelessWidget {
  const AuthenticatedPlaceholderScreen({super.key});

  void _requestLogout(BuildContext context) {
    context.read<AuthenticationBloc>().add(const UserLogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthenticationBloc, AuthenticationState>(
      listener: (context, authState) {
        if (authState is UserNotAuthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            ),
          );
        }
      },
      builder: (context, authState) {
        final signedInUser =
            authState is UserAuthenticated ? authState.authenticatedUser : null;
        final isAuthenticating = authState is AuthenticationInProgress;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            title: Text(
              'Internloom Student',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: AppColors.danger),
                tooltip: 'Log Out',
                onPressed: isAuthenticating ? null : () => _requestLogout(context),
              ),
            ],
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 0,
                color: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppColors.greenLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          color: AppColors.leafGreen,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Authentication Successful',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Student Session active for:',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        signedInUser?.email ?? 'Student User',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.leafGreen,
                            ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 16),
                      Text(
                        'This boundary screen confirms the Auth module session state. Dashboard and onboarding modules will integrate here.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.muted,
                            ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: 'Log Out',
                        isLoading: isAuthenticating,
                        onPressed: () => _requestLogout(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
