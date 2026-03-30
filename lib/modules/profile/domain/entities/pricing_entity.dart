/// Token types in the system
enum TokenType { bidding, listing }

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
  silverMonthly,
  silverYearly,
  goldMonthly,
  goldYearly,
}

/// Extension for subscription plan details
extension SubscriptionPlanExtension on SubscriptionPlan {
  String get name {
    switch (this) {
      case SubscriptionPlan.free:
        return 'Free';
      case SubscriptionPlan.silverMonthly:
        return 'Silver';
      case SubscriptionPlan.silverYearly:
        return 'Silver (Yearly)';
      case SubscriptionPlan.goldMonthly:
        return 'Gold';
      case SubscriptionPlan.goldYearly:
        return 'Gold (Yearly)';
    }
  }

  double get price {
    switch (this) {
      case SubscriptionPlan.free:
        return 0;
      case SubscriptionPlan.silverMonthly:
        return 199;
      case SubscriptionPlan.silverYearly:
        return 1990;
      case SubscriptionPlan.goldMonthly:
        return 499;
      case SubscriptionPlan.goldYearly:
        return 4990;
    }
  }

  int get biddingTokens {
    switch (this) {
      case SubscriptionPlan.free:
        return 10;
      case SubscriptionPlan.silverMonthly:
      case SubscriptionPlan.silverYearly:
        return 60;
      case SubscriptionPlan.goldMonthly:
      case SubscriptionPlan.goldYearly:
        return 250;
    }
  }

  int get listingTokens {
    switch (this) {
      case SubscriptionPlan.free:
        return 1;
      case SubscriptionPlan.silverMonthly:
      case SubscriptionPlan.silverYearly:
        return 3;
      case SubscriptionPlan.goldMonthly:
      case SubscriptionPlan.goldYearly:
        return 10;
    }
  }

  bool get includesAutoBid {
    switch (this) {
      case SubscriptionPlan.goldMonthly:
      case SubscriptionPlan.goldYearly:
        return true;
      case SubscriptionPlan.free:
      case SubscriptionPlan.silverMonthly:
      case SubscriptionPlan.silverYearly:
        return false;
    }
  }

  bool get isYearly {
    return this == SubscriptionPlan.silverYearly ||
        this == SubscriptionPlan.goldYearly;
  }

  String toJson() {
    switch (this) {
      case SubscriptionPlan.free:
        return 'free';
      case SubscriptionPlan.silverMonthly:
        return 'silver_monthly';
      case SubscriptionPlan.silverYearly:
        return 'silver_yearly';
      case SubscriptionPlan.goldMonthly:
        return 'gold_monthly';
      case SubscriptionPlan.goldYearly:
        return 'gold_yearly';
    }
  }

  static SubscriptionPlan fromJson(String value) {
    switch (value) {
      case 'free':
        return SubscriptionPlan.free;
      case 'silver_monthly':
      case 'pro_basic_monthly':
        return SubscriptionPlan.silverMonthly;
      case 'silver_yearly':
      case 'pro_basic_yearly':
        return SubscriptionPlan.silverYearly;
      case 'gold_monthly':
      case 'pro_plus_monthly':
        return SubscriptionPlan.goldMonthly;
      case 'gold_yearly':
      case 'pro_plus_yearly':
        return SubscriptionPlan.goldYearly;
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
