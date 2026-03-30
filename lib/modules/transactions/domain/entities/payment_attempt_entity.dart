/// Represents a single submission attempt for an installment payment.
/// Tracks the history of submissions, rejections, and confirmations.
class PaymentAttemptEntity {
  final String id;
  final String paymentId;
  final int attemptNumber;
  final double amount;
  final String? proofImageUrl;
  final PaymentAttemptStatus status;
  final String? rejectionReason;
  final String? submittedBy;
  final String? actedBy;
  final DateTime? actedAt;
  final DateTime createdAt;

  const PaymentAttemptEntity({
    required this.id,
    required this.paymentId,
    required this.attemptNumber,
    required this.amount,
    this.proofImageUrl,
    this.status = PaymentAttemptStatus.submitted,
    this.rejectionReason,
    this.submittedBy,
    this.actedBy,
    this.actedAt,
    required this.createdAt,
  });
}

enum PaymentAttemptStatus { submitted, confirmed, rejected }

extension PaymentAttemptStatusExt on PaymentAttemptStatus {
  String get dbValue {
    switch (this) {
      case PaymentAttemptStatus.submitted:
        return 'submitted';
      case PaymentAttemptStatus.confirmed:
        return 'confirmed';
      case PaymentAttemptStatus.rejected:
        return 'rejected';
    }
  }

  String get label {
    switch (this) {
      case PaymentAttemptStatus.submitted:
        return 'Submitted';
      case PaymentAttemptStatus.confirmed:
        return 'Confirmed';
      case PaymentAttemptStatus.rejected:
        return 'Rejected';
    }
  }

  static PaymentAttemptStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'confirmed':
        return PaymentAttemptStatus.confirmed;
      case 'rejected':
        return PaymentAttemptStatus.rejected;
      default:
        return PaymentAttemptStatus.submitted;
    }
  }
}
