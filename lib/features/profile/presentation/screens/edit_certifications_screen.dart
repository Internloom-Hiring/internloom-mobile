import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../constants/theme.dart';
import '../../provider/profile_provider.dart';
import '../widgets/tag_list_input.dart';

/// Certifications — optional list of strings (maps to the
/// `certifications` text column, JSON-encoded — see StudentProfile).
class EditCertificationsScreen extends StatefulWidget {
  const EditCertificationsScreen({super.key});

  @override
  State<EditCertificationsScreen> createState() => _EditCertificationsScreenState();
}

class _EditCertificationsScreenState extends State<EditCertificationsScreen> {
  late List<String> _certifications;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _certifications = List.of(context.read<ProfileProvider>().profile!.certifications);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final provider = context.read<ProfileProvider>();
    final ok = await provider.saveCertifications(_certifications);
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
      appBar: AppBar(title: const Text('Edit certifications')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          TagListInput(
            title: 'Certifications',
            values: _certifications,
            onChanged: (values) => setState(() => _certifications = values),
            addFieldHint: 'e.g. AWS Cloud Practitioner',
          ),
          const SizedBox(height: AppSpacing.lg),
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
    );
  }
}
