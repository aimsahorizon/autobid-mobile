/// Buyer's transaction entity for won auctions
/// Similar to seller's transaction but from buyer perspective
class BuyerTransactionEntity {
  final String id;
  final String auctionId;
  final String sellerId;
  final String buyerId;

  // Car details
  final String carName;
  final String carImageUrl;

  // Transaction details
  final double agreedPrice;
  final double depositPaid;
  final TransactionStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;

  // Form submission status
  final bool buyerFormSubmitted;
  final bool sellerFormSubmitted;
  final bool buyerConfirmed;
  final bool sellerConfirmed;

  // Admin approval
  final bool adminApproved;
  final DateTime? adminApprovedAt;

  const BuyerTransactionEntity({
    required this.id,
    required this.auctionId,
    required this.sellerId,
    required this.buyerId,
    required this.carName,
    required this.carImageUrl,
    required this.agreedPrice,
    required this.depositPaid,
    required this.status,
    required this.createdAt,
    this.completedAt,
    required this.buyerFormSubmitted,
    required this.sellerFormSubmitted,
    required this.buyerConfirmed,
    required this.sellerConfirmed,
    required this.adminApproved,
    this.adminApprovedAt,
  });

  bool get readyForAdminReview =>
      buyerFormSubmitted &&
      sellerFormSubmitted &&
      buyerConfirmed &&
      sellerConfirmed &&
      !adminApproved;
}

enum TransactionStatus {
  discussion,
  formSubmission,
  formReview,
  pendingApproval,
  approved,
  completed,
  cancelled,
}

/// Buyer's transaction form
class BuyerTransactionFormEntity {
  final String id;
  final String transactionId;
  final FormRole role;

  // Buyer information
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String province;
  final String zipCode;

  // ID verification
  final String idType;
  final String idNumber;
  final String? idPhotoUrl;

  // Payment details
  final String paymentMethod;
  final String? bankName;
  final String? accountNumber;

  // Delivery preference
  final String deliveryMethod;
  final String? deliveryAddress;

  // Agreement
  final bool agreedToTerms;
  final DateTime? submittedAt;
  final bool isConfirmed;

  const BuyerTransactionFormEntity({
    required this.id,
    required this.transactionId,
    required this.role,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.province,
    required this.zipCode,
    required this.idType,
    required this.idNumber,
    this.idPhotoUrl,
    required this.paymentMethod,
    this.bankName,
    this.accountNumber,
    required this.deliveryMethod,
    this.deliveryAddress,
    required this.agreedToTerms,
    this.submittedAt,
    required this.isConfirmed,
  });
}

enum FormRole {
  buyer,
  seller,
}

/// Chat message in transaction
class TransactionChatMessage {
  final String id;
  final String transactionId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;

  const TransactionChatMessage({
    required this.id,
    required this.transactionId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
  });
}

/// Timeline event in transaction progress
class TransactionTimelineEvent {
  final String id;
  final String transactionId;
  final String title;
  final String description;
  final DateTime timestamp;
  final TimelineEventType type;
  final String actorName;

  const TransactionTimelineEvent({
    required this.id,
    required this.transactionId,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
    required this.actorName,
  });
}

enum TimelineEventType {
  created,
  formSubmitted,
  formConfirmed,
  adminReview,
  adminApproved,
  completed,
  cancelled,
}
