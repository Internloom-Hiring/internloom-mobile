import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../constants/theme.dart';
import '../../provider/profile_provider.dart';
import '../../utils/validators.dart';
import '../widgets/labeled_text_field.dart';

/// Education — required for "complete" (Section 2.2), matching the
/// real schema's college_name/college_state/college_city/course/
/// branch/graduation_year/cgpa columns.
class EditEducationScreen extends StatefulWidget {
  const EditEducationScreen({super.key});

  @override
  State<EditEducationScreen> createState() => _EditEducationScreenState();
}

class _EditEducationScreenState extends State<EditEducationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _collegeNameController;
  late final TextEditingController _collegeStateController;
  late final TextEditingController _collegeCityController;
  late final TextEditingController _courseController;
  late final TextEditingController _branchController;
  late final TextEditingController _gradYearController;
  late final TextEditingController _cgpaController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>().profile!;
    _collegeNameController = TextEditingController(text: profile.collegeName);
    _collegeStateController = TextEditingController(text: profile.collegeState);
    _collegeCityController = TextEditingController(text: profile.collegeCity);
    _courseController = TextEditingController(text: profile.course);
    _branchController = TextEditingController(text: profile.branch);
    _gradYearController = TextEditingController(text: profile.graduationYear?.toString() ?? '');
    _cgpaController = TextEditingController(text: profile.cgpa?.toString() ?? '');
  }

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final provider = context.read<ProfileProvider>();
    final ok = await provider.saveEducation(
      collegeName: _collegeNameController.text.trim(),
      collegeState: _collegeStateController.text.trim(),
      collegeCity: _collegeCityController.text.trim(),
      course: _courseController.text.trim(),
      branch: _branchController.text.trim(),
      graduationYear: int.parse(_gradYearController.text.trim()),
      cgpa: double.parse(_cgpaController.text.trim()),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Edit education')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
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
