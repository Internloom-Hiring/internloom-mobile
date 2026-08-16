import 'package:flutter/material.dart';
import 'package:internloom_mobile/core/constants/app_colors.dart';

/// Task 2 — status badge for the five confirmed production values:
/// applied, shortlisted, rejected, selected, withdrawn. Distinct visual
/// treatment for the two terminal states (selected, rejected) vs the
/// rest, per the Sprint 2 spec.
///
/// AppColors.primary/.success/.textSecondary/.error all confirmed to
/// exist in core/constants/app_colors.dart (the unified theme file,
/// post Developer 1's Task 3 — the old lib/constants/theme.dart this
/// module originally pointed at is gone now).
class ApplicationStatusBadge extends StatelessWidget {
  const ApplicationStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;
    switch (status) {
      case 'applied':
        label = 'Applied';
        color = AppColors.textSecondary;
        break;
      case 'shortlisted':
        label = 'Shortlisted';
        color = AppColors.primary;
        break;
      case 'selected':
        label = 'Selected';
        color = AppColors.success;
        break;
      case 'rejected':
        label = 'Rejected';
        color = AppColors.error;
        break;
      case 'withdrawn':
        label = 'Withdrawn';
        color = AppColors.textSecondary;
        break;
      default:
        label = status;
        color = AppColors.textSecondary;
    }

    final isTerminal = status == 'selected' || status == 'rejected';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isTerminal ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: isTerminal ? 0.5 : 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: isTerminal ? FontWeight.w700 : FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
