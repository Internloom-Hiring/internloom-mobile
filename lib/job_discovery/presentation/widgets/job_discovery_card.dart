import 'package:flutter/material.dart';

import '../../data/models/placement_drive.dart';

class JobDiscoveryCard extends StatelessWidget {
  const JobDiscoveryCard({
    super.key,
    required this.drive,
    this.onTap,
  });

  final PlacementDrive drive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = (drive.finalScore * 100).clamp(0, 100).toStringAsFixed(0);

    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        drive.jobTitle,
                        style: theme.textTheme.headlineSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Chip(
                      label: Text('$score% match'),
                      avatar: const Icon(Icons.auto_awesome, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if ((drive.location ?? '').trim().isNotEmpty)
                  _InfoLine(
                    icon: Icons.location_on_outlined,
                    text: drive.location!,
                  ),
                if ((drive.ctc ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _InfoLine(
                    icon: Icons.payments_outlined,
                    text: drive.ctc!,
                  ),
                ],
                if (drive.applicationDeadline != null) ...[
                  const SizedBox(height: 8),
                  _InfoLine(
                    icon: Icons.event_outlined,
                    text: 'Deadline: ${_formatDate(drive.applicationDeadline!)}',
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  drive.jobDescription.isEmpty
                      ? 'No job description provided.'
                      : drive.jobDescription,
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
                if (onTap != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Tap for details',
                        style: theme.textTheme.labelMedium,
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 18),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
