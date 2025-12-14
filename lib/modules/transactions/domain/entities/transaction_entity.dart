/// Represents a transaction between buyer and seller
/// Tracks the complete lifecycle from discussion to completion
class TransactionEntity {
  final String id;
  final String listingId;
  final String sellerId;
  final String buyerId;
  final String carName;
  final String carImageUrl;
  final double agreedPrice;
  final TransactionStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;

  // Form submission tracking
  final bool sellerFormSubmitted;
  final bool buyerFormSubmitted;
  final bool sellerConfirmed;
  final bool buyerConfirmed;
  final bool adminApproved;
  final DateTime? adminApprovedAt;

  // Delivery tracking (only active after admin approval)
  final DeliveryStatus deliveryStatus;
  final DateTime? deliveryStartedAt;
  final DateTime? deliveryCompletedAt;

  // Buyer acceptance tracking (after delivery)
  final BuyerAcceptanceStatus buyerAcceptanceStatus;
  final DateTime? buyerAcceptedAt;
  final String? buyerRejectionReason;

  const TransactionEntity({
    required this.id,
    required this.listingId,
    required this.sellerId,
    required this.buyerId,
    required this.carName,
    required this.carImageUrl,
    required this.agreedPrice,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.sellerFormSubmitted = false,
    this.buyerFormSubmitted = false,
    this.sellerConfirmed = false,
    this.buyerConfirmed = false,
    this.adminApproved = false,
    this.adminApprovedAt,
    this.deliveryStatus = DeliveryStatus.pending,
    this.deliveryStartedAt,
    this.deliveryCompletedAt,
    this.buyerAcceptanceStatus = BuyerAcceptanceStatus.pending,
    this.buyerAcceptedAt,
    this.buyerRejectionReason,
  });

  /// Check if both parties have submitted forms
  bool get bothFormsSubmitted => sellerFormSubmitted && buyerFormSubmitted;

  /// Check if both parties have confirmed
  bool get bothConfirmed => sellerConfirmed && buyerConfirmed;

  /// Check if transaction is ready for admin review
  bool get readyForAdminReview => bothFormsSubmitted && bothConfirmed;

  /// Check if transaction is active (can be modified)
  bool get isActive =>
      status == TransactionStatus.discussion ||
      status == TransactionStatus.formReview;

  /// Check if buyer can accept/reject (vehicle must be delivered)
  bool get canBuyerRespond =>
      deliveryStatus == DeliveryStatus.delivered &&
      buyerAcceptanceStatus == BuyerAcceptanceStatus.pending;

  /// Check if transaction was successfully completed
  bool get isSuccessful =>
      buyerAcceptanceStatus == BuyerAcceptanceStatus.accepted &&
      status == TransactionStatus.completed;

  /// Check if deal failed due to rejection
  bool get isDealFailed =>
      buyerAcceptanceStatus == BuyerAcceptanceStatus.rejected ||
      status == TransactionStatus.cancelled;

  /// Copy with method for updating fields
  TransactionEntity copyWith({
    String? id,
    String? listingId,
    String? sellerId,
    String? buyerId,
    String? carName,
    String? carImageUrl,
    double? agreedPrice,
    TransactionStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? sellerFormSubmitted,
    bool? buyerFormSubmitted,
    bool? sellerConfirmed,
    bool? buyerConfirmed,
    bool? adminApproved,
    DateTime? adminApprovedAt,
    DeliveryStatus? deliveryStatus,
    DateTime? deliveryStartedAt,
    DateTime? deliveryCompletedAt,
    BuyerAcceptanceStatus? buyerAcceptanceStatus,
    DateTime? buyerAcceptedAt,
    String? buyerRejectionReason,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      sellerId: sellerId ?? this.sellerId,
      buyerId: buyerId ?? this.buyerId,
      carName: carName ?? this.carName,
      carImageUrl: carImageUrl ?? this.carImageUrl,
      agreedPrice: agreedPrice ?? this.agreedPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      sellerFormSubmitted: sellerFormSubmitted ?? this.sellerFormSubmitted,
      buyerFormSubmitted: buyerFormSubmitted ?? this.buyerFormSubmitted,
      sellerConfirmed: sellerConfirmed ?? this.sellerConfirmed,
      buyerConfirmed: buyerConfirmed ?? this.buyerConfirmed,
      adminApproved: adminApproved ?? this.adminApproved,
      adminApprovedAt: adminApprovedAt ?? this.adminApprovedAt,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      deliveryStartedAt: deliveryStartedAt ?? this.deliveryStartedAt,
      deliveryCompletedAt: deliveryCompletedAt ?? this.deliveryCompletedAt,
      buyerAcceptanceStatus:
          buyerAcceptanceStatus ?? this.buyerAcceptanceStatus,
      buyerAcceptedAt: buyerAcceptedAt ?? this.buyerAcceptedAt,
      buyerRejectionReason: buyerRejectionReason ?? this.buyerRejectionReason,
    );
  }
}

/// Status of the transaction in its lifecycle
enum TransactionStatus {
  discussion, // Initial discussion phase
  formReview, // Both forms submitted, parties reviewing
  pendingApproval, // Submitted to admin for approval
  approved, // Admin approved, deposit handled
  ongoing, // Seller processing transaction
  completed, // Transaction finished
  cancelled, // Transaction cancelled
  disputed, // Issue raised, needs resolution
}

/// Extension for user-friendly status labels
extension TransactionStatusExt on TransactionStatus {
  String get label {
    switch (this) {
      case TransactionStatus.discussion:
        return 'Discussion';
      case TransactionStatus.formReview:
        return 'Form Review';
      case TransactionStatus.pendingApproval:
        return 'Pending Approval';
      case TransactionStatus.approved:
        return 'Approved';
      case TransactionStatus.ongoing:
        return 'Ongoing';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
      case TransactionStatus.disputed:
        return 'Disputed';
    }
  }
}

/// Represents a chat message in transaction discussion
class ChatMessageEntity {
  final String id;
  final String transactionId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;

  const ChatMessageEntity({
    required this.id,
    required this.transactionId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
  });
}

/// Type of chat message
enum MessageType {
  text, // Regular text message
  system, // System notification (e.g., "Form submitted")
  attachment, // File or image attachment
}

/// Represents transaction form data (seller or buyer)
class TransactionFormEntity {
  final String id;
  final String transactionId;
  final FormRole role;
  final FormStatus status;

  // Agreement details
  final double agreedPrice;
  final String paymentMethod;
  final DateTime deliveryDate;
  final String deliveryLocation;

  // Legal checklist
  final bool orCrVerified;
  final bool deedsOfSaleReady;
  final bool plateNumberConfirmed;
  final bool registrationValid;
  final bool noOutstandingLoans;
  final bool mechanicalInspectionDone;

  // Additional terms
  final String additionalTerms;
  final DateTime submittedAt;
  final String? reviewNotes;

  const TransactionFormEntity({
    required this.id,
    required this.transactionId,
    required this.role,
    required this.status,
    required this.agreedPrice,
    required this.paymentMethod,
    required this.deliveryDate,
    required this.deliveryLocation,
    required this.orCrVerified,
    required this.deedsOfSaleReady,
    required this.plateNumberConfirmed,
    required this.registrationValid,
    required this.noOutstandingLoans,
    required this.mechanicalInspectionDone,
    required this.additionalTerms,
    required this.submittedAt,
    this.reviewNotes,
  });

  /// Check if all required checkboxes are checked
  bool get allChecklistComplete =>
      orCrVerified &&
      deedsOfSaleReady &&
      plateNumberConfirmed &&
      registrationValid &&
      noOutstandingLoans &&
      mechanicalInspectionDone;
}

/// Role in the transaction form
enum FormRole { seller, buyer }

/// Status of form submission and review
enum FormStatus {
  draft, // Not submitted yet
  submitted, // Submitted for review
  reviewed, // Other party reviewed
  changesRequested, // Changes requested
  confirmed, // Confirmed by other party
}

/// Represents a timeline event in transaction progress
class TransactionTimelineEntity {
  final String id;
  final String transactionId;
  final String title;
  final String description;
  final DateTime timestamp;
  final TimelineEventType type;
  final String? actorName; // Who performed the action

  const TransactionTimelineEntity({
    required this.id,
    required this.transactionId,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
    this.actorName,
  });
}

/// Type of timeline event
enum TimelineEventType {
  created, // Transaction created
  messageSent, // Chat message sent
  formSubmitted, // Form submitted
  formReviewed, // Form reviewed
  formConfirmed, // Form confirmed
  adminReview, // Sent to admin
  adminSubmitted, // Submitted to admin for approval
  adminApproved, // Admin approved
  depositRefunded, // Deposit refunded
  transactionStarted, // Seller started processing
  deliveryStarted, // Delivery process started
  deliveryCompleted, // Delivery completed
  completed, // Transaction completed
  cancelled, // Transaction cancelled
  disputed, // Dispute raised
}

/// Delivery status for vehicle handover
enum DeliveryStatus {
  pending, // Not started yet
  preparing, // Seller preparing vehicle
  inTransit, // Vehicle in transit
  delivered, // Vehicle delivered to buyer
  completed, // Delivery confirmed by buyer
}

/// Buyer's response after receiving the vehicle
enum BuyerAcceptanceStatus {
  pending, // Waiting for buyer response (vehicle not yet delivered)
  accepted, // Buyer accepted the car - deal successful
  rejected, // Buyer rejected - deal failed
}

/// Extension for BuyerAcceptanceStatus display
extension BuyerAcceptanceStatusExt on BuyerAcceptanceStatus {
  String get label {
    switch (this) {
      case BuyerAcceptanceStatus.pending:
        return 'Pending';
      case BuyerAcceptanceStatus.accepted:
        return 'Accepted';
      case BuyerAcceptanceStatus.rejected:
        return 'Rejected';
    }
  }

  String get description {
    switch (this) {
      case BuyerAcceptanceStatus.pending:
        return 'Awaiting buyer confirmation';
      case BuyerAcceptanceStatus.accepted:
        return 'Buyer confirmed receipt of vehicle';
      case BuyerAcceptanceStatus.rejected:
        return 'Buyer rejected the vehicle';
    }
  }
}
