import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../constants/theme.dart';
import '../../data/storage_service.dart';
import '../../provider/profile_provider.dart';
import '../../utils/validators.dart';

/// Resume (PDF) — required for the guided-setup minimum (Section
/// 2.4). Saves to `resume_path` (a storage path, not a full URL); the
/// display name shown here is derived from the path itself since the
/// schema has no separate resume_file_name column.
class EditResumeScreen extends StatefulWidget {
  const EditResumeScreen({super.key});

  @override
  State<EditResumeScreen> createState() => _EditResumeScreenState();
}

class _EditResumeScreenState extends State<EditResumeScreen> {
  File? _newFile;
  String? _newFileName;
  String? _error;
  bool _isSaving = false;

  Future<void> _pickResume() async {
    final result =
        await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result.isEmpty || result.single.path == null) return;
    final fileName = File(result.single.path!).path.split('/').last;
    final error = Validators.resumeFile(fileName: fileName, sizeBytes: await File(result.single.path!).length());
    setState(() {
      _error = error;
      if (error == null) {
        _newFile = File(result.single.path!);
        _newFileName = fileName;
      }
    });
  }

  Future<void> _save() async {
    if (_newFile == null) {
      setState(() => _error = 'Choose a PDF to upload first');
      return;
    }
    setState(() => _isSaving = true);
    final provider = context.read<ProfileProvider>();
    final ok = await provider.saveResume(_newFile!, fileName: _newFileName!);
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
    final currentPath = context.watch<ProfileProvider>().profile?.resumePath;
    final currentDisplayName =
        currentPath != null ? StorageService.displayNameFor(currentPath) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit resume')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentDisplayName != null) ...[
              Row(
                children: [
                  const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Current: $currentDisplayName', overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            const Text(
              'PDF only, up to 5 MB. Companies preview it without leaving your card.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: _pickResume,
              icon: const Icon(Icons.upload_file),
              label: Text(_newFileName ?? 'Choose new PDF'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ],
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
      ),
    );
  }
}
