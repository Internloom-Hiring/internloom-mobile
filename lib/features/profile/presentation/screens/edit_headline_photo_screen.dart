// NOTE: filename kept as edit_headline_photo_screen.dart from an
// earlier draft (before the real schema was confirmed) to avoid
// renaming a file already written into the shared project folder.
// The actual schema has no headline/profile_photo_url/cover_banner_url
// columns, so this screen now covers Basic Info instead — full name
// and phone — the fields that section of the profile actually has
// somewhere to be saved. The class name reflects that.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:internloom_mobile/core/constants/app_colors.dart';
import '../../provider/profile_provider.dart';
import '../../utils/validators.dart';
import '../widgets/labeled_text_field.dart';

class EditBasicInfoScreen extends StatefulWidget {
  const EditBasicInfoScreen({super.key});

  @override
  State<EditBasicInfoScreen> createState() => _EditBasicInfoScreenState();
}

class _EditBasicInfoScreenState extends State<EditBasicInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _countryCodeController;
  late final TextEditingController _phoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>().profile!;
    _nameController = TextEditingController(text: profile.fullName);
    _countryCodeController = TextEditingController(text: profile.countryCode);
    _phoneController = TextEditingController(text: profile.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryCodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final provider = context.read<ProfileProvider>();
    final ok = await provider.saveBasicInfo(
      fullName: _nameController.text.trim(),
      countryCode: _countryCodeController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    setState(() => _isSaving = false);
    if (!mounted) return;
    if (ok) {
      context.pop();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Save failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit basic info')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            LabeledTextField(
              label: 'Full name',
              controller: _nameController,
              required: true,
              validator: (v) => Validators.requiredText(v, label: 'Full name'),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: LabeledTextField(
                    label: 'Code',
                    controller: _countryCodeController,
                    required: true,
                    hintText: '+91',
                    keyboardType: TextInputType.phone,
                    validator: Validators.countryCode,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: LabeledTextField(
                    label: 'Phone number',
                    controller: _phoneController,
                    required: true,
                    keyboardType: TextInputType.phone,
                    validator: Validators.phoneNumber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
