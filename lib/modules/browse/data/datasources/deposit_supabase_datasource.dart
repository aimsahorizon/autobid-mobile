import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase datasource for auction deposit management
class DepositSupabaseDatasource {
  final SupabaseClient supabase;

  DepositSupabaseDatasource({required this.supabase});

  /// Create deposit record after successful payment
  Future<String?> createDeposit({
    required String auctionId,
    required String userId,
    required double amount,
    required String paymentIntentId,
  }) async {
    try {
      final response = await supabase.rpc(
        'create_deposit',
        params: {
          'p_auction_id': auctionId,
          'p_user_id': userId,
          'p_amount': amount,
          'p_payment_intent_id': paymentIntentId,
        },
      );

      return response as String?;
    } catch (e) {
      throw Exception('Failed to create deposit: $e');
    }
  }

  /// Check if user has deposited for an auction
  Future<bool> hasUserDeposited({
    required String auctionId,
    required String userId,
  }) async {
    try {
      final response = await supabase.rpc(
        'has_user_deposited',
        params: {
          'p_auction_id': auctionId,
          'p_user_id': userId,
        },
      );

      return response as bool;
    } catch (e) {
      return false;
    }
  }

  /// Get user's deposit for an auction
  Future<Map<String, dynamic>?> getUserDeposit({
    required String auctionId,
    required String userId,
  }) async {
    try {
      final response = await supabase.rpc(
        'get_user_deposit',
        params: {
          'p_auction_id': auctionId,
          'p_user_id': userId,
        },
      );

      if (response is List && response.isNotEmpty) {
        return response.first as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Refund deposit (when user doesn't win)
  Future<bool> refundDeposit({
    required String auctionId,
    required String userId,
  }) async {
    try {
      final response = await supabase.rpc(
        'refund_deposit',
        params: {
          'p_auction_id': auctionId,
          'p_user_id': userId,
        },
      );

      return response as bool;
    } catch (e) {
      return false;
    }
  }

  /// Forfeit deposit (when winner doesn't complete purchase)
  Future<bool> forfeitDeposit({
    required String auctionId,
    required String userId,
  }) async {
    try {
      final response = await supabase.rpc(
        'forfeit_deposit',
        params: {
          'p_auction_id': auctionId,
          'p_user_id': userId,
        },
      );

      return response as bool;
    } catch (e) {
      return false;
    }
  }
}
