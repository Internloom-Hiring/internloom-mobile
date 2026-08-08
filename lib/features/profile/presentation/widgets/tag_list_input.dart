import 'package:flutter/material.dart';

import '../../../../constants/theme.dart';

/// Generic add/remove chip-list editor — the shared building block
/// behind Skills, Certifications, and Achievements, all of which are
/// "a list of short strings" in the real schema (JSON-encoded into a
/// `text` column — see StudentProfile). `suggestions`, if provided,
/// renders a second row of tappable chips to quickly add from (used
/// by Skills via kCommonSkills; Certifications/Achievements have none).
class TagListInput extends StatefulWidget {
  const TagListInput({
    super.key,
    required this.title,
    required this.values,
    required this.onChanged,
    this.suggestions = const [],
    this.addFieldHint = 'Add an item',
  });

  final String title;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final List<String> suggestions;
  final String addFieldHint;

  @override
  State<TagListInput> createState() => _TagListInputState();
}

class _TagListInputState extends State<TagListInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return;
    final alreadyAdded = widget.values.any((v) => v.toLowerCase() == value.toLowerCase());
    if (alreadyAdded) return;
    widget.onChanged([...widget.values, value]);
    _controller.clear();
  }

  void _remove(String value) {
    widget.onChanged(widget.values.where((v) => v != value).toList());
  }

  @override
  Widget build(BuildContext context) {
    final remainingSuggestions = widget.suggestions
        .where((s) => !widget.values.any((v) => v.toLowerCase() == s.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        if (widget.values.isEmpty)
          const Text('Nothing added yet', style: TextStyle(color: AppColors.textSecondary))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.values
                .map((v) => Chip(
                      label: Text(v),
                      onDeleted: () => _remove(v),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                    ))
                .toList(),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(hintText: widget.addFieldHint),
                onSubmitted: _add,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(onPressed: () => _add(_controller.text), icon: const Icon(Icons.add)),
          ],
        ),
        if (remainingSuggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Suggestions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: remainingSuggestions
                .map((s) => ActionChip(label: Text(s), onPressed: () => _add(s)))
                .toList(),
          ),
        ],
      ],
    );
  }
}
