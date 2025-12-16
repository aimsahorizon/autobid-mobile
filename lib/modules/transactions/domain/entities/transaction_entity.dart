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

/// Represents transaction form data - role-specific fields
/// Seller and Buyer have different responsibilities and form fields
class TransactionFormEntity {
  final String id;
  final String transactionId;
  final FormRole role;
  final FormStatus status;
  final DateTime submittedAt;
  final String? reviewNotes;

  // ===== SHARED FIELDS =====
  final DateTime preferredDate;
  final String contactNumber;
  final String additionalNotes;

  // ===== SELLER-SPECIFIC FIELDS =====
  // Document Checklist
  final bool orCrOriginalAvailable;
  final bool deedOfSaleReady;
  final bool releaseOfMortgage; // If applicable
  final bool registrationValid;
  final bool noLiensEncumbrances;

  // Vehicle Condition
  final bool conditionMatchesListing;
  final String? newIssuesDisclosure; // Any issues since listing
  final String fuelLevel; // Full, Half, Quarter, Empty
  final String? accessoriesIncluded; // Keys, manual, tools, etc.

  // Handover
  final String handoverLocation;
  final String handoverTimeSlot; // Morning, Afternoon, Evening

  // ===== BUYER-SPECIFIC FIELDS =====
  // Payment
  final String paymentMethod; // Bank Transfer, Cash, Financing
  final String? bankName;
  final String? accountName;
  final String? accountNumber;

  // Pickup/Delivery
  final String pickupOrDelivery; // Pickup, Delivery
  final String? deliveryAddress;

  // Acknowledgments
  final bool reviewedVehicleCondition;
  final bool understoodAuctionTerms;
  final bool willArrangeInsurance;
  final bool acceptsAsIsCondition;

  const TransactionFormEntity({
    required this.id,
    required this.transactionId,
    required this.role,
    required this.status,
    required this.submittedAt,
    this.reviewNotes,
    // Shared
    required this.preferredDate,
    this.contactNumber = '',
    this.additionalNotes = '',
    // Seller
    this.orCrOriginalAvailable = false,
    this.deedOfSaleReady = false,
    this.releaseOfMortgage = false,
    this.registrationValid = false,
    this.noLiensEncumbrances = false,
    this.conditionMatchesListing = false,
    this.newIssuesDisclosure,
    this.fuelLevel = 'Half',
    this.accessoriesIncluded,
    this.handoverLocation = '',
    this.handoverTimeSlot = 'Afternoon',
    // Buyer
    this.paymentMethod = 'Bank Transfer',
    this.bankName,
    this.accountName,
    this.accountNumber,
    this.pickupOrDelivery = 'Pickup',
    this.deliveryAddress,
    this.reviewedVehicleCondition = false,
    this.understoodAuctionTerms = false,
    this.willArrangeInsurance = false,
    this.acceptsAsIsCondition = false,
  });

  // Legacy getters for backward compatibility
  double get agreedPrice => 0; // Now comes from transaction
  DateTime get deliveryDate => preferredDate;
  String get deliveryLocation => pickupOrDelivery == 'Delivery'
      ? (deliveryAddress ?? handoverLocation)
      : handoverLocation;

  // Legacy checklist getters (map to new fields)
  bool get orCrVerified => orCrOriginalAvailable;
  bool get deedsOfSaleReady => deedOfSaleReady;
  bool get plateNumberConfirmed =>
      true; // Always true, not needed as separate field
  bool get noOutstandingLoans => noLiensEncumbrances;
  bool get mechanicalInspectionDone => conditionMatchesListing;

  /// Check if seller checklist is complete
  bool get sellerChecklistComplete =>
      orCrOriginalAvailable &&
      deedOfSaleReady &&
      registrationValid &&
      noLiensEncumbrances &&
      conditionMatchesListing;

  /// Check if buyer acknowledgments are complete
  bool get buyerAcknowledgmentsComplete =>
      reviewedVehicleCondition &&
      understoodAuctionTerms &&
      willArrangeInsurance &&
      acceptsAsIsCondition;

  /// Check if form is valid for submission
  bool get isValidForSubmission {
    if (role == FormRole.seller) {
      return sellerChecklistComplete &&
          handoverLocation.isNotEmpty &&
          contactNumber.isNotEmpty;
    } else {
      return buyerAcknowledgmentsComplete &&
          paymentMethod.isNotEmpty &&
          contactNumber.isNotEmpty;
    }
  }
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
