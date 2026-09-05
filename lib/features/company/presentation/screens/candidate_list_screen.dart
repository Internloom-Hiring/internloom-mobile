import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/route_names.dart';
import '../../../../core/constants/app_colors.dart';

class CandidateListScreen extends StatefulWidget {
  final String driveId;

  const CandidateListScreen({
    super.key,
    required this.driveId,
  });

  @override
  State<CandidateListScreen> createState() => _CandidateListScreenState();
}

class _CandidateListScreenState extends State<CandidateListScreen> {
  final _cgpaController = TextEditingController();
  final _collegeController = TextEditingController();
  final _skillsController = TextEditingController();

  List<Map<String, dynamic>> _candidates = [];
  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _driveDetails;

  @override
  void initState() {
    super.initState();
    _fetchDriveDetails();
    _fetchCandidates();
  }

  Future<void> _fetchDriveDetails() async {
    try {
      final res = await Supabase.instance.client
          .from('placement_drives')
          .select('*')
          .eq('id', widget.driveId)
          .maybeSingle();
      if (mounted && res != null) {
        setState(() {
          _driveDetails = res;
        });
      }
    } catch (e) {
      debugPrint('Error fetching drive details: $e');
    }
  }

  @override
  void dispose() {
    _cgpaController.dispose();
    _collegeController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _fetchCandidates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final double? minCgpa = double.tryParse(_cgpaController.text.trim());
      final String? college =
          _collegeController.text.trim().isNotEmpty ? _collegeController.text.trim() : null;

      final String skillsText = _skillsController.text.trim();
      final List<String>? skills = skillsText.isNotEmpty
          ? skillsText
              .split(',')
              .map((e) => e.trim())
              .where((s) => s.isNotEmpty)
              .toList()
          : null;

      final params = <String, dynamic>{'p_drive_id': widget.driveId};
      if (minCgpa != null) params['p_min_cgpa'] = minCgpa;
      if (college != null) params['p_college'] = college;
      if (skills != null && skills.isNotEmpty) params['p_skills'] = skills;

      // Note: Live testing may show empty state if RLS on students table blocks SELECT
      final response = await Supabase.instance.client.rpc(
        'get_ranked_candidates',
        params: params,
      );

      if (mounted) {
        setState(() {
          _candidates = List<Map<String, dynamic>>.from(response as List);
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

  void _clearFilters() {
    _cgpaController.clear();
    _collegeController.clear();
    _skillsController.clear();
    _fetchCandidates();
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = _cgpaController.text.isNotEmpty ||
        _collegeController.text.isNotEmpty ||
        _skillsController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Candidates', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Pipeline Funnel',
            onPressed: () {
              context.pushNamed(
                RouteNames.companyPipelineFunnel,
                queryParameters: {'driveId': widget.driveId},
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
          if (_driveDetails != null)
            Container(
              color: AppColors.white,
              child: ExpansionTile(
                title: Text(
                  _driveDetails!['job_title'] ?? 'Job Details',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  [
                    if (_driveDetails!['ctc'] != null) _driveDetails!['ctc'],
                    if (_driveDetails!['location'] != null) _driveDetails!['location'],
                  ].join(' • '),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDetailRow('Location', _driveDetails!['location']),
                        const SizedBox(height: 8),
                        _buildDetailRow('CTC', _driveDetails!['ctc']),
                        const SizedBox(height: 8),
                        _buildDetailRow('Description', _driveDetails!['job_description']),
                        const SizedBox(height: 8),
                        _buildDetailRow('Eligibility Criteria', _driveDetails!['eligibility_criteria']),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          _buildFilterSection(hasActiveFilters),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Text(
                            'Error: $_error',
                            style: const TextStyle(color: AppColors.error),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : _candidates.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.people_outline,
                                    size: 48,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  const Text(
                                    'No candidates match your criteria.',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (hasActiveFilters) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    TextButton(
                                      onPressed: _clearFilters,
                                      child: const Text('Clear Filters'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            itemCount: _candidates.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final candidate = _candidates[index];
                              final finalScore = candidate['final_score']?.toString() ?? 'N/A';
                              final name = candidate['name'] ?? 'Hidden by RLS';
                              final studentCollege =
                                  candidate['college_name'] ?? 'Unknown College';
                              final cgpa = candidate['cgpa']?.toString() ?? 'N/A';

                              return Card(
                                color: AppColors.cardBackground,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                                  side: const BorderSide(color: AppColors.border),
                                ),
                                elevation: 0,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                                  onTap: () {
                                    final appId =
                                        candidate['application_id']?.toString() ?? '';
                                    final stdId =
                                        candidate['student_id']?.toString() ?? '';
                                    if (appId.isNotEmpty && stdId.isNotEmpty) {
                                      context.pushNamed(
                                        RouteNames.companyCandidateDetail,
                                        pathParameters: {'id': appId},
                                        queryParameters: {'studentId': stdId},
                                      );
                                    }
                                  },
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
                                                name,
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: AppSpacing.xs),
                                              Text(
                                                studentCollege,
                                                style: const TextStyle(
                                                    color: AppColors.textSecondary),
                                              ),
                                              const SizedBox(height: AppSpacing.xs),
                                              Text(
                                                'CGPA: $cgpa',
                                                style: const TextStyle(
                                                    color: AppColors.textSecondary),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.sm,
                                            vertical: AppSpacing.xs,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.greenLight,
                                            borderRadius:
                                                BorderRadius.circular(AppSpacing.sm),
                                          ),
                                          child: Text(
                                            'Match: $finalScore',
                                            style: const TextStyle(
                                              color: AppColors.primaryDark,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildFilterSection(bool hasActiveFilters) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Candidates',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (hasActiveFilters)
                InkWell(
                  onTap: _clearFilters,
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cgpaController,
                  decoration: const InputDecoration(
                    labelText: 'Min CGPA',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _collegeController,
                  decoration: const InputDecoration(
                    labelText: 'College Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Skills filter field (wired to p_skills)
          TextField(
            controller: _skillsController,
            decoration: const InputDecoration(
              labelText: 'Required Skills (comma separated)',
              hintText: 'e.g. Flutter, React, Python',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton(
            onPressed: _fetchCandidates,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
            ),
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    final displayValue = value?.toString() ?? 'N/A';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ),
        Expanded(
          child: Text(
            displayValue,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
