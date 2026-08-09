import '../data/models/student_profile.dart';

/// Computes the profile-completion percentage shown in the meter
/// (Section 2.2/2.3). Weighting mirrors the guided-setup minimum
/// (Education + 3 skills + Resume) landing around the doc's ~55%
/// reference point, with everything else additive.
class ProfileCompletion {
  ProfileCompletion._();

  static const int _basicInfo = 10; // full name + phone
  static const int _education = 20; // college name/state/city, course, branch, grad year, cgpa
  static const int _skills = 20;
  static const int _resume = 10;
  static const int _aboutMe = 10;
  static const int _projects = 10;
  static const int _certifications = 5;
  static const int _achievements = 5;
  static const int _linkedin = 5;
  static const int _collegeVerification = 5; // college_email submitted (verification itself is system-owned)
  // Sum = 100

  static int percentFor(StudentProfile p) {
    var total = 0;

    if (p.fullName.trim().isNotEmpty && p.phone.trim().isNotEmpty) total += _basicInfo;

    final educationDone = p.collegeName.trim().isNotEmpty &&
        p.course.trim().isNotEmpty &&
        p.branch.trim().isNotEmpty &&
        p.graduationYear != null &&
        p.cgpa != null;
    if (educationDone) total += _education;

    if (p.skills.length >= 3) {
      total += _skills;
    } else if (p.skills.isNotEmpty) {
      total += (_skills * p.skills.length / 3).round();
    }

    if (p.resumePath != null && p.resumePath!.isNotEmpty) total += _resume;

    if (p.aboutMe.trim().isNotEmpty) total += _aboutMe;

    if (p.projects.any((pr) => pr.isComplete)) total += _projects;

    if (p.certifications.isNotEmpty) total += _certifications;

    if (p.achievements.isNotEmpty) total += _achievements;

    if (p.linkedinUrl.trim().isNotEmpty) total += _linkedin;

    if (p.collegeEmail.trim().isNotEmpty) total += _collegeVerification;

    return total.clamp(0, 100);
  }

  /// Short, human-readable list of what's missing — shown right under
  /// the completion meter per Section 2.2.
  static List<String> missingItems(StudentProfile p) {
    final missing = <String>[];

    if (p.fullName.trim().isEmpty || p.phone.trim().isEmpty) missing.add('Basic info');

    if (p.collegeName.trim().isEmpty ||
        p.course.trim().isEmpty ||
        p.branch.trim().isEmpty ||
        p.graduationYear == null ||
        p.cgpa == null) {
      missing.add('Education');
    }
    if (p.skills.length < 3) missing.add('At least 3 skills');
    if (p.resumePath == null || p.resumePath!.isEmpty) missing.add('Resume');
    if (p.aboutMe.trim().isEmpty) missing.add('About me');
    if (!p.projects.any((pr) => pr.isComplete)) missing.add('Projects');
    if (p.certifications.isEmpty) missing.add('Certifications');
    if (p.achievements.isEmpty) missing.add('Achievements');
    if (p.linkedinUrl.trim().isEmpty) missing.add('LinkedIn');
    if (p.collegeEmail.trim().isEmpty) missing.add('College verification');

    return missing;
  }
}
