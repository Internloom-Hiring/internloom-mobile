import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/job_discovery_filters.dart';
import '../../data/models/placement_drive.dart';
import '../../data/models/swipe_action.dart';
import '../../provider/job_discovery_provider.dart';
import '../widgets/job_discovery_filter_sheet.dart';
import '../widgets/swipe_deck.dart';
import '../../../core/navigation/route_names.dart';

class JobDiscoveryScreen extends StatefulWidget {
  const JobDiscoveryScreen({super.key});

  @override
  State<JobDiscoveryScreen> createState() => _JobDiscoveryScreenState();
}

class _JobDiscoveryScreenState extends State<JobDiscoveryScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => JobDiscoveryProvider()..loadInitial(),
      child: const _JobDiscoveryView(),
    );
  }
}



Future<void> _openSavedJobs(
  BuildContext context,
  JobDiscoveryProvider provider,
) async {
  await context.pushNamed(RouteNames.studentSavedJobs);

  if (!context.mounted) return;

  await provider.loadInitial();
}



class _JobDiscoveryView extends StatelessWidget {
  const _JobDiscoveryView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobDiscoveryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Jobs'),
        actions: [
          IconButton(
            tooltip: 'Filters',
            onPressed: () => _showFilters(context, provider),
            icon: Badge(
              isLabelVisible: provider.hasActiveFilters,
              smallSize: 8,
              child: const Icon(Icons.filter_list),
            ),
          ),
          IconButton(
            tooltip: 'Saved jobs',
            onPressed: () => _openSavedJobs(context, provider),
            icon: const Icon(Icons.bookmark_border),
          ),
        ],
      ),
      body: _buildBody(context, provider),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
          onDestinationSelected: (index) {
            if (index == 1) {
              context.goNamed(RouteNames.studentSavedJobs);
            } else if (index == 2) {
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
              const Icon(Icons.cloud_off, size: 44),
              const SizedBox(height: 12),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
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
        onOpenSaved: () =>
            context.pushNamed(RouteNames.studentSavedJobs),
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
          if (provider.canUndo)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: TextButton.icon(
                onPressed: () => _undo(context, provider),
                icon: const Icon(Icons.undo),
                label: const Text('Undo last swipe'),
              ),
            )
          else
            const SizedBox(height: 40),
          if (provider.isLoading)
            const LinearProgressIndicator(minHeight: 2)
          else
            const SizedBox(height: 2),
        ],
      ),
    );
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

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(label),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () => _undo(context, provider),
          ),
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
              avatar: const Icon(Icons.location_on_outlined, size: 16),
              label: Text(filters.location),
            ),
          if (filters.ctc.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Chip(
                avatar: const Icon(Icons.payments_outlined, size: 16),
                label: Text(filters.ctc),
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
  const _Hint({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
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
            const Icon(Icons.check_circle_outline, size: 72),
            const SizedBox(height: 20),
            const Text(
              "You're all caught up!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "You've seen all the opportunities available to you right now. "
              "We'll notify you when a new posting is available.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (hasFilters)
              OutlinedButton(
                onPressed: onClearFilters,
                child: const Text('Clear filters'),
              ),
            const SizedBox(height: 4),
            TextButton.icon(
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
