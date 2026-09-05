import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/route_names.dart';
import '../../../../core/constants/app_colors.dart';
import 'edit_drive_screen.dart';

class MyDrivesScreen extends StatefulWidget {
  const MyDrivesScreen({super.key});

  @override
  State<MyDrivesScreen> createState() => _MyDrivesScreenState();
}

class _MyDrivesScreenState extends State<MyDrivesScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _drives = [];

  @override
  void initState() {
    super.initState();
    _fetchDrives();
  }

  Future<void> _fetchDrives() async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final data = await client
          .from('placement_drives')
          .select()
          .eq('company_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _drives = List<Map<String, dynamic>>.from(data);
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

  void _onDriveTapped(Map<String, dynamic> drive) {
    if (drive['id'] != null) {
      context.pushNamed(
        RouteNames.companyCandidateList,
        queryParameters: {'driveId': drive['id']},
      ).then((_) => _fetchDrives());
    }
  }

  void _onEditDrive(Map<String, dynamic> drive) async {
    // Note: Since no companyEditDrive route is registered in route_names.dart,
    // we use direct MaterialPageRoute as a temporary measure pending Dev 1 route assignment.
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditDriveScreen(drive: drive),
      ),
    );

    if (updated == true && mounted) {
      _fetchDrives();
    }
  }

  Future<void> _onCloseDrive(Map<String, dynamic> drive) async {
    final driveId = drive['id'];
    if (driveId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Drive?'),
        content: const Text(
          'Are you sure you want to close this placement drive? Students will no longer be able to apply.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Close Drive'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final client = Supabase.instance.client;
      await client
          .from('placement_drives')
          .update({'status': 'closed'})
          .eq('id', driveId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Drive closed successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        _fetchDrives();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to close drive: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Drives',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Post New Drive',
            onPressed: () {
              context.pushNamed(RouteNames.companyPostDrive).then((_) => _fetchDrives());
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Error: $_error',
                          style: const TextStyle(color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton.icon(
                          onPressed: _fetchDrives,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _drives.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.work_off_outlined,
                              size: 56,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const Text(
                              'No placement drives posted yet.',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            const Text(
                              'Create a new drive to start recruiting talented students.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            ElevatedButton.icon(
                              onPressed: () {
                                context
                                    .pushNamed(RouteNames.companyPostDrive)
                                    .then((_) => _fetchDrives());
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Post a Drive'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _fetchDrives,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: _drives.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final drive = _drives[index];
                          final status = (drive['status'] as String? ?? 'pending').toLowerCase();
                          final ctc = drive['ctc'] as String? ?? '';
                          final location = drive['location'] as String? ?? '';
                          final title = drive['job_title'] as String? ?? 'Untitled Drive';

                          final Color statusColor = status == 'approved'
                              ? AppColors.success
                              : status == 'rejected'
                                  ? AppColors.danger
                                  : status == 'closed'
                                      ? AppColors.textSecondary
                                      : AppColors.warning;

                          return Card(
                            color: AppColors.cardBackground,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.sm),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            elevation: 0,
                            child: InkWell(
                              onTap: () => _onDriveTapped(drive),
                              borderRadius: BorderRadius.circular(AppSpacing.sm),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row 1: Title and Status Badge
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            status.toUpperCase(),
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.xs),

                                    // Row 2: CTC & Location (matching website's drive card)
                                    if (ctc.isNotEmpty || location.isNotEmpty) ...[
                                      Row(
                                        children: [
                                          if (ctc.isNotEmpty) ...[
                                            const Icon(
                                              Icons.payments_outlined,
                                              size: 14,
                                              color: AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              ctc,
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                          if (ctc.isNotEmpty && location.isNotEmpty) ...[
                                            const SizedBox(width: AppSpacing.sm),
                                            const Text(
                                              '•',
                                              style: TextStyle(color: AppColors.textSecondary),
                                            ),
                                            const SizedBox(width: AppSpacing.sm),
                                          ],
                                          if (location.isNotEmpty) ...[
                                            const Icon(
                                              Icons.location_on_outlined,
                                              size: 14,
                                              color: AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                location,
                                                style: const TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontSize: 13,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                    ],

                                    const Divider(height: 1, color: AppColors.border),
                                    const SizedBox(height: AppSpacing.xs),

                                    // Row 3: Action Buttons (Edit for all statuses, Close for approved, View Candidates)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        // Edit Action Button (pencil icon)
                                        TextButton.icon(
                                          onPressed: () => _onEditDrive(drive),
                                          icon: const Icon(Icons.edit_outlined, size: 16),
                                          label: const Text('Edit'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppColors.primary,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.sm,
                                              vertical: AppSpacing.xs,
                                            ),
                                          ),
                                        ),

                                        // Close Drive Action Button (only if status == 'approved')
                                        if (status == 'approved') ...[
                                          const SizedBox(width: AppSpacing.xs),
                                          TextButton.icon(
                                            onPressed: () => _onCloseDrive(drive),
                                            icon: const Icon(Icons.close, size: 16),
                                            label: const Text('Close Drive'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: AppColors.danger,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: AppSpacing.sm,
                                                vertical: AppSpacing.xs,
                                              ),
                                            ),
                                          ),
                                        ],

                                        // Note: Delete button is omitted because Phase 1 confirmed
                                        // no DELETE RLS policy exists on placement_drives.
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ),
    );
  }
}
