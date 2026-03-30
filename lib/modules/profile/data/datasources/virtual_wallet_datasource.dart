import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/virtual_wallet_model.dart';

class VirtualWalletDatasource {
  final SupabaseClient supabase;

  VirtualWalletDatasource(this.supabase);

  /// Get or create the user's wallet
  Future<VirtualWalletModel> getOrCreateWallet(String userId) async {
    try {
      final response = await supabase.rpc(
        'get_or_create_wallet',
        params: {'p_user_id': userId},
      );

      if (response is List && response.isNotEmpty) {
        final data = response[0] as Map<String, dynamic>;
        return VirtualWalletModel(
          id: data['wallet_id'] as String,
          userId: userId,
          balance: _toDouble(data['balance']),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      throw Exception('Failed to get wallet');
    } catch (e) {
      debugPrint('[VirtualWalletDatasource] Error getting wallet: $e');
      rethrow;
    }
  }

  /// Debit from wallet
  Future<
    ({bool success, String message, double newBalance, String? transactionId})
  >
  debit({
    required String userId,
    required double amount,
    required String category,
    String? referenceId,
    String? description,
  }) async {
    try {
      final response = await supabase.rpc(
        'wallet_debit',
        params: {
          'p_user_id': userId,
          'p_amount': amount,
          'p_category': category,
          'p_reference_id': referenceId,
          'p_description': description,
        },
      );

      if (response is List && response.isNotEmpty) {
        final data = response[0] as Map<String, dynamic>;
        return (
          success: data['success'] as bool? ?? false,
          message: data['message'] as String? ?? 'Unknown error',
          newBalance: _toDouble(data['new_balance']),
          transactionId: data['transaction_id'] as String?,
        );
      }

      throw Exception('Unexpected response from wallet_debit');
    } catch (e) {
      debugPrint('[VirtualWalletDatasource] Error debiting wallet: $e');
      rethrow;
    }
  }

  /// Credit to wallet
  Future<
    ({bool success, String message, double newBalance, String? transactionId})
  >
  credit({
    required String userId,
    required double amount,
    required String category,
    String? referenceId,
    String? description,
  }) async {
    try {
      final response = await supabase.rpc(
        'wallet_credit',
        params: {
          'p_user_id': userId,
          'p_amount': amount,
          'p_category': category,
          'p_reference_id': referenceId,
          'p_description': description,
        },
      );

      if (response is List && response.isNotEmpty) {
        final data = response[0] as Map<String, dynamic>;
        return (
          success: data['success'] as bool? ?? false,
          message: data['message'] as String? ?? 'Unknown error',
          newBalance: _toDouble(data['new_balance']),
          transactionId: data['transaction_id'] as String?,
        );
      }

      throw Exception('Unexpected response from wallet_credit');
    } catch (e) {
      debugPrint('[VirtualWalletDatasource] Error crediting wallet: $e');
      rethrow;
    }
  }

  /// Get transaction history
  Future<List<WalletTransactionModel>> getTransactions(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await supabase.rpc(
        'get_wallet_transactions',
        params: {'p_user_id': userId, 'p_limit': limit, 'p_offset': offset},
      );

      if (response is List) {
        return response
            .map(
              (e) => WalletTransactionModel.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('[VirtualWalletDatasource] Error getting transactions: $e');
      rethrow;
    }
  }

  /// Return deposits for an auction
  Future<void> returnAuctionDeposits(String auctionId) async {
    try {
      await supabase.rpc(
        'return_auction_deposits',
        params: {'p_auction_id': auctionId},
      );
    } catch (e) {
      debugPrint('[VirtualWalletDatasource] Error returning deposits: $e');
      rethrow;
    }
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
