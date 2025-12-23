import '../entities/pricing_entity.dart';

/// Repository interface for pricing and token management
abstract class PricingRepository {
  /// Get current user's token balance
  Future<TokenBalanceEntity> getTokenBalance(String userId);

  /// Get current user's subscription details
  Future<UserSubscriptionEntity> getUserSubscription(String userId);

  /// Get available token packages for purchase
  Future<List<TokenPackageEntity>> getTokenPackages();

  /// Purchase a token package
  /// Returns updated token balance
  Future<TokenBalanceEntity> purchaseTokenPackage({
    required String userId,
    required String packageId,
    required double amount,
  });

  /// Subscribe to a plan
  /// Returns subscription details
  Future<UserSubscriptionEntity> subscribeToPlan({
    required String userId,
    required SubscriptionPlan plan,
  });

  /// Cancel current subscription
  Future<void> cancelSubscription(String userId);

  /// Consume a bidding token
  /// Returns true if successful, false if insufficient tokens
  Future<bool> consumeBiddingToken({
    required String userId,
    required String referenceId,
  });

  /// Consume a listing token
  /// Returns true if successful, false if insufficient tokens
  Future<bool> consumeListingToken({
    required String userId,
    required String referenceId,
  });

  /// Get token transaction history
  Future<List<TokenTransactionEntity>> getTransactionHistory({
    required String userId,
    int limit = 50,
    int offset = 0,
  });

  /// Add tokens (for testing or admin purposes)
  Future<bool> addTokens({
    required String userId,
    required TokenType type,
    required int amount,
    required double price,
    required String transactionType,
  });
}
