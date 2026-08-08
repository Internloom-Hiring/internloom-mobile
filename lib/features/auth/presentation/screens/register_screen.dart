import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/social_auth_button.dart';
import '../../../profile/presentation/screens/profile_gate.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';
import 'login_screen.dart';

/// Student Registration Screen
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegisterPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _errorMessage = null;
        _infoMessage = null;
      });
      context.read<AuthBloc>().add(
            RegisterSubmitted(
              fullName: _nameController.text,
              email: _emailController.text,
              password: _passwordController.text,
              confirmPassword: _confirmPasswordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is Authenticated) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const ProfileGate(),
                ),
              );
            } else if (state is EmailVerificationRequired) {
              setState(() {
                _infoMessage =
                    'Registration successful! A verification link has been sent to ${state.email}. Please verify your email before logging in.';
              });
            } else if (state is AuthFailure) {
              setState(() {
                _errorMessage = state.message;
              });
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

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
                    key: _formKey,
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
                        if (_errorMessage != null)
                          ErrorBanner(
                            message: _errorMessage!,
                            onDismiss: () {
                              setState(() {
                                _errorMessage = null;
                              });
                            },
                          ),

                        // Info / Success Banner
                        if (_infoMessage != null) ...[
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
                                    _infoMessage!,
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
                          controller: _nameController,
                          prefixIcon: Icons.person_outline,
                          textInputAction: TextInputAction.next,
                          validator: Validators.validateName,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 16),

                        // Email Input
                        CustomTextField(
                          label: 'College or Personal Email',
                          hint: 'student@university.edu',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          textInputAction: TextInputAction.next,
                          validator: Validators.validateEmail,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 16),

                        // Password Input
                        CustomTextField(
                          label: 'Password',
                          hint: 'At least 8 characters',
                          controller: _passwordController,
                          isPassword: true,
                          prefixIcon: Icons.lock_outline,
                          textInputAction: TextInputAction.next,
                          validator: Validators.validatePassword,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password Input
                        CustomTextField(
                          label: 'Confirm Password',
                          hint: 'Re-enter your password',
                          controller: _confirmPasswordController,
                          isPassword: true,
                          prefixIcon: Icons.lock_clock_outlined,
                          textInputAction: TextInputAction.done,
                          validator: (value) =>
                              Validators.validateConfirmPassword(
                            _passwordController.text,
                            value,
                          ),
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 24),

                        // Register Button
                        PrimaryButton(
                          text: 'Create Student Account',
                          onPressed: _onRegisterPressed,
                          isLoading: isLoading,
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
                        SocialAuthButton(
                          type: SocialType.google,
                          isLoading: isLoading,
                          onPressed: () {
                            context
                                .read<AuthBloc>()
                                .add(const GoogleLoginSubmitted());
                          },
                        ),
                        const SizedBox(height: 12),
                        SocialAuthButton(
                          type: SocialType.linkedin,
                          isLoading: isLoading,
                          onPressed: () {
                            context
                                .read<AuthBloc>()
                                .add(const LinkedInLoginSubmitted());
                          },
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
                              onTap: isLoading
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
