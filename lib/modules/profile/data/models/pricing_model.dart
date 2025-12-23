import '../../domain/entities/pricing_entity.dart';

/// Model for user token balance with JSON serialization
class TokenBalanceModel extends TokenBalanceEntity {
  const TokenBalanceModel({
    required super.userId,
    required super.biddingTokens,
    required super.listingTokens,
    required super.updatedAt,
  });

  factory TokenBalanceModel.fromJson(Map<String, dynamic> json) {
    return TokenBalanceModel(
      userId: json['user_id'] as String,
      biddingTokens: json['bidding_tokens'] as int,
      listingTokens: json['listing_tokens'] as int,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'bidding_tokens': biddingTokens,
      'listing_tokens': listingTokens,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Model for user subscription with JSON serialization
class UserSubscriptionModel extends UserSubscriptionEntity {
  const UserSubscriptionModel({
    required super.userId,
    required super.plan,
    super.startDate,
    super.endDate,
    required super.isActive,
    super.cancelledAt,
  });

  factory UserSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return UserSubscriptionModel(
      userId: json['user_id'] as String,
      plan: SubscriptionPlanExtension.fromJson(json['plan'] as String),
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      isActive: json['is_active'] as bool,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'plan': plan.toJson(),
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive,
      'cancelled_at': cancelledAt?.toIso8601String(),
    };
  }
}

/// Model for token transaction with JSON serialization
class TokenTransactionModel extends TokenTransactionEntity {
  const TokenTransactionModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.amount,
    required super.price,
    required super.transactionType,
    required super.createdAt,
  });

  factory TokenTransactionModel.fromJson(Map<String, dynamic> json) {
    return TokenTransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: (json['token_type'] as String) == 'bidding'
          ? TokenType.bidding
          : TokenType.listing,
      amount: json['amount'] as int,
      price: (json['price'] as num).toDouble(),
      transactionType: json['transaction_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'token_type': type == TokenType.bidding ? 'bidding' : 'listing',
      'amount': amount,
      'price': price,
      'transaction_type': transactionType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
