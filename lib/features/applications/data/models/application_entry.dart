/// One row in the student's Applications List — an `applications` row
/// joined with the parent drive's title and the drive's company name
/// for display.
///
/// Column names confirmed via a teammate's reference SQL (the "Applied"
/// query joining auth.users -> students -> applications -> placement_drives):
/// applications.application_date (NOT created_at — an earlier guess that
/// was wrong but silently never hit, since the companies.name error below
/// surfaced first) and placement_drives.job_title (NOT title — same
/// situation). companies.company_name confirmed earlier via a real
/// PostgrestException. student_id/drive_id/status remain as originally
/// sourced from the Sprint 2 task breakdown.
class ApplicationEntry {
  const ApplicationEntry({
    required this.id,
    required this.driveId,
    required this.driveTitle,
    required this.companyName,
    required this.status,
    required this.appliedAt,
  });

  final String id;
  final String driveId;
  final String driveTitle;
  final String companyName;

  /// One of the five confirmed production values:
  /// applied, shortlisted, rejected, selected, withdrawn.
  final String status;
  final DateTime appliedAt;

  bool get isTerminal => status == 'selected' || status == 'rejected';

  factory ApplicationEntry.fromJoinedRow(Map<String, dynamic> row) {
    final drive = row['placement_drives'] as Map<String, dynamic>?;
    final company = drive?['companies'] as Map<String, dynamic>?;
    final applicationDate = row['application_date'] as String?;
    return ApplicationEntry(
      id: row['id'] as String,
      driveId: row['drive_id'] as String,
      driveTitle: (drive?['job_title'] as String?) ?? 'Untitled drive',
      companyName: (company?['company_name'] as String?) ?? 'Unknown company',
      status: (row['status'] as String?) ?? 'applied',
      appliedAt: applicationDate != null ? DateTime.parse(applicationDate) : DateTime.now(),
    );
  }
}
