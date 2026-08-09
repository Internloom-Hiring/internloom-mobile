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
import 'login_screen.dart';

/// Screen for entering and saving a new password after password recovery link is clicked
class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _updatePasswordFormKey = GlobalKey<FormState>();
  final _newPasswordInputController = TextEditingController();
  final _confirmPasswordInputController = TextEditingController();

  String? _displayedErrorMessage;
  bool _passwordWasUpdated = false;

  @override
  void dispose() {
    _newPasswordInputController.dispose();
    _confirmPasswordInputController.dispose();
    super.dispose();
  }

  void _submitNewPassword() {
    final formInputsAreValid =
        _updatePasswordFormKey.currentState?.validate() ?? false;
    if (!formInputsAreValid) return;

    setState(() => _displayedErrorMessage = null);
    context.read<AuthenticationBloc>().add(
          NewPasswordSubmitted(
            newPassword: _newPasswordInputController.text,
            confirmPassword: _confirmPasswordInputController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<AuthenticationBloc, AuthenticationState>(
          listener: (context, authState) {
            if (authState is PasswordUpdateSucceeded) {
              setState(() => _passwordWasUpdated = true);
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
                    key: _updatePasswordFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Icon
                        Center(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.leafGreen,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.key_rounded,
                              color: AppColors.white,
                              size: 34,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Set New Password',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your password recovery is verified. Please enter your new password below.',
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

                        // Success view
                        if (_passwordWasUpdated) ...[
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
                                  'Password Updated!',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(color: AppColors.greenDark),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Your password has been successfully updated. You can now log in with your new password.',
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
                            text: 'Proceed to Login',
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                          ),
                        ] else ...[
                          // New Password Input
                          CustomTextField(
                            label: 'New Password',
                            hint: 'At least 8 characters',
                            controller: _newPasswordInputController,
                            isPassword: true,
                            prefixIcon: Icons.lock_outline,
                            textInputAction: TextInputAction.next,
                            validator: Validators.validatePassword,
                            enabled: !isAuthenticating,
                          ),
                          const SizedBox(height: 16),

                          // Confirm New Password Input
                          CustomTextField(
                            label: 'Confirm New Password',
                            hint: 'Re-enter new password',
                            controller: _confirmPasswordInputController,
                            isPassword: true,
                            prefixIcon: Icons.lock_clock_outlined,
                            textInputAction: TextInputAction.done,
                            validator: (value) =>
                                Validators.validateConfirmPassword(
                              _newPasswordInputController.text,
                              value,
                            ),
                            enabled: !isAuthenticating,
                          ),
                          const SizedBox(height: 24),

                          // Submit Button
                          PrimaryButton(
                            text: 'Update Password',
                            onPressed: _submitNewPassword,
                            isLoading: isAuthenticating,
                          ),
                        ],
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
