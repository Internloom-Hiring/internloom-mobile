import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_event.dart';
import '../../../../constants/theme.dart';
import '../../provider/profile_provider.dart';
import '../widgets/completion_meter.dart';
import '../widgets/section_card.dart';
import 'edit_about_screen.dart';
import 'edit_achievements_screen.dart';
import 'edit_certifications_screen.dart';
import 'edit_college_verification_screen.dart';
import 'edit_education_screen.dart';
import 'edit_headline_photo_screen.dart'; // EditBasicInfoScreen — see file for naming note
import 'edit_projects_screen.dart';
import 'edit_resume_screen.dart';
import 'edit_skills_screen.dart';
import 'edit_social_links_screen.dart'; // EditLinkedinScreen — see file for naming note

/// The profile screen, restructured to match the real `students`
/// table exactly. No cover banner / profile photo section (no columns
/// for them) and no Experience section (no column) — see
/// README_STUDENT_SIDE.md for the full list of adaptations made once
/// the actual schema was confirmed.
class ProfileViewScreen extends StatelessWidget {
  const ProfileViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        if (provider.loadState == ProfileLoadState.loading ||
            provider.loadState == ProfileLoadState.initial) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (provider.loadState == ProfileLoadState.error) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(provider.errorMessage ?? 'Something went wrong'),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: () => provider.load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final profile = provider.profile!;

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Profile'),
            actions: [
              IconButton(
                key: const Key('logoutButton'),
                icon: const Icon(Icons.logout),
                tooltip: 'Log Out',
                onPressed: () {
                  context.read<AuthBloc>().add(const LogoutSubmitted());
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _ProfileHeader(
                fullName: profile.fullName,
                headline: profile.displayHeadline,
                phone: profile.phone.isEmpty ? null : '${profile.countryCode} ${profile.phone}',
                onEdit: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const EditBasicInfoScreen())),
              ),
              const SizedBox(height: AppSpacing.md),
              CompletionMeter(percent: provider.completionPct, missingItems: provider.missingItems),
              const SizedBox(height: AppSpacing.md),
              SectionCard(
                title: 'About me',
                isEmpty: profile.aboutMe.trim().isEmpty,
                emptyLabel: 'Add a short bio so recruiters get a sense of you.',
                onEdit: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const EditAboutScreen())),
                child: Text(profile.aboutMe),
              ),
              SectionCard(
                title: 'Education',
                isEmpty: profile.collegeName.trim().isEmpty,
                emptyLabel: 'Required — add your education.',
                onEdit: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const EditEducationScreen())),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${profile.course}, ${profile.branch}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${profile.collegeName}, ${profile.collegeCity}, ${profile.collegeState}'),
                    Text('Graduating ${profile.graduationYear} · CGPA ${profile.cgpa}'),
                  ],
                ),
              ),
              SectionCard(
                title: 'College verification',
                isEmpty: profile.collegeEmail.trim().isEmpty,
                emptyLabel: 'Verify your college email or ID to build trust with companies.',
                onEdit: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EditCollegeVerificationScreen())),
                child: Row(
                  children: [
                    Icon(
                      profile.collegeVerified ? Icons.verified : Icons.hourglass_empty,
                      color: profile.collegeVerified ? AppColors.success : AppColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(profile.collegeVerified ? 'Verified' : 'Status: ${profile.verificationStatus}'),
                  ],
                ),
              ),
              SectionCard(
                title: 'Skills',
                isEmpty: profile.skills.isEmpty,
                emptyLabel: 'Required — add at least 3 skills.',
                onEdit: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const EditSkillsScreen())),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.skills.map((s) => Chip(label: Text(s))).toList(),
                ),
              ),
              SectionCard(
                title: 'Projects & portfolio links',
                isEmpty: profile.projects.isEmpty,
                emptyLabel: 'Optional — add a project to stand out.',
                onEdit: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const EditProjectsScreen())),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: profile.projects
                      .map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ))
                      .toList(),
                ),
              ),
              SectionCard(
                title: 'Certifications',
                isEmpty: profile.certifications.isEmpty,
                emptyLabel: 'Optional — add any certifications you’ve earned.',
                onEdit: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const EditCertificationsScreen())),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.certifications.map((c) => Chip(label: Text(c))).toList(),
                ),
              ),
              SectionCard(
                title: 'Achievements',
                isEmpty: profile.achievements.isEmpty,
                emptyLabel: 'Optional — add awards, competitions, or other wins.',
                onEdit: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const EditAchievementsScreen())),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.achievements.map((a) => Chip(label: Text(a))).toList(),
                ),
              ),
              SectionCard(
                title: 'Resume',
                isEmpty: profile.resumePath == null || profile.resumePath!.isEmpty,
                emptyLabel: 'Required — upload a PDF resume.',
                onEdit: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const EditResumeScreen())),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        profile.resumePath?.split('/').last ?? 'Resume.pdf',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SectionCard(
                title: 'LinkedIn',
                isEmpty: profile.linkedinUrl.trim().isEmpty,
                emptyLabel: 'Optional — add your LinkedIn profile link.',
                onEdit: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const EditLinkedinScreen())),
                child: Text(profile.linkedinUrl),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: OutlinedButton.icon(
                  key: const Key('logoutProfileButton'),
                  onPressed: () {
                    context.read<AuthBloc>().add(const LogoutSubmitted());
                  },
                  icon: const Icon(Icons.logout, color: AppColors.error),
                  label: const Text('Log Out', style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.fullName,
    required this.headline,
    required this.phone,
    required this.onEdit,
  });

  final String fullName;
  final String headline;
  final String? phone;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        color: AppColors.cardBackground,
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.meterTrack,
            child: Icon(Icons.person, size: 32, color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.isEmpty ? 'Add your name' : fullName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  headline.isEmpty ? 'Add your course & college' : headline,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                if (phone != null) ...[
                  const SizedBox(height: 2),
                  Text(phone!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ],
            ),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
        ],
      ),
    );
  }
}
