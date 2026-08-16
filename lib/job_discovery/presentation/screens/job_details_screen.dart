import 'package:flutter/material.dart';

import '../../data/models/placement_drive.dart';
import '../../data/models/swipe_action.dart';
import '../../data/supabase_job_discovery_repository.dart';
import '../widgets/internloom_brand.dart';

class JobDetailsScreen extends StatefulWidget {
  const JobDetailsScreen({
    super.key,
    required this.driveId,
    this.initialDrive,
  });

  final String driveId;
  final PlacementDrive? initialDrive;

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  final _repository = SupabaseJobDiscoveryRepository();

  PlacementDrive? _drive;
  bool _loading = true;
  bool _applying = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _drive = widget.initialDrive;
    _load();
  }

  Future<void> _load() async {
    if (_drive != null) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      return;
    }

    try {
      final drive = await _repository.fetchDriveById(widget.driveId);
      if (!mounted) return;

      setState(() {
        _drive = drive;
        _loading = false;
        _error = drive == null ? 'This job is no longer available.' : null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Could not load this job. Check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InternloomColors.pageBackground,
      appBar: AppBar(
        backgroundColor: InternloomColors.white,
        foregroundColor: InternloomColors.ink,
        elevation: 0,
        title: const Text(
          'Job Details',
          style: TextStyle(
            color: InternloomColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _drive == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error ?? 'This job is no longer available.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final drive = _drive!;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          drive.jobTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: InternloomColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        if ((drive.location ?? '').trim().isNotEmpty)
          _DetailRow(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: drive.location!,
          ),
        if ((drive.ctc ?? '').trim().isNotEmpty)
          _DetailRow(
            icon: Icons.payments_outlined,
            label: 'CTC',
            value: drive.ctc!,
          ),
        if (drive.applicationDeadline != null)
          _DetailRow(
            icon: Icons.event_outlined,
            label: 'Application deadline',
            value: _formatDate(drive.applicationDeadline!),
          ),
        const SizedBox(height: 24),
        _Section(
          title: 'Description',
          child: Text(
            drive.jobDescription.isEmpty
                ? 'No job description provided.'
                : drive.jobDescription,
          ),
        ),
        if ((drive.eligibilityCriteria ?? '').trim().isNotEmpty)
          _Section(
            title: 'Eligibility',
            child: Text(drive.eligibilityCriteria!),
          ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: InternloomColors.bookTeal,
                  side: const BorderSide(color: InternloomColors.bookTeal),
                ),
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: Text(_saving ? 'Saving...' : 'Save'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: InternloomColors.leafGreen,
                  foregroundColor: InternloomColors.white,
                ),
                onPressed: _applying ? null : _apply,
                icon: const Icon(Icons.check),
                label: Text(_applying ? 'Applying...' : 'Apply'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _save() async {
    final drive = _drive;
    if (drive == null) return;

    setState(() => _saving = true);

    try {
      await _repository.recordSwipe(drive.id, SwipeDirection.up);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved for later.')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save this job.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _apply() async {
    final drive = _drive;
    if (drive == null) return;

    setState(() => _applying = true);

    try {
      await _repository.applyToDrive(drive.id);
      // If the job was saved, applying removes it from Saved Jobs.
      await _repository.deleteSwipe(drive.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted.')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not submit the application.')),
      );
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: InternloomColors.bookTeal),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
