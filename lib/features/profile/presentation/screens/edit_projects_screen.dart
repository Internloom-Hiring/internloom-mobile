import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:internloom_mobile/core/constants/app_colors.dart';
import '../../data/models/project_entry.dart';
import '../../provider/profile_provider.dart';
import '../../utils/validators.dart';
import '../widgets/labeled_text_field.dart';

/// Projects & portfolio links — optional overall (Section 2.2). Each
/// entry requires a title; the link, if provided, must be a valid URL.
class EditProjectsScreen extends StatefulWidget {
  const EditProjectsScreen({super.key});

  @override
  State<EditProjectsScreen> createState() => _EditProjectsScreenState();
}

class _EditProjectsScreenState extends State<EditProjectsScreen> {
  late List<ProjectEntry> _entries;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _entries = List.of(context.read<ProfileProvider>().profile!.projects);
  }

  Future<void> _openEntryEditor({ProjectEntry? existing}) async {
    final result = await showModalBottomSheet<ProjectEntry>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProjectEntrySheet(entry: existing),
    );
    if (result == null) return;
    setState(() {
      if (existing != null) {
        final index = _entries.indexWhere((e) => e.id == existing.id);
        _entries[index] = result;
      } else {
        _entries.add(result);
      }
    });
  }

  void _removeEntry(ProjectEntry entry) {
    setState(() => _entries.removeWhere((e) => e.id == entry.id));
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final provider = context.read<ProfileProvider>();
    final ok = await provider.saveProjects(_entries);
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
      appBar: AppBar(
        title: const Text('Edit projects'),
        actions: [
          IconButton(onPressed: () => _openEntryEditor(), icon: const Icon(Icons.add)),
        ],
      ),
      body: _entries.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No projects added yet — optional, but helps you stand out.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: () => _openEntryEditor(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add project'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                return Card(
                  child: ListTile(
                    title: Text(entry.title),
                    subtitle: Text(
                      entry.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _openEntryEditor(existing: entry),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () => _removeEntry(entry),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save'),
        ),
      ),
    );
  }
}

class _ProjectEntrySheet extends StatefulWidget {
  const _ProjectEntrySheet({this.entry});

  final ProjectEntry? entry;

  @override
  State<_ProjectEntrySheet> createState() => _ProjectEntrySheetState();
}

class _ProjectEntrySheetState extends State<_ProjectEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _linkController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry?.title ?? '');
    _descriptionController = TextEditingController(text: widget.entry?.description ?? '');
    _linkController = TextEditingController(text: widget.entry?.link ?? '');
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final entry = ProjectEntry(
      id: widget.entry?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      link: _linkController.text.trim(),
    );
    context.pop(entry);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.entry == null ? 'Add project' : 'Edit project',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.md),
              LabeledTextField(
                label: 'Title',
                controller: _titleController,
                required: true,
                validator: (v) => Validators.requiredText(v, label: 'Title'),
              ),
              LabeledTextField(
                label: 'Description',
                controller: _descriptionController,
                maxLines: 3,
              ),
              LabeledTextField(
                label: 'Link',
                controller: _linkController,
                hintText: 'https://...',
                validator: (v) => Validators.optionalUrl(v, label: 'Project link'),
              ),
              ElevatedButton(onPressed: _submit, child: const Text('Done')),
            ],
          ),
        ),
      ),
    );
  }
}
