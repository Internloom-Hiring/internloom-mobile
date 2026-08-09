import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../bloc/authentication_bloc.dart';
import '../../bloc/authentication_event.dart';
import '../../bloc/authentication_state.dart';

/// Forgot Password Screen
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _resetFormKey = GlobalKey<FormState>();
  final _emailInputController = TextEditingController();

  String? _displayedErrorMessage;
  bool _resetEmailWasSent = false;

  @override
  void dispose() {
    _emailInputController.dispose();
    super.dispose();
  }

  void _submitResetRequest() {
    final formInputsAreValid = _resetFormKey.currentState?.validate() ?? false;
    if (!formInputsAreValid) return;

    setState(() {
      _displayedErrorMessage = null;
      _resetEmailWasSent = false;
    });
    context.read<AuthenticationBloc>().add(
          PasswordResetEmailRequested(email: _emailInputController.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<AuthenticationBloc, AuthenticationState>(
          listener: (context, authState) {
            if (authState is PasswordResetEmailSent) {
              setState(() => _resetEmailWasSent = true);
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
                    key: _resetFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Icon
                        Center(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.bookTeal,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              color: AppColors.white,
                              size: 34,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Reset Password',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your registered email address and we will send you instructions to reset your password.',
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

                        // Success State View
                        if (_resetEmailWasSent) ...[
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.greenLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.leafGreen),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: AppColors.leafGreen,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Reset Link Sent!',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(color: AppColors.greenDark),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'We sent a password reset link to ${_emailInputController.text}. Please check your inbox and follow the link to update your password.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: AppColors.body),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          PrimaryButton(
                            text: 'Back to Login',
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ] else ...[
                          // Email Input
                          CustomTextField(
                            label: 'Account Email',
                            hint: 'student@university.edu',
                            controller: _emailInputController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            textInputAction: TextInputAction.done,
                            validator: Validators.validateEmail,
                            enabled: !isAuthenticating,
                          ),
                          const SizedBox(height: 24),

                          // Reset Button
                          PrimaryButton(
                            text: 'Send Reset Link',
                            onPressed: _submitResetRequest,
                            isLoading: isAuthenticating,
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Back link
                        if (!_resetEmailWasSent)
                          Center(
                            child: TextButton.icon(
                              onPressed: isAuthenticating
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.arrow_back,
                                size: 16,
                                color: AppColors.muted,
                              ),
                              label: const Text(
                                'Back to Login',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
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
