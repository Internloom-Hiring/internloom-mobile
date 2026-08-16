import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../profile/data/models/student_profile.dart';

class CandidateDetailScreen extends StatefulWidget {
  final String applicationId;
  final String studentId;

  const CandidateDetailScreen({
    super.key,
    required this.applicationId,
    required this.studentId,
  });

  @override
  State<CandidateDetailScreen> createState() => _CandidateDetailScreenState();
}

class _CandidateDetailScreenState extends State<CandidateDetailScreen> {
  StudentProfile? _profile;
  bool _isLoading = true;
  String? _error;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final client = Supabase.instance.client;
      final data = await client
          .from('students')
          .select()
          .eq('id', widget.studentId)
          .single();

      if (mounted) {
        setState(() {
          _profile = StudentProfile.fromMap(data);
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

  Future<void> _updateApplicationStatus(String status) async {
    setState(() => _isUpdating = true);
    try {
      final client = Supabase.instance.client;
      // Writes go through the existing applications_update_owning_company_or_admin RLS exactly as-is
      await client
          .from('applications')
          .update({'status': status})
          .eq('id', widget.applicationId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application $status successfully.'),
            backgroundColor: status == 'selected' ? AppColors.success : AppColors.error,
          ),
        );
        Navigator.pop(context); // Optional: go back after taking action
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _viewResume() async {
    final resumePath = _profile?.resumePath;
    if (resumePath == null || resumePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No resume available for this candidate.')),
      );
      return;
    }

    try {
      final client = Supabase.instance.client;
      final signedUrl = await client.storage.from('profile-uploads').createSignedUrl(resumePath, 3600);
      
      final uri = Uri.parse(signedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch resume URL.';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load resume: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Candidate Profile', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: AppColors.error)))
              : _profile == null
                  ? const Center(child: Text('Profile not found'))
                  : _buildProfileContent(),
      bottomNavigationBar: (_profile != null && !_isLoading) ? _buildActionButtons() : null,
    );
  }

  Widget _buildProfileContent() {
    final p = _profile!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Card(
            color: AppColors.cardBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.sm)),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Text(
                    p.fullName.isNotEmpty ? p.fullName : 'No Name',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    p.displayHeadline.isNotEmpty ? p.displayHeadline : 'No Headline',
                    style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Resume Section
          Card(
            color: AppColors.cardBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.sm)),
            child: ListTile(
              title: const Text('Resume', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(p.resumePath != null && p.resumePath!.isNotEmpty ? 'PDF Available' : 'Not uploaded'),
              trailing: ElevatedButton.icon(
                onPressed: (p.resumePath != null && p.resumePath!.isNotEmpty) ? _viewResume : null,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('View'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // About Me
          if (p.aboutMe.isNotEmpty) ...[
            _buildSectionTitle('About'),
            Text(p.aboutMe, style: const TextStyle(color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.md),
          ],

          // Skills
          if (p.skills.isNotEmpty) ...[
            _buildSectionTitle('Skills'),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: p.skills.map((s) => Chip(label: Text(s))).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Education Details
          _buildSectionTitle('Education'),
          _buildInfoRow('Course', p.course),
          _buildInfoRow('Branch', p.branch),
          _buildInfoRow('Graduation Year', p.graduationYear?.toString() ?? 'N/A'),
          _buildInfoRow('CGPA', p.cgpa?.toString() ?? 'N/A'),
          _buildInfoRow('College', '${p.collegeName} (${p.collegeCity}, ${p.collegeState})'),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500))),
          Expanded(flex: 3, child: Text(value.isNotEmpty ? value : 'N/A', style: const TextStyle(color: AppColors.textPrimary))),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isUpdating ? null : () => _updateApplicationStatus('rejected'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: const Text('Pass'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton(
                onPressed: _isUpdating ? null : () => _updateApplicationStatus('selected'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: const Text('Select'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
