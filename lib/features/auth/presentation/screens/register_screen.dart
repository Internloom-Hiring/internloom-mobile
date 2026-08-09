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
import 'authenticated_placeholder_screen.dart';
import 'login_screen.dart';

/// Student Registration Screen
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _registrationFormKey = GlobalKey<FormState>();
  final _fullNameInputController = TextEditingController();
  final _emailInputController = TextEditingController();
  final _passwordInputController = TextEditingController();
  final _confirmPasswordInputController = TextEditingController();

  String? _displayedErrorMessage;
  String? _displayedInfoMessage;

  @override
  void dispose() {
    _fullNameInputController.dispose();
    _emailInputController.dispose();
    _passwordInputController.dispose();
    _confirmPasswordInputController.dispose();
    super.dispose();
  }

  void _submitRegistrationForm() {
    final formInputsAreValid =
        _registrationFormKey.currentState?.validate() ?? false;
    if (!formInputsAreValid) return;

    setState(() {
      _displayedErrorMessage = null;
      _displayedInfoMessage = null;
    });
    context.read<AuthenticationBloc>().add(
          EmailPasswordRegistrationRequested(
            fullName: _fullNameInputController.text,
            email: _emailInputController.text,
            password: _passwordInputController.text,
            confirmPassword: _confirmPasswordInputController.text,
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
            if (authState is UserAuthenticated) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const AuthenticatedPlaceholderScreen(),
                ),
              );
            } else if (authState is EmailVerificationPending) {
              setState(() {
                _displayedInfoMessage =
                    'Registration successful! A verification link has been sent to ${authState.pendingEmail}. Please verify your email before logging in.';
              });
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
                    key: _registrationFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Center(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.leafGreen,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.person_add_rounded,
                              color: AppColors.white,
                              size: 34,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Create Account',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Join Internloom to unlock internship opportunities',
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

                        // Info / Success Banner
                        if (_displayedInfoMessage != null) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.info.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.info.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.mark_email_read_outlined,
                                    color: AppColors.info, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _displayedInfoMessage!,
                                    style: const TextStyle(
                                      color: AppColors.info,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Full Name Input
                        CustomTextField(
                          label: 'Full Name',
                          hint: 'Alex Johnson',
                          controller: _fullNameInputController,
                          prefixIcon: Icons.person_outline,
                          textInputAction: TextInputAction.next,
                          validator: Validators.validateName,
                          enabled: !isAuthenticating,
                        ),
                        const SizedBox(height: 16),

                        // Email Input
                        CustomTextField(
                          label: 'College or Personal Email',
                          hint: 'student@university.edu',
                          controller: _emailInputController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          textInputAction: TextInputAction.next,
                          validator: Validators.validateEmail,
                          enabled: !isAuthenticating,
                        ),
                        const SizedBox(height: 16),

                        // Password Input
                        CustomTextField(
                          label: 'Password',
                          hint: 'At least 8 characters',
                          controller: _passwordInputController,
                          isPassword: true,
                          prefixIcon: Icons.lock_outline,
                          textInputAction: TextInputAction.next,
                          validator: Validators.validatePassword,
                          enabled: !isAuthenticating,
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password Input
                        CustomTextField(
                          label: 'Confirm Password',
                          hint: 'Re-enter your password',
                          controller: _confirmPasswordInputController,
                          isPassword: true,
                          prefixIcon: Icons.lock_clock_outlined,
                          textInputAction: TextInputAction.done,
                          validator: (value) =>
                              Validators.validateConfirmPassword(
                            _passwordInputController.text,
                            value,
                          ),
                          enabled: !isAuthenticating,
                        ),
                        const SizedBox(height: 24),

                        // Register Button
                        PrimaryButton(
                          text: 'Create Student Account',
                          onPressed: _submitRegistrationForm,
                          isLoading: isAuthenticating,
                        ),
                        const SizedBox(height: 20),

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
                        const SizedBox(height: 20),

                        // Social Logins
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
                        const SizedBox(height: 24),

                        // Login Navigation Link
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
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
                                          builder: (_) => const LoginScreen(),
                                        ),
                                      );
                                    },
                              child: Text(
                                'Log In',
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
