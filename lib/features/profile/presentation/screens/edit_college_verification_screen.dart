import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../constants/theme.dart';
import '../../data/storage_service.dart';
import '../../provider/profile_provider.dart';
import '../../utils/validators.dart';
import '../widgets/labeled_text_field.dart';

/// College verification — a real column group in the schema
/// (college_email, college_id_path, verification_status,
/// verification_method, college_verified) that wasn't in any earlier
/// draft of this feature.
///
/// The student can submit a college email and/or upload a college ID
/// document; verification_status/verification_method/college_verified
/// are system-owned (set by admin/backend logic, not this screen) and
/// shown read-only. Confirm the exact enum values for
/// verification_status/verification_method against the database —
/// 'pending'/'verified'/'rejected' and 'college_email'/'college_id'
/// are reasonable guesses used here as placeholders, not confirmed.
class EditCollegeVerificationScreen extends StatefulWidget {
  const EditCollegeVerificationScreen({super.key});

  @override
  State<EditCollegeVerificationScreen> createState() => _EditCollegeVerificationScreenState();
}

class _EditCollegeVerificationScreenState extends State<EditCollegeVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _collegeEmailController;
  File? _newIdFile;
  String? _newIdFileName;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _collegeEmailController =
        TextEditingController(text: context.read<ProfileProvider>().profile!.collegeEmail);
  }

  @override
  void dispose() {
    _collegeEmailController.dispose();
    super.dispose();
  }

  Future<void> _pickCollegeId() async {
    final result = await FilePicker
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);
    if (result.isEmpty || result.single.path == null) return;
    setState(() {
      _newIdFile = File(result.single.path!);
      _newIdFileName = result.single.name;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final provider = context.read<ProfileProvider>();
    final ok = await provider.saveCollegeVerification(
      collegeEmail: _collegeEmailController.text.trim(),
      newCollegeIdFile: _newIdFile,
      newCollegeIdFileName: _newIdFileName,
    );
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
    final profile = context.watch<ProfileProvider>().profile!;
    final currentIdName =
        profile.collegeIdPath != null ? StorageService.displayNameFor(profile.collegeIdPath!) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('College verification')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _StatusBadge(
              collegeVerified: profile.collegeVerified,
              verificationStatus: profile.verificationStatus,
              verificationMethod: profile.verificationMethod,
            ),
            const SizedBox(height: AppSpacing.lg),
            LabeledTextField(
              label: 'College email',
              controller: _collegeEmailController,
              required: true,
              hintText: 'you@college.edu',
              keyboardType: TextInputType.emailAddress,
              validator: Validators.collegeEmail,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (currentIdName != null) Text('Current ID on file: $currentIdName'),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _pickCollegeId,
              icon: const Icon(Icons.badge_outlined),
              label: Text(_newIdFileName ?? 'Upload college ID'),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit for verification'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.collegeVerified,
    required this.verificationStatus,
    required this.verificationMethod,
  });

  final bool collegeVerified;
  final String verificationStatus;
  final String verificationMethod;

  @override
  Widget build(BuildContext context) {
    final color = collegeVerified ? AppColors.success : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(collegeVerified ? Icons.verified : Icons.hourglass_empty, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              collegeVerified
                  ? 'Verified'
                  : 'Status: $verificationStatus'
                      '${verificationMethod != 'none' ? ' via $verificationMethod' : ''}',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
