/// Represents an installment payment plan linked to a transaction
class InstallmentPlanEntity {
  final String id;
  final String transactionId;
  final double totalAmount;
  final double downPayment;
  final double remainingAmount;
  final double totalPaid;
  final int numInstallments;
  final String frequency; // weekly, bi-weekly, monthly, no_schedule
  final DateTime startDate;
  final InstallmentPlanStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InstallmentPlanEntity({
    required this.id,
    required this.transactionId,
    required this.totalAmount,
    this.downPayment = 0,
    required this.remainingAmount,
    this.totalPaid = 0,
    this.numInstallments = 1,
    this.frequency = 'monthly',
    required this.startDate,
    this.status = InstallmentPlanStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Progress percentage (0.0 - 1.0)
  double get progress =>
      totalAmount > 0 ? (totalPaid / totalAmount).clamp(0.0, 1.0) : 0.0;

  /// Whether the plan is fully paid
  bool get isFullyPaid => totalPaid >= totalAmount;

  InstallmentPlanEntity copyWith({
    String? id,
    String? transactionId,
    double? totalAmount,
    double? downPayment,
    double? remainingAmount,
    double? totalPaid,
    int? numInstallments,
    String? frequency,
    DateTime? startDate,
    InstallmentPlanStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InstallmentPlanEntity(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      totalAmount: totalAmount ?? this.totalAmount,
      downPayment: downPayment ?? this.downPayment,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      totalPaid: totalPaid ?? this.totalPaid,
      numInstallments: numInstallments ?? this.numInstallments,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum InstallmentPlanStatus { active, completed, defaulted }

extension InstallmentPlanStatusExt on InstallmentPlanStatus {
  String get label {
    switch (this) {
      case InstallmentPlanStatus.active:
        return 'Active';
      case InstallmentPlanStatus.completed:
        return 'Completed';
      case InstallmentPlanStatus.defaulted:
        return 'Defaulted';
    }
  }

  String get dbValue {
    switch (this) {
      case InstallmentPlanStatus.active:
        return 'active';
      case InstallmentPlanStatus.completed:
        return 'completed';
      case InstallmentPlanStatus.defaulted:
        return 'defaulted';
    }
  }

  static InstallmentPlanStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'completed':
        return InstallmentPlanStatus.completed;
      case 'defaulted':
        return InstallmentPlanStatus.defaulted;
      default:
        return InstallmentPlanStatus.active;
    }
  }
}
