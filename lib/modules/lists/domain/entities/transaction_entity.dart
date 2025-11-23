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
  });

  /// Check if both parties have submitted forms
  bool get bothFormsSubmitted => sellerFormSubmitted && buyerFormSubmitted;

  /// Check if both parties have confirmed
  bool get bothConfirmed => sellerConfirmed && buyerConfirmed;

  /// Check if transaction is ready for admin review
  bool get readyForAdminReview => bothFormsSubmitted && bothConfirmed;

  /// Check if transaction is active (can be modified)
  bool get isActive => status == TransactionStatus.discussion ||
                       status == TransactionStatus.formReview;
}

/// Status of the transaction in its lifecycle
enum TransactionStatus {
  discussion,      // Initial discussion phase
  formReview,      // Both forms submitted, parties reviewing
  pendingApproval, // Submitted to admin for approval
  approved,        // Admin approved, deposit handled
  ongoing,         // Seller processing transaction
  completed,       // Transaction finished
  cancelled,       // Transaction cancelled
  disputed,        // Issue raised, needs resolution
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
  text,      // Regular text message
  system,    // System notification (e.g., "Form submitted")
  attachment // File or image attachment
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
  draft,           // Not submitted yet
  submitted,       // Submitted for review
  reviewed,        // Other party reviewed
  changesRequested,// Changes requested
  confirmed,       // Confirmed by other party
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
  created,         // Transaction created
  formSubmitted,   // Form submitted
  formConfirmed,   // Form confirmed
  adminReview,     // Sent to admin
  adminApproved,   // Admin approved
  depositRefunded, // Deposit refunded
  transactionStarted, // Seller started processing
  completed,       // Transaction completed
  cancelled,       // Transaction cancelled
  disputed,        // Dispute raised
}
