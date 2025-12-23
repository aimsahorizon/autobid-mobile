import '../../domain/entities/account_status_entity.dart';

class AccountStatusModel extends AccountStatusEntity {
  AccountStatusModel({
    required super.userId,
    required super.status,
    required super.submittedAt,
    super.reviewedAt,
    super.reviewNotes,
    required super.userEmail,
    required super.userName,
  });

  factory AccountStatusModel.fromJson(Map<String, dynamic> json) {
    return AccountStatusModel(
      userId: json['user_id'] as String,
      status: _parseStatus(json['status'] as String),
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      reviewNotes: json['review_notes'] as String?,
      userEmail: json['user_email'] as String,
      userName: json['user_name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'status': _statusToString(status),
      'submitted_at': submittedAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'review_notes': reviewNotes,
      'user_email': userEmail,
      'user_name': userName,
    };
  }

  static AccountStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AccountStatus.pending;
      case 'under_review':
        return AccountStatus.underReview;
      case 'approved':
        return AccountStatus.approved;
      case 'rejected':
        return AccountStatus.rejected;
      case 'suspended':
        return AccountStatus.suspended;
      default:
        return AccountStatus.pending;
    }
  }

  static String _statusToString(AccountStatus status) {
    switch (status) {
      case AccountStatus.pending:
        return 'pending';
      case AccountStatus.underReview:
        return 'under_review';
      case AccountStatus.approved:
        return 'approved';
      case AccountStatus.rejected:
        return 'rejected';
      case AccountStatus.suspended:
        return 'suspended';
    }
  }
}
