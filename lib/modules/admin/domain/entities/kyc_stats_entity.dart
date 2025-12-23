class KycStatsEntity {
  final int totalSubmissions;
  final int pendingReview;
  final int underReview;
  final int approved;
  final int rejected;
  final int expired;
  final int slaAtRisk;
  final int slaBreached;
  final int assignedToMe;

  const KycStatsEntity({
    required this.totalSubmissions,
    required this.pendingReview,
    required this.underReview,
    required this.approved,
    required this.rejected,
    required this.expired,
    required this.slaAtRisk,
    required this.slaBreached,
    required this.assignedToMe,
  });

  int get needsReview => pendingReview + underReview;

  double get approvalRate {
    final total = approved + rejected;
    if (total == 0) return 0.0;
    return (approved / total) * 100;
  }
}
