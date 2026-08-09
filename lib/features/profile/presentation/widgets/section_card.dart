import 'package:flutter/material.dart';

import '../../../../constants/theme.dart';

/// A single "profile section" block on the view screen (Education,
/// Skills, Experience, etc.), each with its own Edit action — Section
/// 2.3: "a dedicated edit screen per section... never one long
/// edit-everything form." This widget is the read-only display half
/// of that rule; the edit screens themselves are separate.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.onEdit,
    required this.child,
    this.isEmpty = false,
    this.emptyLabel = 'Not added yet',
  });

  final String title;
  final VoidCallback onEdit;
  final Widget child;
  final bool isEmpty;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(isEmpty ? 'Add' : 'Edit'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (isEmpty)
            Text(emptyLabel, style: const TextStyle(color: AppColors.textSecondary))
          else
            child,
        ],
      ),
    );
  }
}
