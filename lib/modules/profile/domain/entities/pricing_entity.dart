/// Token types in the system
enum TokenType {
  bidding,
  listing,
}

/// Extension for token type display
extension TokenTypeExtension on TokenType {
  String get label {
    switch (this) {
      case TokenType.bidding:
        return 'Bidding Token';
      case TokenType.listing:
        return 'Listing Token';
    }
  }
}

/// Subscription plan types
enum SubscriptionPlan {
  free,
  proBasicMonthly,
  proPlusMonthly,
  proBasicYearly,
  proPlusYearly,
}

/// Extension for subscription plan details
extension SubscriptionPlanExtension on SubscriptionPlan {
  String get name {
    switch (this) {
      case SubscriptionPlan.free:
        return 'Free';
      case SubscriptionPlan.proBasicMonthly:
        return 'Pro Basic';
      case SubscriptionPlan.proPlusMonthly:
        return 'Pro Plus';
      case SubscriptionPlan.proBasicYearly:
        return 'Pro Basic (Yearly)';
      case SubscriptionPlan.proPlusYearly:
        return 'Pro Plus (Yearly)';
    }
  }

  double get price {
    switch (this) {
      case SubscriptionPlan.free:
        return 0;
      case SubscriptionPlan.proBasicMonthly:
        return 199;
      case SubscriptionPlan.proPlusMonthly:
        return 499;
      case SubscriptionPlan.proBasicYearly:
        return 1699;
      case SubscriptionPlan.proPlusYearly:
        return 4499;
    }
  }

  int get biddingTokens {
    switch (this) {
      case SubscriptionPlan.free:
        return 10;
      case SubscriptionPlan.proBasicMonthly:
      case SubscriptionPlan.proBasicYearly:
        return 50;
      case SubscriptionPlan.proPlusMonthly:
      case SubscriptionPlan.proPlusYearly:
        return 250;
    }
  }

  int get listingTokens {
    switch (this) {
      case SubscriptionPlan.free:
        return 1;
      case SubscriptionPlan.proBasicMonthly:
      case SubscriptionPlan.proBasicYearly:
        return 3;
      case SubscriptionPlan.proPlusMonthly:
      case SubscriptionPlan.proPlusYearly:
        return 10;
    }
  }

  bool get isYearly {
    return this == SubscriptionPlan.proBasicYearly ||
           this == SubscriptionPlan.proPlusYearly;
  }

  String toJson() {
    switch (this) {
      case SubscriptionPlan.free:
        return 'free';
      case SubscriptionPlan.proBasicMonthly:
        return 'pro_basic_monthly';
      case SubscriptionPlan.proPlusMonthly:
        return 'pro_plus_monthly';
      case SubscriptionPlan.proBasicYearly:
        return 'pro_basic_yearly';
      case SubscriptionPlan.proPlusYearly:
        return 'pro_plus_yearly';
    }
  }

  static SubscriptionPlan fromJson(String value) {
    switch (value) {
      case 'free':
        return SubscriptionPlan.free;
      case 'pro_basic_monthly':
        return SubscriptionPlan.proBasicMonthly;
      case 'pro_plus_monthly':
        return SubscriptionPlan.proPlusMonthly;
      case 'pro_basic_yearly':
        return SubscriptionPlan.proBasicYearly;
      case 'pro_plus_yearly':
        return SubscriptionPlan.proPlusYearly;
      default:
        return SubscriptionPlan.free;
    }
  }
}

/// User's token balance
class TokenBalanceEntity {
  final String userId;
  final int biddingTokens;
  final int listingTokens;
  final DateTime updatedAt;

  const TokenBalanceEntity({
    required this.userId,
    required this.biddingTokens,
    required this.listingTokens,
    required this.updatedAt,
  });
}

/// User's subscription details
class UserSubscriptionEntity {
  final String userId;
  final SubscriptionPlan plan;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime? cancelledAt;

  const UserSubscriptionEntity({
    required this.userId,
    required this.plan,
    this.startDate,
    this.endDate,
    required this.isActive,
    this.cancelledAt,
  });

  bool get hasActivePlan => isActive && plan != SubscriptionPlan.free;
}

/// Token package for purchase
class TokenPackageEntity {
  final String id;
  final TokenType type;
  final int tokens;
  final int bonusTokens;
  final double price;
  final String description;

  const TokenPackageEntity({
    required this.id,
    required this.type,
    required this.tokens,
    this.bonusTokens = 0,
    required this.price,
    required this.description,
  });

  int get totalTokens => tokens + bonusTokens;
}

/// Transaction history for token purchases
class TokenTransactionEntity {
  final String id;
  final String userId;
  final TokenType type;
  final int amount;
  final double price;
  final String transactionType; // 'purchase', 'subscription', 'consumed'
  final DateTime createdAt;

  const TokenTransactionEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.price,
    required this.transactionType,
    required this.createdAt,
  });
}
