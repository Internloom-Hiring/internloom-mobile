import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:internloom_mobile/core/constants/app_colors.dart';
import 'package:internloom_mobile/core/navigation/route_names.dart';
import '../../provider/profile_provider.dart';
import '../../utils/validators.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/skill_chip_input.dart';

/// First-time-only flow (Section 2.4): Education + 3 Skills + Resume,
/// the guided-setup minimum. Sign Up (Authentication's workstream)
/// should route here before a student ever reaches Home; this screen
/// pushes-and-replaces into ProfileViewScreen once the minimum is
/// met, which is what "Home unlocked" means from this module's side.
class GuidedSetupScreen extends StatefulWidget {
  const GuidedSetupScreen({super.key});

  @override
  State<GuidedSetupScreen> createState() => _GuidedSetupScreenState();
}

class _GuidedSetupScreenState extends State<GuidedSetupScreen> {
  int _step = 0;
  final _educationFormKey = GlobalKey<FormState>();

  final _collegeNameController = TextEditingController();
  final _collegeStateController = TextEditingController();
  final _collegeCityController = TextEditingController();
  final _courseController = TextEditingController();
  final _branchController = TextEditingController();
  final _gradYearController = TextEditingController();
  final _cgpaController = TextEditingController();

  List<String> _skills = [];
  String? _skillsError;

  File? _resumeFile;
  String? _resumeFileName;
  String? _resumeError;
  bool _isUploading = false;

  @override
  void dispose() {
    _collegeNameController.dispose();
    _collegeStateController.dispose();
    _collegeCityController.dispose();
    _courseController.dispose();
    _branchController.dispose();
    _gradYearController.dispose();
    _cgpaController.dispose();
    super.dispose();
  }

  void _nextFromEducation() {
    if (_educationFormKey.currentState!.validate()) {
      setState(() => _step = 1);
    }
  }

  void _nextFromSkills() {
    final error = Validators.skillsMinimum(_skills);
    setState(() => _skillsError = error);
    if (error == null) setState(() => _step = 2);
  }

  Future<void> _pickResume() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result.isEmpty || result.single.path == null) return;
    final file = File(result.single.path!);
    final fileName = result.single.name;
    final error = Validators.resumeFile(fileName: fileName, sizeBytes: await file.length());
    setState(() {
      _resumeError = error;
      if (error == null) {
        _resumeFile = file;
        _resumeFileName = fileName;
      }
    });
  }

  Future<void> _finishSetup() async {
    if (_resumeFile == null) {
      setState(() => _resumeError = Validators.resumeFile(fileName: null, sizeBytes: null));
      return;
    }

    setState(() => _isUploading = true);
    final provider = context.read<ProfileProvider>();

    final eduOk = await provider.saveEducation(
      collegeName: _collegeNameController.text.trim(),
      collegeState: _collegeStateController.text.trim(),
      collegeCity: _collegeCityController.text.trim(),
      course: _courseController.text.trim(),
      branch: _branchController.text.trim(),
      graduationYear: int.parse(_gradYearController.text.trim()),
      cgpa: double.parse(_cgpaController.text.trim()),
    );
    final skillsOk = await provider.saveSkills(_skills);
    final resumeOk = await provider.saveResume(_resumeFile!, fileName: _resumeFileName!);

    setState(() => _isUploading = false);

    if (!mounted) return;

    if (eduOk && skillsOk && resumeOk) {
      // go clears the entire back-stack and lands on studentProfile;
      // AppRouter redirect will skip the setup guard since profile is now complete.
      context.goNamed(RouteNames.studentProfile);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Something went wrong. Please retry.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set up your profile')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (_step + 1) / 3,
              backgroundColor: AppColors.meterTrack,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
            const SizedBox(height: 6),
            Text('Step ${_step + 1} of 3', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: IndexedStack(
                index: _step,
                children: [_buildEducationStep(), _buildSkillsStep(), _buildResumeStep()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationStep() {
    return Form(
      key: _educationFormKey,
      child: ListView(
        children: [
          const Text('Education', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            'Required — companies filter on this.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          LabeledTextField(
            label: 'College name',
            controller: _collegeNameController,
            required: true,
            validator: (v) => Validators.requiredText(v, label: 'College name'),
          ),
          LabeledTextField(
            label: 'College state',
            controller: _collegeStateController,
            required: true,
            validator: (v) => Validators.requiredText(v, label: 'College state'),
          ),
          LabeledTextField(
            label: 'College city',
            controller: _collegeCityController,
            required: true,
            validator: (v) => Validators.requiredText(v, label: 'College city'),
          ),
          LabeledTextField(
            label: 'Course',
            controller: _courseController,
            required: true,
            hintText: 'e.g. B.E. Computer Science',
            validator: (v) => Validators.requiredText(v, label: 'Course'),
          ),
          LabeledTextField(
            label: 'Branch',
            controller: _branchController,
            required: true,
            validator: (v) => Validators.requiredText(v, label: 'Branch'),
          ),
          LabeledTextField(
            label: 'Graduation year',
            controller: _gradYearController,
            required: true,
            keyboardType: TextInputType.number,
            validator: Validators.graduationYear,
          ),
          LabeledTextField(
            label: 'CGPA',
            controller: _cgpaController,
            required: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: Validators.cgpa,
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(onPressed: _nextFromEducation, child: const Text('Continue')),
        ],
      ),
    );
  }

  Widget _buildSkillsStep() {
    return ListView(
      children: [
        const Text('Skills', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
          'Add at least 3 — this is what swipe/match filtering keys off.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        SkillChipInput(
          selectedSkills: _skills,
          onChanged: (skills) => setState(() {
            _skills = skills;
            _skillsError = null;
          }),
        ),
        if (_skillsError != null) ...[
          const SizedBox(height: 8),
          Text(_skillsError!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
        ],
        const SizedBox(height: AppSpacing.md),
        ElevatedButton(onPressed: _nextFromSkills, child: const Text('Continue')),
      ],
    );
  }

  Widget _buildResumeStep() {
    return ListView(
      children: [
        const Text('Resume', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
          'One PDF, up to 5 MB. Companies preview it without leaving your card.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: _pickResume,
          icon: const Icon(Icons.upload_file),
          label: Text(_resumeFileName ?? 'Choose PDF'),
        ),
        if (_resumeError != null) ...[
          const SizedBox(height: 8),
          Text(_resumeError!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
        ],
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton(
          onPressed: _isUploading ? null : _finishSetup,
          child: _isUploading
              ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Finish setup'),
        ),
      ],
    );
  }
}
