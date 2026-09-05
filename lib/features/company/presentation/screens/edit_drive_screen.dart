import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';

class EditDriveScreen extends StatefulWidget {
  final Map<String, dynamic> drive;

  const EditDriveScreen({
    super.key,
    required this.drive,
  });

  @override
  State<EditDriveScreen> createState() => _EditDriveScreenState();
}

class _EditDriveScreenState extends State<EditDriveScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _ctcController;
  late final TextEditingController _locationController;
  late final TextEditingController _cgpaController;
  late final TextEditingController _skillsController;

  DateTime? _lastDateToApply;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final d = widget.drive;

    _titleController = TextEditingController(text: d['job_title']?.toString() ?? '');
    _descriptionController = TextEditingController(text: d['job_description']?.toString() ?? '');
    _ctcController = TextEditingController(text: d['ctc']?.toString() ?? '');
    _locationController = TextEditingController(text: d['location']?.toString() ?? '');

    // Parse eligibility_criteria
    String initialCgpa = '';
    String initialSkills = '';
    final criteria = d['eligibility_criteria']?.toString() ?? '';
    final cgpaMatch = RegExp(r'Min\s*CGPA:\s*([0-9.]+)').firstMatch(criteria);
    if (cgpaMatch != null) {
      initialCgpa = cgpaMatch.group(1) ?? '';
    }
    final skillsMatch = RegExp(r'Skills:\s*(.*)', caseSensitive: false).firstMatch(criteria);
    if (skillsMatch != null) {
      initialSkills = skillsMatch.group(1)?.trim() ?? '';
    }

    _cgpaController = TextEditingController(text: initialCgpa);
    _skillsController = TextEditingController(text: initialSkills);

    final deadlineStr = d['application_deadline']?.toString();
    if (deadlineStr != null && deadlineStr.isNotEmpty) {
      _lastDateToApply = DateTime.tryParse(deadlineStr);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ctcController.dispose();
    _locationController.dispose();
    _cgpaController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initial = _lastDateToApply ?? DateTime.now().add(const Duration(days: 7));
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(DateTime.now()) ? DateTime.now() : initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date != null) {
      setState(() {
        _lastDateToApply = date;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lastDateToApply == null) {
      setState(() => _error = 'Please select a last date to apply');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;
      final driveId = widget.drive['id'];
      if (driveId == null) throw Exception('Drive ID is missing');

      final skillsList = _skillsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // UPDATE existing placement_drives row (do NOT change status)
      await client.from('placement_drives').update({
        'job_title': _titleController.text.trim(),
        'job_description': _descriptionController.text.trim(),
        'ctc': _ctcController.text.trim(),
        'location': _locationController.text.trim(),
        'eligibility_criteria':
            'Min CGPA: ${_cgpaController.text.trim()}\nSkills: ${skillsList.join(', ')}',
        'application_deadline': _lastDateToApply!.toIso8601String(),
      }).eq('id', driveId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Drive details updated successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (widget.drive['status'] as String? ?? '').toLowerCase();
    final isApproved = status == 'approved';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Edit Drive',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isApproved) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Editing an approved drive updates it live immediately.',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Text(_error!, style: const TextStyle(color: AppColors.error)),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Job Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Job Title',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.white,
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Job Description',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.white,
                ),
                maxLines: 4,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // CTC
              TextFormField(
                controller: _ctcController,
                decoration: const InputDecoration(
                  labelText: 'CTC / Salary',
                  hintText: 'e.g. 6-8 LPA',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.white,
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g. Remote, Bangalore',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.white,
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // Minimum CGPA
              TextFormField(
                controller: _cgpaController,
                decoration: const InputDecoration(
                  labelText: 'Minimum CGPA Required',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.white,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (double.tryParse(v.trim()) == null) return 'Must be a valid number';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Required Skills
              TextFormField(
                controller: _skillsController,
                decoration: const InputDecoration(
                  labelText: 'Required Skills (comma separated)',
                  hintText: 'e.g. Flutter, Dart, Firebase',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.white,
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // Last Date to Apply
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today, color: AppColors.primary),
                label: Text(
                  _lastDateToApply == null
                      ? 'Select Last Date to Apply'
                      : 'Deadline: ${_lastDateToApply!.toLocal().toString().split(' ')[0]}',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  backgroundColor: AppColors.white,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}
