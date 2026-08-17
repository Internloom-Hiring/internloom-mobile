import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:internloom_mobile/core/constants/app_colors.dart';
import 'package:internloom_mobile/core/navigation/route_names.dart';
import 'package:provider/provider.dart';

import '../../../../job_discovery/presentation/widgets/internloom_brand.dart';
import '../../../../job_discovery/presentation/widgets/student_navigation_bar.dart';
import '../../data/models/application_entry.dart';
import '../../provider/applications_provider.dart';
import '../widgets/status_badge.dart';

/// Task 1 + 2 + 3 screen. Registered at path '/student/applications',
/// name RouteNames.studentApplications, in core/navigation/app_router.dart.
///
/// Given its own NavigationBar destination (index 2, between Saved and
/// Profile) on JobDiscoveryScreen's bottom nav — deliberately NOT a button
/// tucked under the Profile screen, per explicit instruction. Only
/// JobDiscoveryScreen currently owns this NavigationBar (SavedJobsScreen
/// and ProfileViewScreen don't have one of their own yet — a pre-existing
/// gap in Developer 2's screens, not something fixed here), so this screen
/// carries its own copy so it isn't a dead end with no way back except the
/// system back button.
class ApplicationsListScreen extends StatefulWidget {
  const ApplicationsListScreen({super.key});

  @override
  State<ApplicationsListScreen> createState() => _ApplicationsListScreenState();
}

class _ApplicationsListScreenState extends State<ApplicationsListScreen> {
  @override
  void initState() {
    super.initState();
    // Kick off the initial fetch + realtime subscription once, after the
    // first frame (so `context.read` has a valid provider to read from).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ApplicationsProvider>().start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApplicationsProvider>();

    return Scaffold(
      backgroundColor: InternloomColors.pageBackground,
      appBar: AppBar(
        backgroundColor: InternloomColors.white,
        foregroundColor: InternloomColors.ink,
        elevation: 0,
        title: const Text(
          'My Applications',
          style: TextStyle(
            color: InternloomColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: provider.refresh,
        child: _buildBody(provider),
      ),
      bottomNavigationBar: const StudentNavigationBar(selectedIndex: 2),
    );
  }

  Widget _buildBody(ApplicationsProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(
            child: Text(
              provider.errorMessage!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    }
    if (provider.applications.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text(
              'No applications yet — swipe right on a drive to apply.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: provider.applications.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final a = provider.applications[i];
        // Only applied/shortlisted applications can be withdrawn — once a
        // company has made a final call (selected/rejected) there's
        // nothing left for the student to withdraw.
        final canWithdraw = !a.isTerminal;
        final isWithdrawing = provider.withdrawingIds.contains(a.id);

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.15)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.driveTitle,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(a.companyName, style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ApplicationStatusBadge(status: a.status),
                ],
              ),
              if (canWithdraw) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    key: Key('withdrawButton-${a.id}'),
                    onPressed: isWithdrawing ? null : () => _confirmWithdraw(context, provider, a),
                    style: TextButton.styleFrom(foregroundColor: AppColors.error),
                    icon: isWithdrawing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.undo, size: 18),
                    label: Text(isWithdrawing ? 'Withdrawing…' : 'Withdraw'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmWithdraw(
    BuildContext context,
    ApplicationsProvider provider,
    ApplicationEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Withdraw application?'),
        content: Text(
          'You will no longer be considered for "${entry.driveTitle}" at ${entry.companyName}. '
          'The drive will reappear in your job stack so you can apply again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final success = await provider.withdraw(entry);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Application withdrawn. It\'s back in your job stack.'
              : 'Could not withdraw the application. Try again.',
        ),
      ),
    );
  }
}
