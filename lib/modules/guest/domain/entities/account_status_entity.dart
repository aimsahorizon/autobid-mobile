enum AccountStatus {
  pending,
  underReview,
  approved,
  rejected,
  suspended,
}

extension AccountStatusExtension on AccountStatus {
  String get displayName {
    switch (this) {
      case AccountStatus.pending:
        return 'Pending Verification';
      case AccountStatus.underReview:
        return 'Under Review';
      case AccountStatus.approved:
        return 'Approved';
      case AccountStatus.rejected:
        return 'Rejected';
      case AccountStatus.suspended:
        return 'Suspended';
    }
  }

  String get description {
    switch (this) {
      case AccountStatus.pending:
        return 'Your KYC documents are waiting to be reviewed by our team.';
      case AccountStatus.underReview:
        return 'Our team is currently reviewing your submitted documents.';
      case AccountStatus.approved:
        return 'Your account has been verified. You can now participate in auctions.';
      case AccountStatus.rejected:
        return 'Your verification was rejected. Please contact support for more details.';
      case AccountStatus.suspended:
        return 'Your account has been suspended. Contact support for assistance.';
    }
  }
}

class AccountStatusEntity {
  final String userId;
  final AccountStatus status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewNotes;
  final String userEmail;
  final String userName;

  AccountStatusEntity({
    required this.userId,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewNotes,
    required this.userEmail,
    required this.userName,
  });
}
