import '../../domain/entities/installment_plan_entity.dart';

/// Data model for installment plans with JSON serialization
class InstallmentPlanModel {
  final String id;
  final String transactionId;
  final double totalAmount;
  final double downPayment;
  final double remainingAmount;
  final double totalPaid;
  final int numInstallments;
  final String frequency;
  final DateTime startDate;
  final String status;
  final bool buyerConfirmedPlan;
  final bool sellerConfirmedPlan;
  final String? proposedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InstallmentPlanModel({
    required this.id,
    required this.transactionId,
    required this.totalAmount,
    this.downPayment = 0,
    required this.remainingAmount,
    this.totalPaid = 0,
    this.numInstallments = 1,
    this.frequency = 'monthly',
    required this.startDate,
    this.status = 'active',
    this.buyerConfirmedPlan = false,
    this.sellerConfirmedPlan = false,
    this.proposedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InstallmentPlanModel.fromJson(Map<String, dynamic> json) {
    return InstallmentPlanModel(
      id: json['id'] as String,
      transactionId: json['transaction_id'] as String,
      totalAmount: _toDouble(json['total_amount']) ?? 0,
      downPayment: _toDouble(json['down_payment']) ?? 0,
      remainingAmount: _toDouble(json['remaining_amount']) ?? 0,
      totalPaid: _toDouble(json['total_paid']) ?? 0,
      numInstallments: json['num_installments'] as int? ?? 1,
      frequency: json['frequency'] as String? ?? 'monthly',
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : DateTime.now(),
      status: json['status'] as String? ?? 'active',
      buyerConfirmedPlan: json['buyer_confirmed_plan'] as bool? ?? false,
      sellerConfirmedPlan: json['seller_confirmed_plan'] as bool? ?? false,
      proposedBy: json['proposed_by'] as String?,
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
      'transaction_id': transactionId,
      'total_amount': totalAmount,
      'down_payment': downPayment,
      'remaining_amount': remainingAmount,
      'total_paid': totalPaid,
      'num_installments': numInstallments,
      'frequency': frequency,
      'start_date': startDate.toIso8601String().split('T').first,
      'status': status,
      'buyer_confirmed_plan': buyerConfirmedPlan,
      'seller_confirmed_plan': sellerConfirmedPlan,
      'proposed_by': proposedBy,
    };
  }

  InstallmentPlanEntity toEntity() {
    return InstallmentPlanEntity(
      id: id,
      transactionId: transactionId,
      totalAmount: totalAmount,
      downPayment: downPayment,
      remainingAmount: remainingAmount,
      totalPaid: totalPaid,
      numInstallments: numInstallments,
      frequency: frequency,
      startDate: startDate,
      status: InstallmentPlanStatusExt.fromString(status),
      buyerConfirmedPlan: buyerConfirmedPlan,
      sellerConfirmedPlan: sellerConfirmedPlan,
      proposedBy: proposedBy,
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
