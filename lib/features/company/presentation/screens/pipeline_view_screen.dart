import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';

class PipelineViewScreen extends StatefulWidget {
  final String driveId;

  const PipelineViewScreen({super.key, required this.driveId});

  @override
  State<PipelineViewScreen> createState() => _PipelineViewScreenState();
}

class _PipelineViewScreenState extends State<PipelineViewScreen> {
  final Map<String, int> _counts = {
    'applied': 0,
    'shortlisted': 0,
    'selected': 0,
    'rejected': 0,
    'withdrawn': 0,
  };
  
  RealtimeChannel? _channel;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchInitialCounts();
    _subscribeToRealtime();
  }

  @override
  void dispose() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
    }
    super.dispose();
  }

  Future<void> _fetchInitialCounts() async {
    try {
      final client = Supabase.instance.client;
      // Fetch all status rows for this drive and group them locally
      final data = await client
          .from('applications')
          .select('status')
          .eq('drive_id', widget.driveId);

      final Map<String, int> newCounts = {
        'applied': 0,
        'shortlisted': 0,
        'selected': 0,
        'rejected': 0,
        'withdrawn': 0,
      };

      for (var row in data) {
        final status = row['status'] as String;
        if (newCounts.containsKey(status)) {
          newCounts[status] = newCounts[status]! + 1;
        }
      }

      if (mounted) {
        setState(() {
          _counts.addAll(newCounts);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _subscribeToRealtime() {
    final client = Supabase.instance.client;
    // Subscribe to changes on the applications table for this specific drive
    _channel = client
        .channel('public:applications:drive_${widget.driveId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'applications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'drive_id',
            value: widget.driveId,
          ),
          callback: (payload) {
            if (!mounted) return;
            
            final oldRecord = payload.oldRecord;
            final newRecord = payload.newRecord;
            final eventType = payload.eventType;

            setState(() {
              if (eventType == PostgresChangeEvent.insert) {
                final status = newRecord['status'] as String?;
                if (status != null && _counts.containsKey(status)) {
                  _counts[status] = _counts[status]! + 1;
                }
              } else if (eventType == PostgresChangeEvent.update) {
                final oldStatus = oldRecord['status'] as String?;
                final newStatus = newRecord['status'] as String?;
                
                if (oldStatus != null && _counts.containsKey(oldStatus)) {
                  _counts[oldStatus] = (_counts[oldStatus]! - 1).clamp(0, 999999);
                }
                if (newStatus != null && _counts.containsKey(newStatus)) {
                  _counts[newStatus] = _counts[newStatus]! + 1;
                }
              } else if (eventType == PostgresChangeEvent.delete) {
                final oldStatus = oldRecord['status'] as String?;
                if (oldStatus != null && _counts.containsKey(oldStatus)) {
                  _counts[oldStatus] = (_counts[oldStatus]! - 1).clamp(0, 999999);
                }
              }
            });
          },
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pipeline Funnel', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: AppColors.error)))
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    _buildPipelineCard('Applied', _counts['applied'] ?? 0, Icons.assignment),
                    _buildPipelineCard('Shortlisted', _counts['shortlisted'] ?? 0, Icons.star, color: AppColors.warning),
                    _buildPipelineCard('Selected', _counts['selected'] ?? 0, Icons.check_circle, color: AppColors.success),
                    _buildPipelineCard('Rejected', _counts['rejected'] ?? 0, Icons.cancel, color: AppColors.error),
                    _buildPipelineCard('Withdrawn', _counts['withdrawn'] ?? 0, Icons.exit_to_app, color: AppColors.textSecondary),
                  ],
                ),
    );
  }

  Widget _buildPipelineCard(String title, int count, IconData icon, {Color? color}) {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.sm)),
      child: ListTile(
        leading: Icon(icon, color: color ?? AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: (color ?? AppColors.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: color ?? AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
