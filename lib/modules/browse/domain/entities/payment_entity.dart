/// Represents different payment methods available in the app
/// GCash and Maya are popular Philippine e-wallets
/// Card supports Visa/Mastercard credit and debit cards
enum PaymentMethod {
  gcash,
  maya,
  card,
}

/// Extension to add display properties to PaymentMethod enum
/// Makes it easy to show user-friendly labels and icons
extension PaymentMethodExt on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.gcash:
        return 'GCash';
      case PaymentMethod.maya:
        return 'Maya';
      case PaymentMethod.card:
        return 'Credit/Debit Card';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.gcash:
        return 'assets/icons/gcash.png';
      case PaymentMethod.maya:
        return 'assets/icons/maya.png';
      case PaymentMethod.card:
        return 'assets/icons/card.png';
    }
  }
}

/// Tracks the current status of a payment transaction
/// Used to update UI and handle payment flow state
enum PaymentStatus {
  pending,    // Payment initiated, waiting for user action
  processing, // Payment being processed by gateway
  success,    // Payment completed successfully
  failed,     // Payment failed or was rejected
  cancelled,  // User cancelled the payment
}

/// Represents a payment transaction record
/// Stores all relevant info about a deposit or payment
class PaymentEntity {
  final String id;                    // Unique payment ID from PayMongo
  final String auctionId;             // Which auction this payment is for
  final double amount;                // Payment amount in PHP
  final PaymentMethod method;         // Selected payment method
  final PaymentStatus status;         // Current payment status
  final DateTime createdAt;           // When payment was initiated
  final DateTime? completedAt;        // When payment was completed (if any)
  final String? checkoutUrl;          // PayMongo checkout URL for redirect
  final String? errorMessage;         // Error message if payment failed

  const PaymentEntity({
    required this.id,
    required this.auctionId,
    required this.amount,
    required this.method,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.checkoutUrl,
    this.errorMessage,
  });

  /// Check if payment is still pending user action
  bool get isPending => status == PaymentStatus.pending;

  /// Check if payment completed successfully
  bool get isSuccess => status == PaymentStatus.success;

  /// Check if payment failed
  bool get isFailed => status == PaymentStatus.failed;
}
