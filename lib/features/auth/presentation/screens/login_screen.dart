import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/social_provider_button.dart';
import '../../bloc/authentication_bloc.dart';
import '../../bloc/authentication_event.dart';
import '../../bloc/authentication_state.dart';
import '../../../profile/presentation/screens/profile_gate.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'update_password_screen.dart';

/// Student Login Screen
class LoginScreen extends StatefulWidget {
  /// Optional error message to display immediately on screen open
  /// (e.g. when redirected from an expired recovery link).
  final String? initialError;

  const LoginScreen({super.key, this.initialError});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _emailInputController = TextEditingController();
  final _passwordInputController = TextEditingController();
  String? _displayedErrorMessage;

  @override
  void initState() {
    super.initState();
    // Show error passed in from SplashScreen (e.g. expired recovery link)
    if (widget.initialError != null) {
      _displayedErrorMessage = widget.initialError;
    }
  }

  @override
  void dispose() {
    _emailInputController.dispose();
    _passwordInputController.dispose();
    super.dispose();
  }

  void _submitEmailPasswordLogin() {
    final formInputsAreValid = _loginFormKey.currentState?.validate() ?? false;
    if (!formInputsAreValid) return;

    setState(() => _displayedErrorMessage = null);
    context.read<AuthenticationBloc>().add(
          EmailPasswordLoginRequested(
            email: _emailInputController.text,
            password: _passwordInputController.text,
          ),
        );
  }

  void _startGoogleOAuthLogin() {
    context.read<AuthenticationBloc>().add(const GoogleOAuthLoginRequested());
  }

  void _startLinkedInOAuthLogin() {
    context.read<AuthenticationBloc>().add(const LinkedInOAuthLoginRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<AuthenticationBloc, AuthenticationState>(
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
              setState(() => _displayedErrorMessage = authState.errorMessage);
            }
          },
          builder: (context, authState) {
            final isAuthenticating = authState is AuthenticationInProgress;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 440),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _loginFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo & Brand Header
                        Center(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.leafGreen,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              color: AppColors.white,
                              size: 34,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Welcome Back',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Log in to your Internloom student account',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.muted,
                              ),
                        ),
                        const SizedBox(height: 28),

                        // Error Banner
                        if (_displayedErrorMessage != null)
                          ErrorBanner(
                            message: _displayedErrorMessage!,
                            onDismiss: () {
                              setState(() => _displayedErrorMessage = null);
                            },
                          ),

                        // Email Input
                        CustomTextField(
                          label: 'College or Personal Email',
                          hint: 'student@university.edu',
                          controller: _emailInputController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          prefixIcon: Icons.email_outlined,
                          validator: Validators.validateEmail,
                          enabled: !isAuthenticating,
                        ),
                        const SizedBox(height: 18),

                        // Password Input
                        CustomTextField(
                          label: 'Password',
                          hint: '••••••••',
                          controller: _passwordInputController,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          prefixIcon: Icons.lock_outline,
                          validator: Validators.validatePassword,
                          enabled: !isAuthenticating,
                        ),
                        const SizedBox(height: 10),

                        // Forgot Password Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: isAuthenticating
                                ? null
                                : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ForgotPasswordScreen(),
                                      ),
                                    );
                                  },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.bookTeal,
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Submit Button
                        PrimaryButton(
                          text: 'Log In',
                          onPressed: _submitEmailPasswordLogin,
                          isLoading: isAuthenticating,
                        ),
                        const SizedBox(height: 24),

                        // Divider
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(color: AppColors.border),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'OR',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.muted),
                              ),
                            ),
                            const Expanded(
                              child: Divider(color: AppColors.border),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Social Buttons
                        SocialProviderButton(
                          provider: SocialAuthProvider.google,
                          isAuthenticating: isAuthenticating,
                          onPressed: _startGoogleOAuthLogin,
                        ),
                        const SizedBox(height: 12),
                        SocialProviderButton(
                          provider: SocialAuthProvider.linkedIn,
                          isAuthenticating: isAuthenticating,
                          onPressed: _startLinkedInOAuthLogin,
                        ),
                        const SizedBox(height: 28),

                        // Register Navigation Link
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.muted),
                            ),
                            GestureDetector(
                              onTap: isAuthenticating
                                  ? null
                                  : () {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const RegisterScreen(),
                                        ),
                                      );
                                    },
                              child: Text(
                                'Register',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.leafGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
