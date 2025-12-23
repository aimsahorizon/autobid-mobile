import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/pricing_entity.dart';
import '../models/pricing_model.dart';

/// Supabase datasource for pricing and token management
class PricingSupabaseDatasource {
  final SupabaseClient supabase;

  PricingSupabaseDatasource({required this.supabase});

  /// Get user's token balance
  Future<TokenBalanceModel> getTokenBalance(String userId) async {
    final response = await supabase
        .from('user_token_balances')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      // Return default balance if no record found
      // This should be created by the database trigger, but return default as fallback
      return TokenBalanceModel(
        userId: userId,
        biddingTokens: 10,
        listingTokens: 1,
        updatedAt: DateTime.now(),
      );
    }

    return TokenBalanceModel.fromJson(response);
  }

  /// Get user's subscription
  Future<UserSubscriptionModel> getUserSubscription(String userId) async {
    final response = await supabase
        .from('user_subscriptions')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .maybeSingle();

    if (response == null) {
      // Return default free plan if no subscription found
      return UserSubscriptionModel(
        userId: userId,
        plan: SubscriptionPlan.free,
        isActive: true,
        startDate: DateTime.now(),
      );
    }

    return UserSubscriptionModel.fromJson(response);
  }

  /// Subscribe to a plan
  Future<UserSubscriptionModel> subscribeToPlan({
    required String userId,
    required String plan,
    required DateTime startDate,
    required DateTime? endDate,
  }) async {
    // Deactivate any existing active subscriptions
    await supabase
        .from('user_subscriptions')
        .update({'is_active': false})
        .eq('user_id', userId)
        .eq('is_active', true);

    // Create new subscription
    final response = await supabase
        .from('user_subscriptions')
        .insert({
          'user_id': userId,
          'plan': plan,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
          'is_active': true,
        })
        .select()
        .single();

    return UserSubscriptionModel.fromJson(response);
  }

  /// Cancel subscription
  Future<void> cancelSubscription(String userId) async {
    await supabase
        .from('user_subscriptions')
        .update({
          'is_active': false,
          'cancelled_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('is_active', true);
  }

  /// Consume bidding token using SQL function
  Future<bool> consumeBiddingToken({
    required String userId,
    required String referenceId,
  }) async {
    final response = await supabase.rpc(
      'consume_bidding_token',
      params: {
        'p_user_id': userId,
        'p_reference_id': referenceId,
      },
    );

    return response as bool;
  }

  /// Consume listing token using SQL function
  Future<bool> consumeListingToken({
    required String userId,
    required String referenceId,
  }) async {
    final response = await supabase.rpc(
      'consume_listing_token',
      params: {
        'p_user_id': userId,
        'p_reference_id': referenceId,
      },
    );

    return response as bool;
  }

  /// Add tokens using SQL function
  Future<bool> addTokens({
    required String userId,
    required String tokenType,
    required int amount,
    required double price,
    required String transactionType,
  }) async {
    final response = await supabase.rpc(
      'add_tokens',
      params: {
        'p_user_id': userId,
        'p_token_type': tokenType,
        'p_amount': amount,
        'p_price': price,
        'p_transaction_type': transactionType,
      },
    );

    return response as bool;
  }

  /// Get token transaction history
  Future<List<TokenTransactionModel>> getTransactionHistory({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await supabase
        .from('token_transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => TokenTransactionModel.fromJson(json))
        .toList();
  }
}
