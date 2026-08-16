import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/job_discovery_filters.dart';
import '../../data/models/placement_drive.dart';
import '../../data/models/swipe_action.dart';
import '../../provider/job_discovery_provider.dart';
import '../widgets/internloom_brand.dart';
import '../widgets/job_discovery_filter_sheet.dart';
import '../widgets/swipe_deck.dart';
import '../../../core/navigation/route_names.dart';

class JobDiscoveryScreen extends StatelessWidget {
  const JobDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => JobDiscoveryProvider()..loadInitial(),
      child: const _JobDiscoveryView(),
    );
  }
}

class _JobDiscoveryView extends StatelessWidget {
  const _JobDiscoveryView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobDiscoveryProvider>();

    return Scaffold(
      backgroundColor: InternloomColors.pageBackground,
      appBar: AppBar(
        backgroundColor: InternloomColors.white,
        foregroundColor: InternloomColors.ink,
        elevation: 0,
        title: const Text(
          'Discover Jobs',
          style: TextStyle(
            color: InternloomColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Filters',
            onPressed: () => _showFilters(context, provider),
            icon: Badge(
              isLabelVisible: provider.hasActiveFilters,
              smallSize: 8,
              child: const Icon(
                Icons.filter_list,
                color: InternloomColors.leafGreen,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Saved jobs',
            onPressed: () => _openSavedJobs(context, provider),
            icon: const Icon(
              Icons.bookmark_border,
              color: InternloomColors.bookTeal,
            ),
          ),
        ],
      ),
      body: _buildBody(context, provider),
      bottomNavigationBar: NavigationBar(
        backgroundColor: InternloomColors.white,
        indicatorColor: InternloomColors.greenLight,
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) {
            context.goNamed(RouteNames.studentSavedJobs);
          } else if (index == 2) {
            context.goNamed(RouteNames.studentApplications);
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

  Widget _buildBody(
    BuildContext context,
    JobDiscoveryProvider provider,
  ) {
    if (provider.loadState == JobDiscoveryLoadState.loading &&
        provider.cards.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.cards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off,
                size: 44,
                color: InternloomColors.muted,
              ),
              const SizedBox(height: 12),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: InternloomColors.body),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: InternloomColors.leafGreen,
                  foregroundColor: InternloomColors.white,
                ),
                onPressed: provider.retry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.cards.isEmpty && provider.hasReachedEnd) {
      return _AllCaughtUp(
        hasFilters: provider.hasActiveFilters,
        onClearFilters: provider.clearFilters,
        onOpenSaved: () => context.pushNamed(RouteNames.studentSavedJobs),
      );
    }

    if (provider.cards.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: Column(
        children: [
          if (provider.hasActiveFilters)
            _ActiveFilterBar(filters: provider.filters),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SwipeDeck(
                cards: provider.cards,
                onSwipe: (direction) => _handleSwipe(
                  context,
                  provider,
                  direction,
                ),
                onOpenDetails: (drive) => _openDetails(context, drive),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _SwipeHint(),
          // This control is driven by provider.canUndo. The provider clears
          // it after exactly 3 seconds, so there is no stale undo action.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: provider.canUndo
                ? Padding(
                    key: const ValueKey('undo-visible'),
                    padding: const EdgeInsets.only(top: 6),
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: InternloomColors.leafGreen,
                      ),
                      onPressed: () => _undo(context, provider),
                      icon: const Icon(Icons.undo),
                      label: const Text('Undo last swipe'),
                    ),
                  )
                : const SizedBox(
                    key: ValueKey('undo-hidden'),
                    height: 40,
                  ),
          ),
          if (provider.isLoading)
            const LinearProgressIndicator(
              minHeight: 2,
              color: InternloomColors.leafGreen,
            )
          else
            const SizedBox(height: 2),
        ],
      ),
    );
  }

  Future<void> _openSavedJobs(
    BuildContext context,
    JobDiscoveryProvider provider,
  ) async {
    await context.pushNamed(RouteNames.studentSavedJobs);

    if (!context.mounted) return;

    // Refresh exclusions after a saved job is unsaved/applied.
    await provider.loadInitial();
  }

  Future<void> _showFilters(
    BuildContext context,
    JobDiscoveryProvider provider,
  ) async {
    final filters = await showModalBottomSheet<JobDiscoveryFilters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => JobDiscoveryFilterSheet(
        initialFilters: provider.filters,
      ),
    );

    if (filters == null || !context.mounted) return;

    await provider.applyFilters(
      location: filters.location,
      ctc: filters.ctc,
    );
  }

  void _handleSwipe(
    BuildContext context,
    JobDiscoveryProvider provider,
    SwipeDirection direction,
  ) {
    provider.swipeTop(direction);

    if (!context.mounted) return;

    final label = switch (direction) {
      SwipeDirection.left => 'Dismissed',
      SwipeDirection.up => 'Saved for later',
      SwipeDirection.right => 'Application sent',
    };

    // Status only. The Undo control itself lives in the page and expires
    // with provider.canUndo after three seconds.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(label),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  Future<void> _undo(
    BuildContext context,
    JobDiscoveryProvider provider,
  ) async {
    final restored = await provider.undoLastSwipe();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            restored
                ? 'Last swipe undone.'
                : 'That swipe can no longer be undone.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _openDetails(BuildContext context, PlacementDrive drive) {
    context.pushNamed(
      RouteNames.studentJobDetails,
      pathParameters: {'driveId': drive.id},
      extra: drive,
    );
  }
}

class _ActiveFilterBar extends StatelessWidget {
  const _ActiveFilterBar({required this.filters});

  final JobDiscoveryFilters filters;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        children: [
          if (filters.location.trim().isNotEmpty)
            Chip(
              backgroundColor: InternloomColors.greenLight,
              side: const BorderSide(color: InternloomColors.border),
              avatar: const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: InternloomColors.greenDark,
              ),
              label: Text(
                filters.location,
                style: const TextStyle(color: InternloomColors.ink),
              ),
            ),
          if (filters.ctc.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Chip(
                backgroundColor: InternloomColors.tealLight,
                side: const BorderSide(color: InternloomColors.border),
                avatar: const Icon(
                  Icons.payments_outlined,
                  size: 16,
                  color: InternloomColors.tealDark,
                ),
                label: Text(
                  filters.ctc,
                  style: const TextStyle(color: InternloomColors.ink),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SwipeHint extends StatelessWidget {
  const _SwipeHint();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Hint(icon: Icons.close, label: 'Left: dismiss'),
          _Hint(icon: Icons.bookmark, label: 'Up: save'),
          _Hint(icon: Icons.check, label: 'Right: apply'),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: InternloomColors.bookTeal),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: InternloomColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllCaughtUp extends StatelessWidget {
  const _AllCaughtUp({
    required this.hasFilters,
    required this.onClearFilters,
    required this.onOpenSaved,
  });

  final bool hasFilters;
  final VoidCallback onClearFilters;
  final VoidCallback onOpenSaved;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 72,
              color: InternloomColors.leafGreen,
            ),
            const SizedBox(height: 20),
            const Text(
              "You're all caught up!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: InternloomColors.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "You've seen all the opportunities available to you right now. "
              "We'll notify you when a new posting is available.",
              textAlign: TextAlign.center,
              style: TextStyle(color: InternloomColors.body),
            ),
            const SizedBox(height: 20),
            if (hasFilters)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: InternloomColors.leafGreen,
                  side: const BorderSide(color: InternloomColors.leafGreen),
                ),
                onPressed: onClearFilters,
                child: const Text('Clear filters'),
              ),
            const SizedBox(height: 4),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: InternloomColors.bookTeal,
              ),
              onPressed: onOpenSaved,
              icon: const Icon(Icons.bookmark_outline),
              label: const Text('View saved jobs'),
            ),
          ],
        ),
      ),
    );
  }
}
