import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:internloom_mobile/core/constants/app_colors.dart';
import '../../provider/profile_provider.dart';
import '../widgets/tag_list_input.dart';

/// Achievements — optional list of strings (maps to the
/// `achievements` text column, JSON-encoded — see StudentProfile).
class EditAchievementsScreen extends StatefulWidget {
  const EditAchievementsScreen({super.key});

  @override
  State<EditAchievementsScreen> createState() => _EditAchievementsScreenState();
}

class _EditAchievementsScreenState extends State<EditAchievementsScreen> {
  late List<String> _achievements;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _achievements = List.of(context.read<ProfileProvider>().profile!.achievements);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final provider = context.read<ProfileProvider>();
    final ok = await provider.saveAchievements(_achievements);
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
      appBar: AppBar(title: const Text('Edit achievements')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          TagListInput(
            title: 'Achievements',
            values: _achievements,
            onChanged: (values) => setState(() => _achievements = values),
            addFieldHint: 'e.g. Winner, Smart India Hackathon 2025',
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
