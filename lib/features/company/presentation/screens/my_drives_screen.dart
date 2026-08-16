import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';

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
    // Navigate to Candidate List screen
    // TODO: wire navigation when route is added to route_names.dart
  }

  Future<void> _onCloseDrive(Map<String, dynamic> drive) async {
    final driveId = drive['id'];
    if (driveId == null) return;

    // Optimistic UI update or show loading state could be added here
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
        // Refresh the list to reflect the change
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
        title: const Text('My Drives', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: AppColors.error)))
              : _drives.isEmpty
                  ? const Center(
                      child: Text('No drives posted yet.', style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: _drives.length,
                      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final drive = _drives[index];
                        final status = drive['status'] as String? ?? 'pending';

                        return Card(
                          color: AppColors.cardBackground,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.sm)),
                          child: InkWell(
                            onTap: () => _onDriveTapped(drive),
                            borderRadius: BorderRadius.circular(AppSpacing.sm),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          drive['title'] ?? 'Untitled Drive',
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          'Status: ${status.toUpperCase()}',
                                          style: TextStyle(
                                            color: status == 'approved'
                                                ? AppColors.success
                                                : status == 'rejected'
                                                    ? AppColors.danger
                                                    : AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (status == 'approved')
                                    TextButton.icon(
                                      onPressed: () => _onCloseDrive(drive),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.danger,
                                      ),
                                      icon: const Icon(Icons.close),
                                      label: const Text('Close Drive'),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
