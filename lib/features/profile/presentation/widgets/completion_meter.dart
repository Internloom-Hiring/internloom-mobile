import 'package:flutter/material.dart';

import '../../../../constants/theme.dart';

/// The profile-completion meter — Section 2.2: "a percentage plus a
/// short list of what's missing; the primary nudge to keep filling it
/// in." Section 2.3 requires this stay visible near the top of the
/// profile, not buried in settings — enforced by where callers place
/// this widget, not by anything in here.
class CompletionMeter extends StatelessWidget {
  const CompletionMeter({
    super.key,
    required this.percent,
    required this.missingItems,
  });

  final int percent;
  final List<String> missingItems;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              const Text(
                'Profile completion',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 8,
              backgroundColor: AppColors.meterTrack,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          if (missingItems.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Still missing: ${missingItems.join(', ')}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'Your profile is fully filled out.',
                style: TextStyle(fontSize: 13, color: AppColors.success),
              ),
            ),
        ],
      ),
    );
  }
}
