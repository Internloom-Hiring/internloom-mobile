class JobDiscoveryFilters {
  const JobDiscoveryFilters({
    this.location = '',
    this.ctc = '',
  });

  final String location;
  final String ctc;

  bool get isEmpty => location.trim().isEmpty && ctc.trim().isEmpty;

  JobDiscoveryFilters copyWith({
    String? location,
    String? ctc,
  }) {
    return JobDiscoveryFilters(
      location: location ?? this.location,
      ctc: ctc ?? this.ctc,
    );
  }
}
