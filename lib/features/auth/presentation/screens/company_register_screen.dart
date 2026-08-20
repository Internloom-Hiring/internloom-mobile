import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';

/// Company Registration Screen
class CompanyRegisterScreen extends StatefulWidget {
  const CompanyRegisterScreen({super.key});

  @override
  State<CompanyRegisterScreen> createState() => _CompanyRegisterScreenState();
}

class _CompanyRegisterScreenState extends State<CompanyRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Auth fields
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Company fields
  final _companyNameController = TextEditingController();
  final _hrNameController = TextEditingController();
  final _hrContactController = TextEditingController();
  final _websiteController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyNameController.dispose();
    _hrNameController.dispose();
    _hrContactController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateCompanyPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 10) {
      return 'Password must be at least 10 characters.';
    }
    return null;
  }

  void _onRegisterPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _errorMessage = null;
        _infoMessage = null;
      });
      context.read<AuthBloc>().add(
            CompanyRegisterSubmitted(
              username: _usernameController.text,
              email: _emailController.text,
              password: _passwordController.text,
              confirmPassword: _confirmPasswordController.text,
              companyName: _companyNameController.text,
              hrName: _hrNameController.text,
              hrContact: _hrContactController.text,
              website: _websiteController.text.isNotEmpty ? _websiteController.text : null,
              description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
              // PENDING: file uploads are stubbed out until the storage bucket is created
              incorporationCertPath: null,
              pitchDeckPath: null,
            ),
          );
    }
  }

  Widget _buildFileUploadControl({
    required String title,
    required String acceptedFormats,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.cloud_upload_outlined, color: AppColors.muted, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    acceptedFormats,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            // Navigation on Authenticated is handled declaratively by
            // AppRouter's redirect — see LoginScreen for the full rationale.
            if (state is AuthFailure) {
              setState(() {
                _errorMessage = state.message;
              });
            } else if (state is CompanyRegistrationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account created — pending admin approval.'),
                  backgroundColor: AppColors.leafGreen,
                ),
              );
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
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
                              Icons.business_outlined,
                              color: AppColors.white,
                              size: 34,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Company Registration',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Join Internloom to find top student talent',
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
                        
                        // Admin Approval Banner
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: AppColors.warning, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Your account requires admin approval before posting drives. We typically respond within 24 hours.',
                                  style: TextStyle(
                                    color: AppColors.warning.withValues(alpha: 0.9),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Account Information Section
                        const Text(
                          'Account Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Username
                        CustomTextField(
                          label: 'Username',
                          hint: 'company_hr',
                          controller: _usernameController,
                          prefixIcon: Icons.alternate_email,
                          textInputAction: TextInputAction.next,
                          validator: Validators.validateName,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 16),

                        // Email Input
                        CustomTextField(
                          label: 'Email',
                          hint: 'hr@company.com',
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
                          hint: 'At least 10 characters',
                          controller: _passwordController,
                          isPassword: true,
                          prefixIcon: Icons.lock_outline,
                          textInputAction: TextInputAction.next,
                          validator: _validateCompanyPassword,
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
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              Validators.validateConfirmPassword(
                            _passwordController.text,
                            value,
                          ),
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 32),

                        // Company Information Section
                        const Text(
                          'Company Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Company Name Input
                        CustomTextField(
                          label: 'Company Name',
                          hint: 'Acme Corp',
                          controller: _companyNameController,
                          prefixIcon: Icons.business,
                          textInputAction: TextInputAction.next,
                          validator: (value) => value == null || value.trim().isEmpty
                              ? 'Company Name is required'
                              : null,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 16),
                        
                        // HR Name Input
                        CustomTextField(
                          label: 'HR Name',
                          hint: 'Jane Doe',
                          controller: _hrNameController,
                          prefixIcon: Icons.person_outline,
                          textInputAction: TextInputAction.next,
                          validator: (value) => value == null || value.trim().isEmpty
                              ? 'HR Name is required'
                              : null,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 16),
                        
                        // HR Contact Input
                        CustomTextField(
                          label: 'HR Contact',
                          hint: '+1 234 567 8900',
                          controller: _hrContactController,
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone_outlined,
                          textInputAction: TextInputAction.next,
                          validator: (value) => value == null || value.trim().isEmpty
                              ? 'HR Contact is required'
                              : null,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 16),
                        
                        // Website Input
                        CustomTextField(
                          label: 'Website (Optional)',
                          hint: 'https://www.company.com',
                          controller: _websiteController,
                          keyboardType: TextInputType.url,
                          prefixIcon: Icons.language,
                          textInputAction: TextInputAction.next,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 16),
                        
                        // Company Description Input
                        CustomTextField(
                          label: 'Company Description (Optional)',
                          hint: 'Tell us about your company...',
                          controller: _descriptionController,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          maxLines: 3,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 32),
                        
                        // Documents Section
                        const Text(
                          'Documents (Optional)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'These documents help expedite your approval process.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Incorporation Certificate Upload
                        _buildFileUploadControl(
                          title: 'Upload Incorporation Certificate',
                          acceptedFormats: 'PDF, JPG, or PNG (Max 5MB)',
                          onTap: isLoading ? () {} : () {
                            // TODO: Implement file picker
                          },
                        ),
                        const SizedBox(height: 12),
                        
                        // Pitch Deck Upload
                        _buildFileUploadControl(
                          title: 'Upload Pitch Deck',
                          acceptedFormats: 'PPT or PPTX (Max 10MB)',
                          onTap: isLoading ? () {} : () {
                            // TODO: Implement file picker
                          },
                        ),
                        const SizedBox(height: 32),

                        // Register Button
                        PrimaryButton(
                          text: 'Create Company Account',
                          onPressed: _onRegisterPressed,
                          isLoading: isLoading,
                        ),
                        const SizedBox(height: 24),

                        // Login Navigation Link
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Already registered? ',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.muted),
                            ),
                            GestureDetector(
                              onTap: isLoading
                                  ? null
                                  : () {
                                      Navigator.pop(context);
                                    },
                              child: Text(
                                'Sign In',
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
