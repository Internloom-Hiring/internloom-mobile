import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';

class PostDriveScreen extends StatefulWidget {
  const PostDriveScreen({super.key});

  @override
  State<PostDriveScreen> createState() => _PostDriveScreenState();
}

class _PostDriveScreenState extends State<PostDriveScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ctcController = TextEditingController();
  final _locationController = TextEditingController();
  final _cgpaController = TextEditingController();
  final _skillsController = TextEditingController();
  
  DateTime? _lastDateToApply;
  bool _isSubmitting = false;
  String? _error;

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
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // Parse required skills as a list
      final skillsList = _skillsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      await client.from('placement_drives').insert({
        'company_id': userId,
        'status': 'pending', // Always pending initially
        'job_title': _titleController.text.trim(),
        'job_description': _descriptionController.text.trim(),
        'ctc': _ctcController.text.trim(),
        'location': _locationController.text.trim(),
        'eligibility_criteria': 'Min CGPA: ${_cgpaController.text.trim()}\nSkills: ${skillsList.join(', ')}',
        'application_deadline': _lastDateToApply!.toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Drive posted successfully. Waiting for approval.'),
            backgroundColor: AppColors.success,
          ),
        );
        // We would pop or navigate away here
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Post a Drive', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: AppColors.error)),
                const SizedBox(height: AppSpacing.md),
              ],
              
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              
              TextFormField(
                controller: _ctcController,
                decoration: const InputDecoration(
                  labelText: 'CTC',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              
              TextFormField(
                controller: _cgpaController,
                decoration: const InputDecoration(
                  labelText: 'Minimum CGPA Required',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Must be a valid number';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              
              TextFormField(
                controller: _skillsController,
                decoration: const InputDecoration(
                  labelText: 'Required Skills (comma separated)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Flutter, Dart, Firebase',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _lastDateToApply == null 
                    ? 'Select Last Date to Apply' 
                    : 'Last Date: ${_lastDateToApply!.toLocal().toString().split(' ')[0]}',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.all(AppSpacing.md),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.all(AppSpacing.md),
                ),
                child: _isSubmitting 
                  ? const CircularProgressIndicator(color: AppColors.white)
                  : const Text('Submit for Approval'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
