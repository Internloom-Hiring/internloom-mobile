import 'package:flutter/material.dart';

import '../../constants/skills.dart';
import 'tag_list_input.dart';

/// Thin Skills-specific wrapper around TagListInput — kept as its own
/// widget (rather than inlining TagListInput everywhere Skills is
/// edited) so the "Your skills" title and kCommonSkills suggestions
/// don't need repeating at every call site.
class SkillChipInput extends StatelessWidget {
  const SkillChipInput({
    super.key,
    required this.selectedSkills,
    required this.onChanged,
  });

  final List<String> selectedSkills;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return TagListInput(
      title: 'Your skills',
      values: selectedSkills,
      onChanged: onChanged,
      suggestions: kCommonSkills,
      addFieldHint: 'Add a custom skill',
    );
  }
}
