/// Central route name constants for InternLoom Mobile.
///
/// All navigation should reference these constants rather than raw strings so
/// that a route rename shows up as a compile error across the whole codebase.
///
/// Usage:
///   context.goNamed(RouteNames.login);
///   context.pushNamed(RouteNames.studentEditSkills);
class RouteNames {
  RouteNames._();

  // ─── Shared / Auth ────────────────────────────────────────────────────────
  static const String splash = 'splash';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgot-password';
  static const String updatePassword = 'update-password';

  // ─── Student Flow ─────────────────────────────────────────────────────────
  static const String studentSetup = 'student-setup';
  static const String studentProfile = 'student-profile';

  // Job discovery
  static const String studentDiscover = 'student-discover';
  static const String studentSavedJobs = 'student-saved-jobs';
  static const String studentJobDetails = 'student-job-details';

  // Profile edit sub-routes (nested under /student/profile)
  static const String studentEditBasic = 'student-edit-basic';
  static const String studentEditAbout = 'student-edit-about';
  static const String studentEditEducation = 'student-edit-education';
  static const String studentEditVerification = 'student-edit-verification';
  static const String studentEditSkills = 'student-edit-skills';
  static const String studentEditProjects = 'student-edit-projects';
  static const String studentEditCertifications = 'student-edit-certifications';
  static const String studentEditAchievements = 'student-edit-achievements';
  static const String studentEditResume = 'student-edit-resume';
  static const String studentEditLinkedin = 'student-edit-linkedin';

  // ─── Company Flow (Sprint 2 placeholders — Developer 4 owns screens) ──────
  static const String companyDashboard = 'company-dashboard';
  static const String companyProfile = 'company-profile';
  static const String companyApprovalWait = 'company-approval-wait';
  static const String companyPostDrive = 'company-post-drive';
  static const String companyMyDrives = 'company-my-drives';
  static const String companyCandidateList = 'company-candidate-list';
  static const String companyCandidateDetail = 'company-candidate-detail';
  static const String companyPipelineFunnel = 'company-pipeline-funnel';
}
