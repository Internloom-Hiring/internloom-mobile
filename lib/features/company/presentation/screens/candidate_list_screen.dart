import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchCandidates();
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
      final String? college = _collegeController.text.trim().isNotEmpty ? _collegeController.text.trim() : null;
      
      final String skillsText = _skillsController.text.trim();
      final List<String>? skills = skillsText.isNotEmpty 
          ? skillsText.split(',').map((e) => e.trim()).toList() 
          : null;

      final params = <String, dynamic>{'p_drive_id': widget.driveId};
      if (minCgpa != null) params['p_min_cgpa'] = minCgpa;
      if (college != null) params['p_college'] = college;
      if (skills != null) params['p_skills'] = skills;

      // Note: Live testing may show this empty state unexpectedly until the
      // schema owner fixes the missing SELECT RLS policy on the `students` table.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Candidate List', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(child: Text('Error: $_error', style: const TextStyle(color: AppColors.error)))
                    : _candidates.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.lg),
                              // Note: Live testing may show this empty state unexpectedly until the
                              // schema owner fixes the missing SELECT RLS policy on the `students` table.
                              child: Text(
                                'No candidates match your filters.',
                                style: TextStyle(color: AppColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            itemCount: _candidates.length,
                            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final candidate = _candidates[index];
                              final finalScore = candidate['final_score']?.toString() ?? 'N/A';
                              // Since student SELECT policy is missing, these fields might be null during live test
                              final name = candidate['name'] ?? 'Hidden by RLS';
                              final studentCollege = candidate['college_name'] ?? 'Unknown College';
                              final cgpa = candidate['cgpa']?.toString() ?? 'N/A';

                              return Card(
                                color: AppColors.cardBackground,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.sm)),
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
                                              style: const TextStyle(color: AppColors.textSecondary),
                                            ),
                                            const SizedBox(height: AppSpacing.xs),
                                            Text(
                                              'CGPA: $cgpa',
                                              style: const TextStyle(color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                                        decoration: BoxDecoration(
                                          color: AppColors.greenLight,
                                          borderRadius: BorderRadius.circular(AppSpacing.sm),
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
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Filters', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _skillsController,
                  decoration: const InputDecoration(
                    labelText: 'Skills (comma separated)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ElevatedButton(
                onPressed: _fetchCandidates,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.all(AppSpacing.md),
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
