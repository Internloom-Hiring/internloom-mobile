import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../constants/theme.dart';
import '../../provider/profile_provider.dart';
import '../../utils/validators.dart';
import '../widgets/labeled_text_field.dart';

/// About me — optional (maps to the `about_me` column), so the only
/// validation is a soft max-length cap.
class EditAboutScreen extends StatefulWidget {
  const EditAboutScreen({super.key});

  @override
  State<EditAboutScreen> createState() => _EditAboutScreenState();
}

class _EditAboutScreenState extends State<EditAboutScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _aboutMeController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _aboutMeController =
        TextEditingController(text: context.read<ProfileProvider>().profile!.aboutMe);
  }

  @override
  void dispose() {
    _aboutMeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final provider = context.read<ProfileProvider>();
    final ok = await provider.saveAboutMe(_aboutMeController.text.trim());
    setState(() => _isSaving = false);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Save failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit about me')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const Text(
              'Optional — 2–3 sentences is plenty.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            LabeledTextField(
              label: 'About me',
              controller: _aboutMeController,
              maxLines: 5,
              maxLength: 300,
              validator: (v) => Validators.optionalMaxLength(v, 300, label: 'About me'),
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
