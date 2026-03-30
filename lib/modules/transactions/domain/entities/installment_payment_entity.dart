/// Represents a single payment within an installment plan
class InstallmentPaymentEntity {
  final String id;
  final String installmentPlanId;
  final int paymentNumber;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final InstallmentPaymentStatus status;
  final String? proofImageUrl;
  final String? rejectionReason;
  final String? submittedBy;
  final String? confirmedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InstallmentPaymentEntity({
    required this.id,
    required this.installmentPlanId,
    required this.paymentNumber,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    this.status = InstallmentPaymentStatus.pending,
    this.proofImageUrl,
    this.rejectionReason,
    this.submittedBy,
    this.confirmedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Whether this payment has no scheduled due date (no_schedule frequency)
  /// We detect this by checking if the due date is far in the future (year 9999)
  bool get hasNoDueDate => dueDate.year >= 9999;

  /// Whether payment is overdue
  /// - Not overdue if frequency is no_schedule (far-future due date)
  /// - Down payment (#0) gets a 3-day grace period
  bool get isOverdue {
    if (status != InstallmentPaymentStatus.pending) return false;
    if (hasNoDueDate) return false;
    return DateTime.now().isAfter(dueDate);
  }

  /// Whether seller can act on this payment
  bool get canSellerAct => status == InstallmentPaymentStatus.submitted;

  InstallmentPaymentEntity copyWith({
    String? id,
    String? installmentPlanId,
    int? paymentNumber,
    double? amount,
    DateTime? dueDate,
    DateTime? paidDate,
    InstallmentPaymentStatus? status,
    String? proofImageUrl,
    String? rejectionReason,
    String? submittedBy,
    String? confirmedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InstallmentPaymentEntity(
      id: id ?? this.id,
      installmentPlanId: installmentPlanId ?? this.installmentPlanId,
      paymentNumber: paymentNumber ?? this.paymentNumber,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      status: status ?? this.status,
      proofImageUrl: proofImageUrl ?? this.proofImageUrl,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      submittedBy: submittedBy ?? this.submittedBy,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum InstallmentPaymentStatus { pending, submitted, confirmed, rejected }

extension InstallmentPaymentStatusExt on InstallmentPaymentStatus {
  String get label {
    switch (this) {
      case InstallmentPaymentStatus.pending:
        return 'Pending';
      case InstallmentPaymentStatus.submitted:
        return 'Submitted';
      case InstallmentPaymentStatus.confirmed:
        return 'Confirmed';
      case InstallmentPaymentStatus.rejected:
        return 'Rejected';
    }
  }

  String get dbValue {
    switch (this) {
      case InstallmentPaymentStatus.pending:
        return 'pending';
      case InstallmentPaymentStatus.submitted:
        return 'submitted';
      case InstallmentPaymentStatus.confirmed:
        return 'confirmed';
      case InstallmentPaymentStatus.rejected:
        return 'rejected';
    }
  }

  static InstallmentPaymentStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'submitted':
        return InstallmentPaymentStatus.submitted;
      case 'confirmed':
        return InstallmentPaymentStatus.confirmed;
      case 'rejected':
        return InstallmentPaymentStatus.rejected;
      default:
        return InstallmentPaymentStatus.pending;
    }
  }
}
