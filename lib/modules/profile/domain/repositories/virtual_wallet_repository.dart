import '../entities/virtual_wallet_entity.dart';

abstract class VirtualWalletRepository {
  Future<VirtualWalletEntity> getOrCreateWallet(String userId);

  Future<({bool success, String message, double newBalance})> debit({
    required String userId,
    required double amount,
    required WalletTransactionCategory category,
    String? referenceId,
    String? description,
  });

  Future<({bool success, String message, double newBalance})> credit({
    required String userId,
    required double amount,
    required WalletTransactionCategory category,
    String? referenceId,
    String? description,
  });

  Future<List<WalletTransactionEntity>> getTransactions(
    String userId, {
    int limit = 50,
    int offset = 0,
  });

  Future<void> returnAuctionDeposits(String auctionId);
}
