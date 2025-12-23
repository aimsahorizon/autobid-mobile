/// Entity representing a transaction for admin review
class AdminTransactionEntity {
  final String id;
  final String auctionId;
  final String sellerId;
  final String buyerId;
  final String sellerName;
  final String buyerName;
  final String carName;
  final String carImageUrl;
  final double agreedPrice;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  // Form submission tracking
  final bool sellerFormSubmitted;
  final bool buyerFormSubmitted;
  final bool sellerConfirmed;
  final bool buyerConfirmed;
  final bool adminApproved;
  final DateTime? adminApprovedAt;

  // Admin review fields
  final String? adminNotes;
  final String? reviewedBy;

  const AdminTransactionEntity({
    required this.id,
    required this.auctionId,
    required this.sellerId,
    required this.buyerId,
    required this.sellerName,
    required this.buyerName,
    required this.carName,
    required this.carImageUrl,
    required this.agreedPrice,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.sellerFormSubmitted = false,
    this.buyerFormSubmitted = false,
    this.sellerConfirmed = false,
    this.buyerConfirmed = false,
    this.adminApproved = false,
    this.adminApprovedAt,
    this.adminNotes,
    this.reviewedBy,
  });

  /// Check if both parties have submitted forms
  bool get bothFormsSubmitted => sellerFormSubmitted && buyerFormSubmitted;

  /// Check if both parties have confirmed
  bool get bothConfirmed => sellerConfirmed && buyerConfirmed;

  /// Check if ready for admin review
  bool get readyForReview =>
      bothFormsSubmitted && bothConfirmed && !adminApproved;

  /// Get status label
  String get statusLabel {
    switch (status) {
      case 'in_transaction':
        return 'In Transaction';
      case 'sold':
        return 'Sold';
      case 'deal_failed':
        return 'Deal Failed';
      default:
        return status;
    }
  }

  /// Get review status for admin
  AdminReviewStatus get reviewStatus {
    if (adminApproved) return AdminReviewStatus.approved;
    if (status == 'deal_failed') return AdminReviewStatus.failed;
    if (status == 'sold') return AdminReviewStatus.completed;
    if (readyForReview) return AdminReviewStatus.pendingReview;
    if (bothFormsSubmitted) return AdminReviewStatus.awaitingConfirmation;
    return AdminReviewStatus.inProgress;
  }
}

/// Status for admin review filtering
enum AdminReviewStatus {
  pendingReview, // Ready for admin to review
  awaitingConfirmation, // Forms submitted, waiting for both to confirm
  inProgress, // Still in discussion/form submission
  approved, // Admin approved
  completed, // Transaction completed (sold)
  failed, // Deal failed
}

extension AdminReviewStatusExt on AdminReviewStatus {
  String get label {
    switch (this) {
      case AdminReviewStatus.pendingReview:
        return 'Pending Review';
      case AdminReviewStatus.awaitingConfirmation:
        return 'Awaiting Confirmation';
      case AdminReviewStatus.inProgress:
        return 'In Progress';
      case AdminReviewStatus.approved:
        return 'Approved';
      case AdminReviewStatus.completed:
        return 'Completed';
      case AdminReviewStatus.failed:
        return 'Failed';
    }
  }

  String get description {
    switch (this) {
      case AdminReviewStatus.pendingReview:
        return 'Both parties confirmed, needs admin approval';
      case AdminReviewStatus.awaitingConfirmation:
        return 'Forms submitted, waiting for confirmations';
      case AdminReviewStatus.inProgress:
        return 'Parties still discussing or filling forms';
      case AdminReviewStatus.approved:
        return 'Admin approved, proceeding to delivery';
      case AdminReviewStatus.completed:
        return 'Transaction completed successfully';
      case AdminReviewStatus.failed:
        return 'Transaction failed or cancelled';
    }
  }
}

/// Transaction form entity for admin review
class AdminTransactionFormEntity {
  final String id;
  final String transactionId;
  final String role; // 'seller' or 'buyer'
  final String status;
  final double agreedPrice;
  final String? paymentMethod;
  final DateTime? deliveryDate;
  final String? deliveryLocation;

  // Legal checklist
  final bool orCrVerified;
  final bool deedsOfSaleReady;
  final bool plateNumberConfirmed;
  final bool registrationValid;
  final bool noOutstandingLoans;
  final bool mechanicalInspectionDone;

  final String? additionalTerms;
  final String? reviewNotes;
  final DateTime? submittedAt;
  final DateTime createdAt;

  const AdminTransactionFormEntity({
    required this.id,
    required this.transactionId,
    required this.role,
    required this.status,
    required this.agreedPrice,
    this.paymentMethod,
    this.deliveryDate,
    this.deliveryLocation,
    this.orCrVerified = false,
    this.deedsOfSaleReady = false,
    this.plateNumberConfirmed = false,
    this.registrationValid = false,
    this.noOutstandingLoans = false,
    this.mechanicalInspectionDone = false,
    this.additionalTerms,
    this.reviewNotes,
    this.submittedAt,
    required this.createdAt,
  });

  bool get isSeller => role == 'seller';
  bool get isBuyer => role == 'buyer';

  int get checklistCompletedCount {
    int count = 0;
    if (orCrVerified) count++;
    if (deedsOfSaleReady) count++;
    if (plateNumberConfirmed) count++;
    if (registrationValid) count++;
    if (noOutstandingLoans) count++;
    if (mechanicalInspectionDone) count++;
    return count;
  }

  int get checklistTotalCount => 6;
}

/// Stats for admin transaction dashboard
class AdminTransactionStats {
  final int total;
  final int pendingReview;
  final int awaitingConfirmation;
  final int inProgress;
  final int approved;
  final int completed;
  final int failed;

  const AdminTransactionStats({
    required this.total,
    required this.pendingReview,
    required this.awaitingConfirmation,
    required this.inProgress,
    required this.approved,
    required this.completed,
    required this.failed,
  });
}
