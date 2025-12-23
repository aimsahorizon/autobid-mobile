import '../../domain/entities/kyc_stats_entity.dart';

class KycStatsModel extends KycStatsEntity {
  const KycStatsModel({
    required super.totalSubmissions,
    required super.pendingReview,
    required super.underReview,
    required super.approved,
    required super.rejected,
    required super.expired,
    required super.slaAtRisk,
    required super.slaBreached,
    required super.assignedToMe,
  });

  factory KycStatsModel.fromJson(Map<String, dynamic> json) {
    return KycStatsModel(
      totalSubmissions: json['total_submissions'] as int? ?? 0,
      pendingReview: json['pending_review'] as int? ?? 0,
      underReview: json['under_review'] as int? ?? 0,
      approved: json['approved'] as int? ?? 0,
      rejected: json['rejected'] as int? ?? 0,
      expired: json['expired'] as int? ?? 0,
      slaAtRisk: json['sla_at_risk'] as int? ?? 0,
      slaBreached: json['sla_breached'] as int? ?? 0,
      assignedToMe: json['assigned_to_me'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_submissions': totalSubmissions,
      'pending_review': pendingReview,
      'under_review': underReview,
      'approved': approved,
      'rejected': rejected,
      'expired': expired,
      'sla_at_risk': slaAtRisk,
      'sla_breached': slaBreached,
      'assigned_to_me': assignedToMe,
    };
  }
}
