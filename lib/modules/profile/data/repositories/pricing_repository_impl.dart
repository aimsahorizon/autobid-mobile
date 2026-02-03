import 'package:autobid_mobile/core/network/network_info.dart';
import '../../domain/entities/pricing_entity.dart';
import '../../domain/repositories/pricing_repository.dart';
import '../datasources/pricing_supabase_datasource.dart';

/// Implementation of PricingRepository using Supabase
class PricingRepositoryImpl implements PricingRepository {
  final PricingSupabaseDatasource datasource;
  final NetworkInfo networkInfo;

  PricingRepositoryImpl({
    required this.datasource,
    required this.networkInfo,
  });

  @override
  Future<TokenBalanceEntity> getTokenBalance(String userId) async {
    if (!await networkInfo.isConnected) {
      throw Exception('No internet connection');
    }
    return await datasource.getTokenBalance(userId);
  }

  @override
  Future<UserSubscriptionEntity> getUserSubscription(String userId) async {
    if (!await networkInfo.isConnected) {
      throw Exception('No internet connection');
    }
    return await datasource.getUserSubscription(userId);
  }

  @override
  Future<List<TokenPackageEntity>> getTokenPackages() async {
    // Define token packages as per business requirements
    // This is static data, doesn't strictly need internet to display UI,
    // but purchase would need it.
    return [
      // ... (existing packages) ...
      // listing packages
      const TokenPackageEntity(
        id: 'bidding_small',
        type: TokenType.bidding,
        tokens: 5,
        bonusTokens: 0,
        price: 99,
        description: '5 Bidding Tokens',
      ),
      const TokenPackageEntity(
        id: 'bidding_medium',
        type: TokenType.bidding,
        tokens: 25,
        bonusTokens: 0,
        price: 349,
        description: '25 Bidding Tokens',
      ),
      const TokenPackageEntity(
        id: 'bidding_large',
        type: TokenType.bidding,
        tokens: 100,
        bonusTokens: 0,
        price: 1299,
        description: '100 Bidding Tokens',
      ),
      // Listing token packages
      const TokenPackageEntity(
        id: 'listing_small',
        type: TokenType.listing,
        tokens: 1,
        bonusTokens: 0,
        price: 199,
        description: '1 Listing Token',
      ),
      const TokenPackageEntity(
        id: 'listing_medium',
        type: TokenType.listing,
        tokens: 3,
        bonusTokens: 0,
        price: 499,
        description: '3 Listing Tokens',
      ),
      const TokenPackageEntity(
        id: 'listing_large',
        type: TokenType.listing,
        tokens: 10,
        bonusTokens: 0,
        price: 1499,
        description: '10 Listing Tokens',
      ),
    ];
  }

  @override
  Future<TokenBalanceEntity> purchaseTokenPackage({
    required String userId,
    required String packageId,
    required double amount,
  }) async {
    if (!await networkInfo.isConnected) {
      throw Exception('No internet connection');
    }
    // Get the package details
    final packages = await getTokenPackages();
    final package = packages.firstWhere((p) => p.id == packageId);

    // Add tokens using SQL function
    final tokenType = package.type == TokenType.bidding ? 'bidding' : 'listing';
    await datasource.addTokens(
      userId: userId,
      tokenType: tokenType,
      amount: package.totalTokens,
      price: amount,
      transactionType: 'purchase',
    );

    // Return updated balance
    return await datasource.getTokenBalance(userId);
  }

  @override
  Future<UserSubscriptionEntity> subscribeToPlan({
    required String userId,
    required SubscriptionPlan plan,
  }) async {
    if (!await networkInfo.isConnected) {
      throw Exception('No internet connection');
    }
    final now = DateTime.now();
    DateTime? endDate;

    // Calculate end date based on plan
    if (plan != SubscriptionPlan.free) {
      if (plan.isYearly) {
        endDate = now.add(const Duration(days: 365));
      } else {
        endDate = now.add(const Duration(days: 30));
      }
    }

    // Subscribe via datasource
    final subscription = await datasource.subscribeToPlan(
      userId: userId,
      plan: plan.toJson(),
      startDate: now,
      endDate: endDate,
    );

    // Add subscription tokens
    await datasource.addTokens(
      userId: userId,
      tokenType: 'bidding',
      amount: plan.biddingTokens,
      price: 0,
      transactionType: 'subscription',
    );

    await datasource.addTokens(
      userId: userId,
      tokenType: 'listing',
      amount: plan.listingTokens,
      price: 0,
      transactionType: 'subscription',
    );

    return subscription;
  }

  @override
  Future<void> cancelSubscription(String userId) async {
    if (!await networkInfo.isConnected) {
      throw Exception('No internet connection');
    }
    await datasource.cancelSubscription(userId);
  }

  @override
  Future<bool> consumeBiddingToken({
    required String userId,
    required String referenceId,
  }) async {
    if (!await networkInfo.isConnected) {
      throw Exception('No internet connection');
    }
    return await datasource.consumeBiddingToken(
      userId: userId,
      referenceId: referenceId,
    );
  }

  @override
  Future<bool> consumeListingToken({
    required String userId,
    required String referenceId,
  }) async {
    if (!await networkInfo.isConnected) {
      throw Exception('No internet connection');
    }
    return await datasource.consumeListingToken(
      userId: userId,
      referenceId: referenceId,
    );
  }

  @override
  Future<List<TokenTransactionEntity>> getTransactionHistory({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    if (!await networkInfo.isConnected) {
      throw Exception('No internet connection');
    }
    return await datasource.getTransactionHistory(
      userId: userId,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<bool> addTokens({
    required String userId,
    required TokenType type,
    required int amount,
    required double price,
    required String transactionType,
  }) async {
    if (!await networkInfo.isConnected) {
      throw Exception('No internet connection');
    }
    final tokenType = type == TokenType.bidding ? 'bidding' : 'listing';
    return await datasource.addTokens(
      userId: userId,
      tokenType: tokenType,
      amount: amount,
      price: price,
      transactionType: transactionType,
    );
  }
}
