import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/pricing_entity.dart';
import '../models/pricing_model.dart';

/// Exception for subscription change failures
class SubscriptionChangeException implements Exception {
  final String code;
  final String? cooldownEndsAt;
  SubscriptionChangeException(this.code, {this.cooldownEndsAt});

  @override
  String toString() => 'SubscriptionChangeException: $code';
}

/// Supabase datasource for pricing and token management
class PricingSupabaseDatasource {
  final SupabaseClient supabase;

  static const int starterBiddingTokens = 10;
  static const int starterListingTokens = 1;

  PricingSupabaseDatasource({required this.supabase});

  Future<Map<String, dynamic>?> fetchTokenBalanceRow(String userId) {
    return supabase
        .from('user_token_balances')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
  }

  Future<Map<String, dynamic>> createStarterTokenBalance(String userId) {
    return supabase
        .from('user_token_balances')
        .upsert({
          'user_id': userId,
          'bidding_tokens': starterBiddingTokens,
          'listing_tokens': starterListingTokens,
        }, onConflict: 'user_id')
        .select()
        .single();
  }

  Future<Map<String, dynamic>?> fetchActiveSubscriptionRow(String userId) {
    return supabase
        .from('user_subscriptions')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .maybeSingle();
  }

  Future<Map<String, dynamic>> createFreeSubscription(String userId) {
    return supabase
        .from('user_subscriptions')
        .insert({
          'user_id': userId,
          'plan': SubscriptionPlan.free.toJson(),
          'is_active': true,
          'start_date': DateTime.now().toIso8601String(),
        })
        .select()
        .single();
  }

  Future<bool> callConsumeBiddingTokenRpc({
    required String userId,
    required String referenceId,
  }) async {
    final response = await supabase.rpc(
      'consume_bidding_token',
      params: {'p_user_id': userId, 'p_reference_id': referenceId},
    );

    return response as bool;
  }

  Future<bool> callConsumeListingTokenRpc({
    required String userId,
    required String referenceId,
  }) async {
    final response = await supabase.rpc(
      'consume_listing_token',
      params: {'p_user_id': userId, 'p_reference_id': referenceId},
    );

    return response as bool;
  }

  /// Get user's token balance
  Future<TokenBalanceModel> getTokenBalance(String userId) async {
    final response = await fetchTokenBalanceRow(userId);

    if (response == null) {
      final created = await createStarterTokenBalance(userId);
      return TokenBalanceModel.fromJson(created);
    }

    return TokenBalanceModel.fromJson(response);
  }

  /// Get user's subscription
  Future<UserSubscriptionModel> getUserSubscription(String userId) async {
    final response = await fetchActiveSubscriptionRow(userId);

    if (response == null) {
      try {
        final created = await createFreeSubscription(userId);
        return UserSubscriptionModel.fromJson(created);
      } catch (_) {
        // If another request created it concurrently, fetch the active row again.
        final retried = await fetchActiveSubscriptionRow(userId);
        if (retried != null) {
          return UserSubscriptionModel.fromJson(retried);
        }

        rethrow;
      }
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

  /// Change subscription via atomic RPC (handles tokens, cooldown, time)
  Future<UserSubscriptionModel> changeSubscription({
    required String userId,
    required String plan,
  }) async {
    final response = await supabase.rpc(
      'change_subscription',
      params: {'p_user_id': userId, 'p_new_plan': plan},
    );

    final result = Map<String, dynamic>.from(response as Map);
    if (result['success'] != true) {
      throw SubscriptionChangeException(
        result['error'] as String? ?? 'unknown',
        cooldownEndsAt: result['cooldown_ends_at'] as String?,
      );
    }

    final sub = Map<String, dynamic>.from(result['subscription'] as Map);
    return UserSubscriptionModel.fromJson(sub);
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
    await getTokenBalance(userId);
    return callConsumeBiddingTokenRpc(userId: userId, referenceId: referenceId);
  }

  /// Consume listing token using SQL function
  Future<bool> consumeListingToken({
    required String userId,
    required String referenceId,
  }) async {
    await getTokenBalance(userId);
    return callConsumeListingTokenRpc(userId: userId, referenceId: referenceId);
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
