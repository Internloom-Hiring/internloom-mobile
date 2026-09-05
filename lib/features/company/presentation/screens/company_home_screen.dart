import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/route_names.dart';
import '../../../../core/constants/app_colors.dart';

class CompanyHomeScreen extends StatefulWidget {
  const CompanyHomeScreen({super.key});

  @override
  State<CompanyHomeScreen> createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends State<CompanyHomeScreen> {
  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _companyData;
  int _totalDrivesCount = 0;
  int _activeDrivesCount = 0;
  int _totalApplicationsCount = 0;
  List<Map<String, dynamic>> _recentDrives = [];
  Map<String, int> _driveAppCounts = {};

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // 1. Fetch Company Info
      final companyRes = await client
          .from('companies')
          .select('*')
          .eq('profile_id', userId)
          .maybeSingle();

      // 2. Fetch Drives Info (all drives for this company)
      final allDrivesData = await client
          .from('placement_drives')
          .select('id, job_title, status, ctc, location, created_at')
          .eq('company_id', userId)
          .order('created_at', ascending: false);

      final drivesList = List<Map<String, dynamic>>.from(allDrivesData);
      final totalDrives = drivesList.length;
      final activeDrives = drivesList.where((d) => d['status'] == 'approved').length;
      final recentDrives = drivesList.take(3).toList();

      // 3. Fetch Applications count across all company drives
      final allDriveIds = drivesList.map((d) => d['id'] as String).toList();
      int totalApps = 0;
      final Map<String, int> appCountsMap = {};

      if (allDriveIds.isNotEmpty) {
        final appsData = await client
            .from('applications')
            .select('id, drive_id')
            .inFilter('drive_id', allDriveIds);

        final appsList = List<Map<String, dynamic>>.from(appsData);
        totalApps = appsList.length;

        for (final app in appsList) {
          final dId = app['drive_id'] as String?;
          if (dId != null) {
            appCountsMap[dId] = (appCountsMap[dId] ?? 0) + 1;
          }
        }
      }

      if (mounted) {
        setState(() {
          _companyData = companyRes;
          _totalDrivesCount = totalDrives;
          _activeDrivesCount = activeDrives;
          _recentDrives = recentDrives;
          _totalApplicationsCount = totalApps;
          _driveAppCounts = appCountsMap;
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

  @override
  Widget build(BuildContext context) {
    final companyName = _companyData?['company_name'] as String? ?? 'Company';
    final approvalStatus = _companyData?['approval_status'] as String? ?? 'approved';
    final email = Supabase.instance.client.auth.currentUser?.email ?? 'N/A';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/images/internloom_logo.svg',
              width: 28,
              height: 28,
            ),
            const SizedBox(width: 10),
            const Text(
              'Company Dashboard',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: AppColors.textPrimary),
            tooltip: 'Company Profile',
            onPressed: () {
              context.pushNamed(RouteNames.companyProfile).then((_) {
                _fetchDashboardData();
              });
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
                              'Error loading dashboard:\n$_error',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.error),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            ElevatedButton.icon(
                              onPressed: _fetchDashboardData,
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
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _fetchDashboardData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Welcome Banner
                            _buildWelcomeBanner(companyName),
                            const SizedBox(height: AppSpacing.md),

                            // Stat Section at Top (Three compact cards)
                            _buildStatSection(approvalStatus),
                            const SizedBox(height: AppSpacing.lg),

                            // Quick Actions Section
                            _buildQuickActionsSection(),
                            const SizedBox(height: AppSpacing.lg),

                            // Company Info Section
                            _buildCompanyInfoSection(email),
                            const SizedBox(height: AppSpacing.lg),

                            // Recent Drives Section
                            _buildRecentDrivesSection(),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(String companyName) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: const Icon(Icons.business, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                Text(
                  companyName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (_activeDrivesCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Text(
                '$_activeDrivesCount Active',
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatSection(String approvalStatus) {
    final statusLower = approvalStatus.toLowerCase();
    final bool isApproved = statusLower == 'approved';
    final bool isPending = statusLower == 'pending';

    final Color statusBg = isApproved
        ? AppColors.greenLight
        : isPending
            ? const Color(0xFFFEF3C7) // Amber light
            : const Color(0xFFFEE2E2); // Red light

    final Color statusTextColor = isApproved
        ? AppColors.success
        : isPending
            ? AppColors.warning
            : AppColors.danger;

    final String statusDisplay = isApproved
        ? 'Approved'
        : isPending
            ? 'Pending'
            : approvalStatus.toUpperCase();

    return Row(
      children: [
        // 1. Drives Created
        Expanded(
          child: _buildStatCard(
            title: 'Drives Created',
            value: '$_totalDrivesCount',
            icon: Icons.work_outline,
            iconColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),

        // 2. Total Applications
        Expanded(
          child: _buildStatCard(
            title: 'Applications',
            value: '$_totalApplicationsCount',
            icon: Icons.people_outline,
            iconColor: AppColors.bookTeal,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),

        // 3. Account Status Badge Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Account Status',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Text(
                    statusDisplay,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: statusTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.all(AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
            ),
            onPressed: () {
              context.pushNamed(RouteNames.companyPostDrive).then((_) {
                _fetchDashboardData();
              });
            },
            icon: const Icon(Icons.add_circle_outline),
            label: const Text(
              'Post a Drive',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                    ),
                  ),
                  onPressed: () {
                    context.pushNamed(RouteNames.companyMyDrives).then((_) {
                      _fetchDashboardData();
                    });
                  },
                  icon: const Icon(Icons.list_alt),
                  label: const Text('My Drives'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                    ),
                  ),
                  onPressed: () {
                    context.pushNamed(RouteNames.companyProfile).then((_) {
                      _fetchDashboardData();
                    });
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Profile'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyInfoSection(String email) {
    final hrName = _companyData?['hr_name'] as String? ?? 'Not specified';
    final hrContact = _companyData?['hr_contact'] as String? ?? 'Not specified';
    final website = _companyData?['website'] as String? ?? 'Not specified';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Company Info',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              InkWell(
                onTap: () {
                  context.pushNamed(RouteNames.companyProfile).then((_) {
                    _fetchDashboardData();
                  });
                },
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow(Icons.person_outline, 'HR Name', hrName),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(Icons.phone_outlined, 'HR Contact', hrContact),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(Icons.email_outlined, 'Email', email),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(Icons.language_outlined, 'Website', website),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentDrivesSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Drives',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_totalDrivesCount > 0)
                TextButton(
                  onPressed: () {
                    context.pushNamed(RouteNames.companyMyDrives).then((_) {
                      _fetchDashboardData();
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('View All'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_recentDrives.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: Text(
                  'No drives posted yet.\nTap "Post a Drive" to get started.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentDrives.length,
              separatorBuilder: (context, index) => const Divider(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final drive = _recentDrives[index];
                final driveId = drive['id'] as String? ?? '';
                final title = drive['job_title'] as String? ?? 'Untitled Drive';
                final status = (drive['status'] as String? ?? 'pending').toLowerCase();
                final appCount = _driveAppCounts[driveId] ?? 0;
                final ctc = drive['ctc'] as String? ?? '';
                final location = drive['location'] as String? ?? '';

                final Color statusColor = status == 'approved'
                    ? AppColors.success
                    : status == 'rejected'
                        ? AppColors.danger
                        : status == 'closed'
                            ? AppColors.textSecondary
                            : AppColors.warning;

                return InkWell(
                  onTap: () {
                    if (driveId.isNotEmpty) {
                      context.pushNamed(
                        RouteNames.companyCandidateList,
                        queryParameters: {'driveId': driveId},
                      ).then((_) {
                        _fetchDashboardData();
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (ctc.isNotEmpty || location.isNotEmpty)
                                Text(
                                  [if (ctc.isNotEmpty) ctc, if (location.isNotEmpty) location]
                                      .join(' • '),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    '$appCount ${appCount == 1 ? 'applicant' : 'applicants'}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
