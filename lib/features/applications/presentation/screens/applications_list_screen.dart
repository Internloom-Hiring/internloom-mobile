import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:internloom_mobile/core/constants/app_colors.dart';
import 'package:internloom_mobile/core/navigation/route_names.dart';
import 'package:provider/provider.dart';

import '../../../../job_discovery/presentation/widgets/internloom_brand.dart';
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
      bottomNavigationBar: NavigationBar(
        backgroundColor: InternloomColors.white,
        indicatorColor: InternloomColors.greenLight,
        selectedIndex: 2,
        onDestinationSelected: (index) {
          if (index == 0) {
            context.goNamed(RouteNames.studentDiscover);
          } else if (index == 1) {
            context.goNamed(RouteNames.studentSavedJobs);
          } else if (index == 3) {
            context.goNamed(RouteNames.studentProfile);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Applications',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
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
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.15)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
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
        );
      },
    );
  }
}
