import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase datasource for auction deposit management
class DepositSupabaseDataSource {
  final SupabaseClient supabase;

  DepositSupabaseDataSource(this.supabase);

  /// Create deposit record after successful payment
  Future<String?> createDeposit({
    required String auctionId,
    required String userId,
    required double amount,
    required String paymentIntentId,
  }) async {
    try {
      debugPrint(
        '[DepositSupabaseDatasource] Creating deposit for auction: $auctionId, user: $userId, amount: $amount',
      );

      final response = await supabase.rpc(
        'create_deposit',
        params: {
          'p_auction_id': auctionId,
          'p_user_id': userId,
          'p_amount': amount,
          'p_payment_intent_id': paymentIntentId,
        },
      );

      debugPrint('[DepositSupabaseDatasource] Response: $response');

      // Handle response - could be a single row or a table
      if (response is List && response.isNotEmpty) {
        final result = response[0] as Map<String, dynamic>;
        final success = result['success'] as bool? ?? false;
        final message = result['message'] as String?;
        final depositId = result['deposit_id'] as String?;

        if (!success) {
          throw Exception('Failed to create deposit: $message');
        }

        debugPrint(
          '[DepositSupabaseDatasource] Deposit created successfully: $depositId',
        );
        return depositId;
      } else if (response is Map<String, dynamic>) {
        final success = response['success'] as bool? ?? false;
        final message = response['message'] as String?;
        final depositId = response['deposit_id'] as String?;

        if (!success) {
          throw Exception('Failed to create deposit: $message');
        }

        debugPrint(
          '[DepositSupabaseDatasource] Deposit created successfully: $depositId',
        );
        return depositId;
      } else {
        debugPrint(
          '[DepositSupabaseDatasource] Unexpected response type: ${response.runtimeType}',
        );
        throw Exception('Unexpected response from server');
      }
    } catch (e) {
      debugPrint('[DepositSupabaseDatasource] Error creating deposit: $e');
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
        params: {'p_auction_id': auctionId, 'p_user_id': userId},
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
        params: {'p_auction_id': auctionId, 'p_user_id': userId},
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
        params: {'p_auction_id': auctionId, 'p_user_id': userId},
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
        params: {'p_auction_id': auctionId, 'p_user_id': userId},
      );

      return response as bool;
    } catch (e) {
      return false;
    }
  }

  /// Process deposit payment for auction participation
  /// This is a simplified wrapper for the deposit creation flow
  Future<void> processDeposit(String auctionId) async {
    // This is a placeholder - actual implementation would involve
    // payment processing logic which should be handled separately
    // For now, this just validates that the method exists
    throw UnimplementedError(
      'processDeposit requires payment integration - use createDeposit with payment details',
    );
  }
}
