import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:internloom_mobile/core/constants/app_colors.dart';
import '../../provider/profile_provider.dart';
import '../../utils/validators.dart';
import '../widgets/skill_chip_input.dart';

/// Skills — required, minimum 3 (Section 2.2/2.4). Not a
/// TextFormField, so validation is shown manually rather than via a
/// Form widget.
class EditSkillsScreen extends StatefulWidget {
  const EditSkillsScreen({super.key});

  @override
  State<EditSkillsScreen> createState() => _EditSkillsScreenState();
}

class _EditSkillsScreenState extends State<EditSkillsScreen> {
  late List<String> _skills;
  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _skills = List.of(context.read<ProfileProvider>().profile!.skills);
  }

  Future<void> _save() async {
    final error = Validators.skillsMinimum(_skills);
    setState(() => _error = error);
    if (error != null) return;

    setState(() => _isSaving = true);
    final provider = context.read<ProfileProvider>();
    final ok = await provider.saveSkills(_skills);
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
      appBar: AppBar(title: const Text('Edit skills')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          SkillChipInput(
            selectedSkills: _skills,
            onChanged: (skills) => setState(() {
              _skills = skills;
              _error = null;
            }),
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
    );
  }
}
