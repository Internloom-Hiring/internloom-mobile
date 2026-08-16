/// A placement drive enriched with the matching score used to rank discovery.
///
/// This model mirrors only the production columns needed by the discovery
/// feed. The matching model remains upstream; the mobile app only consumes
/// `final_score`.
class PlacementDrive {
  const PlacementDrive({
    required this.id,
    required this.companyId,
    required this.jobTitle,
    required this.jobDescription,
    required this.eligibilityCriteria,
    required this.ctc,
    required this.location,
    required this.applicationDeadline,
    required this.status,
    required this.finalScore,
  });

  final String id;
  final String companyId;
  final String jobTitle;
  final String jobDescription;
  final String? eligibilityCriteria;
  final String? ctc;
  final String? location;
  final DateTime? applicationDeadline;
  final String status;
  final double finalScore;

  factory PlacementDrive.fromMatchScoreRow(Map<String, dynamic> row) {
    final drive = Map<String, dynamic>.from(
      row['placement_drives'] as Map? ?? const <String, dynamic>{},
    );

    return PlacementDrive(
      id: drive['id'] as String,
      companyId: drive['company_id'] as String,
      jobTitle: drive['job_title'] as String? ?? '',
      jobDescription: drive['job_description'] as String? ?? '',
      eligibilityCriteria: drive['eligibility_criteria'] as String?,
      ctc: drive['ctc'] as String?,
      location: drive['location'] as String?,
      applicationDeadline: _parseDate(drive['application_deadline']),
      status: drive['status'] as String? ?? '',
      finalScore: (row['final_score'] as num?)?.toDouble() ?? 0,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
