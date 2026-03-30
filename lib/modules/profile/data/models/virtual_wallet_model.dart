import '../../domain/entities/virtual_wallet_entity.dart';

class VirtualWalletModel {
  final String id;
  final String userId;
  final double balance;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VirtualWalletModel({
    required this.id,
    required this.userId,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VirtualWalletModel.fromJson(Map<String, dynamic> json) {
    return VirtualWalletModel(
      id: json['wallet_id'] as String? ?? json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      balance: _toDouble(json['balance']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  VirtualWalletEntity toEntity() {
    return VirtualWalletEntity(
      id: id,
      userId: userId,
      balance: balance,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

class WalletTransactionModel {
  final String id;
  final double amount;
  final String type;
  final String category;
  final String? referenceId;
  final String? description;
  final double balanceAfter;
  final DateTime createdAt;

  const WalletTransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    this.referenceId,
    this.description,
    required this.balanceAfter,
    required this.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'] as String,
      amount: VirtualWalletModel._toDouble(json['amount']),
      type: json['type'] as String,
      category: json['category'] as String,
      referenceId: json['reference_id'] as String?,
      description: json['description'] as String?,
      balanceAfter: VirtualWalletModel._toDouble(json['balance_after']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  WalletTransactionEntity toEntity() {
    return WalletTransactionEntity(
      id: id,
      amount: amount,
      type: type == 'credit'
          ? WalletTransactionType.credit
          : WalletTransactionType.debit,
      category: WalletTransactionCategoryExt.fromDb(category),
      referenceId: referenceId,
      description: description,
      balanceAfter: balanceAfter,
      createdAt: createdAt,
    );
  }
}
