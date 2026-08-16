// NOTE: filename kept as edit_social_links_screen.dart from an
// earlier draft. The real schema only has a `linkedin_url` column (no
// github_url/portfolio_url), so this screen now edits just that one
// field rather than three.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:internloom_mobile/core/constants/app_colors.dart';
import '../../provider/profile_provider.dart';
import '../../utils/validators.dart';
import '../widgets/labeled_text_field.dart';

class EditLinkedinScreen extends StatefulWidget {
  const EditLinkedinScreen({super.key});

  @override
  State<EditLinkedinScreen> createState() => _EditLinkedinScreenState();
}

class _EditLinkedinScreenState extends State<EditLinkedinScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _linkedinController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _linkedinController =
        TextEditingController(text: context.read<ProfileProvider>().profile!.linkedinUrl);
  }

  @override
  void dispose() {
    _linkedinController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final provider = context.read<ProfileProvider>();
    final ok = await provider.saveLinkedin(_linkedinController.text.trim());
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
      appBar: AppBar(title: const Text('Edit LinkedIn')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const Text(
              'Optional — a low-effort trust signal for recruiters.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            LabeledTextField(
              label: 'LinkedIn',
              controller: _linkedinController,
              hintText: 'https://linkedin.com/in/...',
              keyboardType: TextInputType.url,
              validator: (v) => Validators.optionalUrl(v, label: 'LinkedIn link'),
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
