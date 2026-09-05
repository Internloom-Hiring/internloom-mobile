import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_event.dart';

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isEditing = false;
  Map<String, dynamic>? _companyData;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _hrNameController;
  late TextEditingController _hrContactController;
  late TextEditingController _websiteController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _hrNameController = TextEditingController();
    _hrContactController = TextEditingController();
    _websiteController = TextEditingController();
    _descriptionController = TextEditingController();
    _fetchProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hrNameController.dispose();
    _hrContactController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final res = await _supabase
          .from('companies')
          .select('*')
          .eq('profile_id', user.id)
          .maybeSingle();

      if (res != null) {
        _companyData = res;
        _nameController.text = res['company_name'] ?? '';
        _hrNameController.text = res['hr_name'] ?? '';
        _hrContactController.text = res['hr_contact'] ?? '';
        _websiteController.text = res['website'] ?? '';
        _descriptionController.text = res['description'] ?? '';
      }
    } catch (e) {
      debugPrint('Error fetching company profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Update editable fields only — Company Name remains locked and is never modified
      await _supabase.from('companies').update({
        'hr_name': _hrNameController.text.trim(),
        'hr_contact': _hrContactController.text.trim(),
        'website': _websiteController.text.trim(),
        'description': _descriptionController.text.trim(),
      }).eq('profile_id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() {
          _isEditing = false;
          _companyData?['hr_name'] = _hrNameController.text.trim();
          _companyData?['hr_contact'] = _hrContactController.text.trim();
          _companyData?['website'] = _websiteController.text.trim();
          _companyData?['description'] = _descriptionController.text.trim();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout() {
    context.read<AuthBloc>().add(const LogoutSubmitted());
  }

  @override
  Widget build(BuildContext context) {
    final approvalStatus = _companyData?['approval_status']?.toString().toLowerCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        title: const Text(
          'Company Profile',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.ink),
        elevation: 1,
        actions: [
          if (!_isLoading && _companyData != null)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              tooltip: _isEditing ? 'Cancel' : 'Edit Profile',
              onPressed: () {
                setState(() {
                  if (_isEditing) {
                    // Cancel editing, revert fields
                    _nameController.text = _companyData?['company_name'] ?? '';
                    _hrNameController.text = _companyData?['hr_name'] ?? '';
                    _hrContactController.text = _companyData?['hr_contact'] ?? '';
                    _websiteController.text = _companyData?['website'] ?? '';
                    _descriptionController.text = _companyData?['description'] ?? '';
                  }
                  _isEditing = !_isEditing;
                });
              },
            ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _companyData == null
                  ? const Center(child: Text('Company profile not found.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Status Banner
                        if (approvalStatus == 'pending')
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(AppSpacing.sm),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: AppColors.warning),
                                SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    'Your account is pending admin approval.',
                                    style: TextStyle(
                                      color: Color(0xFF92400E),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (approvalStatus == 'approved')
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.greenLight,
                              borderRadius: BorderRadius.circular(AppSpacing.sm),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: AppColors.success),
                                SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    'Verified & Approved Company Account',
                                    style: TextStyle(
                                      color: AppColors.greenDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Company Name — LOCKED (matching website's locked behavior)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Company Name',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.border,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lock, size: 10, color: AppColors.muted),
                                      SizedBox(width: 3),
                                      Text(
                                        'LOCKED',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _nameController,
                              enabled: false,
                              style: const TextStyle(color: AppColors.body),
                              decoration: const InputDecoration(
                                filled: true,
                                fillColor: Color(0xFFF8FAFC),
                                border: OutlineInputBorder(),
                                disabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: AppColors.border),
                                ),
                                helperText: 'Company name cannot be edited directly.',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // HR Name
                        CustomTextField(
                          label: 'HR Name',
                          controller: _hrNameController,
                          enabled: _isEditing,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // HR Contact
                        CustomTextField(
                          label: 'HR Contact Phone',
                          controller: _hrContactController,
                          enabled: _isEditing,
                          keyboardType: TextInputType.phone,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Website
                        CustomTextField(
                          label: 'Website URL',
                          controller: _websiteController,
                          enabled: _isEditing,
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Company Description
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Company Description',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _descriptionController,
                              enabled: _isEditing,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Save Changes Button (in edit mode)
                        if (_isEditing)
                          PrimaryButton(
                            text: 'Save Changes',
                            onPressed: _saveProfile,
                          ),

                        // Logout button (when not editing)
                        if (!_isEditing) ...[
                          const SizedBox(height: AppSpacing.lg),
                          const Divider(color: AppColors.border),
                          const SizedBox(height: AppSpacing.md),
                          OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout, color: AppColors.danger),
                            label: const Text(
                              'Logout',
                              style: TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.danger),
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.sm),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
