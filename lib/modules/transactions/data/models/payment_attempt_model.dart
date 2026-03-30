import '../../domain/entities/payment_attempt_entity.dart';

class PaymentAttemptModel {
  final String id;
  final String paymentId;
  final int attemptNumber;
  final double amount;
  final String? proofImageUrl;
  final String status;
  final String? rejectionReason;
  final String? submittedBy;
  final String? actedBy;
  final DateTime? actedAt;
  final DateTime createdAt;

  const PaymentAttemptModel({
    required this.id,
    required this.paymentId,
    required this.attemptNumber,
    required this.amount,
    this.proofImageUrl,
    this.status = 'submitted',
    this.rejectionReason,
    this.submittedBy,
    this.actedBy,
    this.actedAt,
    required this.createdAt,
  });

  factory PaymentAttemptModel.fromJson(Map<String, dynamic> json) {
    return PaymentAttemptModel(
      id: json['id'] as String,
      paymentId: json['payment_id'] as String,
      attemptNumber: json['attempt_number'] as int? ?? 1,
      amount: _toDouble(json['amount']) ?? 0,
      proofImageUrl: json['proof_image_url'] as String?,
      status: json['status'] as String? ?? 'submitted',
      rejectionReason: json['rejection_reason'] as String?,
      submittedBy: json['submitted_by'] as String?,
      actedBy: json['acted_by'] as String?,
      actedAt: json['acted_at'] != null
          ? DateTime.parse(json['acted_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  PaymentAttemptEntity toEntity() {
    return PaymentAttemptEntity(
      id: id,
      paymentId: paymentId,
      attemptNumber: attemptNumber,
      amount: amount,
      proofImageUrl: proofImageUrl,
      status: PaymentAttemptStatusExt.fromString(status),
      rejectionReason: rejectionReason,
      submittedBy: submittedBy,
      actedBy: actedBy,
      actedAt: actedAt,
      createdAt: createdAt,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
