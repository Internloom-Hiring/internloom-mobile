import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/navigation/route_names.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/social_auth_button.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _showRoleSelection = true;
  bool _isStudent = true;

  @override
  void initState() {
    super.initState();
    // Show error passed in from SplashScreen (e.g. expired recovery link)
    if (widget.initialError != null) {
      _errorMessage = widget.initialError;
      _showRoleSelection = false; // Go straight to form if there's an error
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _errorMessage = null;
      });
      context.read<AuthBloc>().add(
            LoginSubmitted(
              email: _emailController.text,
              password: _passwordController.text,
            ),
          );
    }
  }

  Widget _buildRoleSelection() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: 24),
              Text(
                'Welcome to Internloom',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your account type to continue',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                    ),
              ),
              const SizedBox(height: 48),
              _buildRoleCard(
                title: 'Student',
                subtitle: 'Find internships and build your profile',
                icon: Icons.person_outline,
                onTap: () {
                  setState(() {
                    _showRoleSelection = false;
                    _isStudent = true;
                  });
                },
              ),
              const SizedBox(height: 20),
              _buildRoleCard(
                title: 'Company',
                subtitle: 'Post internships and hire top talent',
                icon: Icons.business_outlined,
                onTap: () {
                  setState(() {
                    _showRoleSelection = false;
                    _isStudent = false;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.leafGreen, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(bool isLoading) {
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back Button to return to Role Selection
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: isLoading
                        ? null
                        : () {
                            setState(() {
                              _showRoleSelection = true;
                              _errorMessage = null;
                            });
                          },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Back to role selection',
                  ),
                ),
                const SizedBox(height: 8),
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
                  'Log in to your Internloom ${_isStudent ? 'student' : 'company'} account',
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

                // Email Input
                CustomTextField(
                  label: _isStudent ? 'College or Personal Email' : 'Work Email',
                  hint: _isStudent ? 'student@university.edu' : 'hr@company.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.email_outlined,
                  validator: Validators.validateEmail,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 18),

                // Password Input
                CustomTextField(
                  label: 'Password',
                  hint: '••••••••',
                  controller: _passwordController,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icons.lock_outline,
                  validator: Validators.validatePassword,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 10),

                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            context.pushNamed(RouteNames.forgotPassword);
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
                  onPressed: _onLoginPressed,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: AppColors.border),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
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
                SocialAuthButton(
                  type: SocialType.google,
                  isLoading: isLoading,
                  onPressed: () {
                    context.read<AuthBloc>().add(const GoogleLoginSubmitted());
                  },
                ),
                const SizedBox(height: 12),
                SocialAuthButton(
                  type: SocialType.linkedin,
                  isLoading: isLoading,
                  onPressed: () {
                    context.read<AuthBloc>().add(const LinkedInLoginSubmitted());
                  },
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
                      onTap: isLoading
                          ? null
                          : () {
                              context.goNamed(RouteNames.register);
                            },
                      child: Text(
                        'Register',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            // Navigation on Authenticated / PasswordRecoveryRequired is handled
            // declaratively by AppRouter's redirect callback which subscribes to
            // AuthBloc via _RouterRefreshListenable. Adding navigation here too
            // would fire two competing context.goNamed calls on the same frame —
            // the second one hits an already-detached navigator context.
            if (state is AuthFailure) {
              setState(() {
                _errorMessage = state.message;
              });
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            if (_showRoleSelection) {
              return _buildRoleSelection();
            }

            return _buildLoginForm(isLoading);
          },
        ),
      ),
    );
  }
}
