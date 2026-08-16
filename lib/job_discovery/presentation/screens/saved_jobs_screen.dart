import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/route_names.dart';
import '../../data/models/placement_drive.dart';
import '../../provider/saved_jobs_provider.dart';
import '../widgets/job_discovery_card.dart';

class SavedJobsScreen extends StatelessWidget {
  const SavedJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SavedJobsProvider()..load(),
      child: const _SavedJobsView(),
    );
  }
}

class _SavedJobsView extends StatelessWidget {
  const _SavedJobsView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SavedJobsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Jobs'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: provider.load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(context, provider),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SavedJobsProvider provider,
  ) {
    if (provider.loadState == SavedJobsLoadState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.loadState == SavedJobsLoadState.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 44),
              const SizedBox(height: 12),
              Text(
                provider.errorMessage ?? 'Could not load saved jobs.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: provider.load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.jobs.isEmpty) {
      return RefreshIndicator(
        onRefresh: provider.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 160),
            Icon(Icons.bookmark_border, size: 64),
            SizedBox(height: 16),
            Text(
              'No saved jobs',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Swipe up on a job in Discover to save it for later.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: provider.jobs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final drive = provider.jobs[index];

          return _SavedJobTile(
            drive: drive,
            onOpen: () => context.pushNamed(
              RouteNames.studentJobDetails,
              pathParameters: {'driveId': drive.id},
              extra: drive,
            ),
            onUnsave: () => _unsave(context, provider, drive),
            onApply: () => _apply(context, provider, drive),
          );
        },
      ),
    );
  }

  Future<void> _unsave(
    BuildContext context,
    SavedJobsProvider provider,
    PlacementDrive drive,
  ) async {
    final success = await provider.unsave(drive);
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from saved jobs.')),
      );
    }
  }

  Future<void> _apply(
    BuildContext context,
    SavedJobsProvider provider,
    PlacementDrive drive,
  ) async {
    final success = await provider.apply(drive);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Application submitted.'
              : 'Could not submit the application.',
        ),
      ),
    );
  }
}

class _SavedJobTile extends StatelessWidget {
  const _SavedJobTile({
    required this.drive,
    required this.onOpen,
    required this.onUnsave,
    required this.onApply,
  });

  final PlacementDrive drive;
  final VoidCallback onOpen;
  final VoidCallback onUnsave;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        JobDiscoveryCard(
          drive: drive,
          onTap: onOpen,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onUnsave,
                icon: const Icon(Icons.bookmark_remove_outlined),
                label: const Text('Unsave'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: onApply,
                icon: const Icon(Icons.check),
                label: const Text('Apply'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
