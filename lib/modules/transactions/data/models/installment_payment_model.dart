import '../../domain/entities/installment_payment_entity.dart';

/// Data model for installment payments with JSON serialization
class InstallmentPaymentModel {
  final String id;
  final String installmentPlanId;
  final int paymentNumber;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String status;
  final String? proofImageUrl;
  final String? rejectionReason;
  final String? submittedBy;
  final String? confirmedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InstallmentPaymentModel({
    required this.id,
    required this.installmentPlanId,
    required this.paymentNumber,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    this.status = 'pending',
    this.proofImageUrl,
    this.rejectionReason,
    this.submittedBy,
    this.confirmedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InstallmentPaymentModel.fromJson(Map<String, dynamic> json) {
    return InstallmentPaymentModel(
      id: json['id'] as String,
      installmentPlanId: json['installment_plan_id'] as String,
      paymentNumber: json['payment_number'] as int? ?? 0,
      amount: _toDouble(json['amount']) ?? 0,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : DateTime.now(),
      paidDate: json['paid_date'] != null
          ? DateTime.parse(json['paid_date'] as String)
          : null,
      status: json['status'] as String? ?? 'pending',
      proofImageUrl: json['proof_image_url'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      submittedBy: json['submitted_by'] as String?,
      confirmedBy: json['confirmed_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'installment_plan_id': installmentPlanId,
      'payment_number': paymentNumber,
      'amount': amount,
      'due_date': dueDate.toIso8601String().split('T').first,
      'status': status,
      'proof_image_url': proofImageUrl,
      'rejection_reason': rejectionReason,
      'submitted_by': submittedBy,
      'confirmed_by': confirmedBy,
    };
  }

  InstallmentPaymentEntity toEntity() {
    return InstallmentPaymentEntity(
      id: id,
      installmentPlanId: installmentPlanId,
      paymentNumber: paymentNumber,
      amount: amount,
      dueDate: dueDate,
      paidDate: paidDate,
      status: InstallmentPaymentStatusExt.fromString(status),
      proofImageUrl: proofImageUrl,
      rejectionReason: rejectionReason,
      submittedBy: submittedBy,
      confirmedBy: confirmedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
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
