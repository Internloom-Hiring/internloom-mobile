import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/navigation/route_names.dart';
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

      await _supabase.from('companies').update({
        'company_name': _nameController.text,
        'hr_name': _hrNameController.text,
        'hr_contact': _hrContactController.text,
        'website': _websiteController.text,
        'description': _descriptionController.text,
        'approval_status': 'pending', // Requires re-approval after edit
      }).eq('profile_id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully! Status set to pending.')),
        );
        setState(() {
          _isEditing = false;
          _companyData?['company_name'] = _nameController.text;
          _companyData?['hr_name'] = _hrNameController.text;
          _companyData?['hr_contact'] = _hrContactController.text;
          _companyData?['website'] = _websiteController.text;
          _companyData?['description'] = _descriptionController.text;
          _companyData?['approval_status'] = 'pending';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        title: const Text('Company Profile', style: TextStyle(color: AppColors.ink)),
        iconTheme: const IconThemeData(color: AppColors.ink),
        elevation: 0,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _companyData == null
              ? const Center(child: Text('Company profile not found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Status Banner
                        if (_companyData?['approval_status'] == 'pending')
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange.shade700),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Your account is pending admin approval.',
                                    style: TextStyle(color: Colors.orange),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        CustomTextField(
                          label: 'Company Name',
                          controller: _nameController,
                          enabled: _isEditing,
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'HR Name',
                          controller: _hrNameController,
                          enabled: _isEditing,
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'HR Contact',
                          controller: _hrContactController,
                          enabled: _isEditing,
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'Website',
                          controller: _websiteController,
                          enabled: _isEditing,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'Company Description',
                          controller: _descriptionController,
                          enabled: _isEditing,
                        ),
                        const SizedBox(height: 32),
                        
                        if (_isEditing)
                          PrimaryButton(
                            text: 'Save Profile',
                            onPressed: _saveProfile,
                          ),
                          
                        if (!_isEditing) ...[
                          const SizedBox(height: 48),
                          Divider(color: AppColors.border),
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout, color: Colors.red),
                            label: const Text('Logout', style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }
}
