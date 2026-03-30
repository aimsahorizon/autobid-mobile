import 'package:flutter/foundation.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import 'package:autobid_mobile/modules/profile/data/datasources/virtual_wallet_datasource.dart';
import 'package:autobid_mobile/modules/profile/data/repositories/virtual_wallet_repository_impl.dart';
import 'package:autobid_mobile/modules/profile/domain/entities/virtual_wallet_entity.dart';
import 'package:autobid_mobile/modules/profile/domain/repositories/virtual_wallet_repository.dart';

/// Singleton service for virtual wallet operations throughout the app
class VirtualWalletService extends ChangeNotifier {
  static VirtualWalletService? _instance;
  static VirtualWalletService get instance =>
      _instance ??= VirtualWalletService._();

  VirtualWalletService._();

  /// For testing
  @visibleForTesting
  factory VirtualWalletService.withRepository(VirtualWalletRepository repo) {
    final service = VirtualWalletService._();
    service._repository = repo;
    return service;
  }

  VirtualWalletRepository? _repository;

  VirtualWalletRepository get _repo {
    _repository ??= VirtualWalletRepositoryImpl(
      datasource: VirtualWalletDatasource(SupabaseConfig.client),
    );
    return _repository!;
  }

  double _balance = 0;
  double get balance => _balance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Load wallet balance for user
  Future<double> loadBalance(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final wallet = await _repo.getOrCreateWallet(userId);
      _balance = wallet.balance;
      return _balance;
    } catch (e) {
      debugPrint('[VirtualWalletService] Error loading balance: $e');
      return _balance;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Pay from wallet (debit)
  Future<({bool success, String message, double newBalance})> pay({
    required String userId,
    required double amount,
    required WalletTransactionCategory category,
    String? referenceId,
    String? description,
  }) async {
    try {
      final result = await _repo.debit(
        userId: userId,
        amount: amount,
        category: category,
        referenceId: referenceId,
        description: description,
      );
      if (result.success) {
        _balance = result.newBalance;
        notifyListeners();
      }
      return result;
    } catch (e) {
      debugPrint('[VirtualWalletService] Error paying: $e');
      return (
        success: false,
        message: 'Payment failed: $e',
        newBalance: _balance,
      );
    }
  }

  /// Get transaction history
  Future<List<WalletTransactionEntity>> getTransactions(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) {
    return _repo.getTransactions(userId, limit: limit, offset: offset);
  }

  /// Top up wallet (credit)
  Future<({bool success, String message, double newBalance})> topUp({
    required String userId,
    required double amount,
  }) async {
    try {
      final result = await _repo.credit(
        userId: userId,
        amount: amount,
        category: WalletTransactionCategory.topUp,
        description: 'Wallet top up',
      );
      if (result.success) {
        _balance = result.newBalance;
        notifyListeners();
      }
      return result;
    } catch (e) {
      debugPrint('[VirtualWalletService] Error topping up: $e');
      return (
        success: false,
        message: 'Top up failed: $e',
        newBalance: _balance,
      );
    }
  }

  /// Withdraw from wallet (debit)
  Future<({bool success, String message, double newBalance})> withdraw({
    required String userId,
    required double amount,
  }) async {
    try {
      final result = await _repo.debit(
        userId: userId,
        amount: amount,
        category: WalletTransactionCategory.withdrawal,
        description: 'Wallet withdrawal',
      );
      if (result.success) {
        _balance = result.newBalance;
        notifyListeners();
      }
      return result;
    } catch (e) {
      debugPrint('[VirtualWalletService] Error withdrawing: $e');
      return (
        success: false,
        message: 'Withdrawal failed: $e',
        newBalance: _balance,
      );
    }
  }

  /// Return all deposits for an auction
  Future<void> returnAuctionDeposits(String auctionId) async {
    await _repo.returnAuctionDeposits(auctionId);
  }
}
