import '../../domain/entities/virtual_wallet_entity.dart';
import '../../domain/repositories/virtual_wallet_repository.dart';
import '../datasources/virtual_wallet_datasource.dart';

class VirtualWalletRepositoryImpl implements VirtualWalletRepository {
  final VirtualWalletDatasource datasource;

  VirtualWalletRepositoryImpl({required this.datasource});

  @override
  Future<VirtualWalletEntity> getOrCreateWallet(String userId) async {
    final model = await datasource.getOrCreateWallet(userId);
    return model.toEntity();
  }

  @override
  Future<({bool success, String message, double newBalance})> debit({
    required String userId,
    required double amount,
    required WalletTransactionCategory category,
    String? referenceId,
    String? description,
  }) async {
    final result = await datasource.debit(
      userId: userId,
      amount: amount,
      category: category.dbValue,
      referenceId: referenceId,
      description: description,
    );
    return (
      success: result.success,
      message: result.message,
      newBalance: result.newBalance,
    );
  }

  @override
  Future<({bool success, String message, double newBalance})> credit({
    required String userId,
    required double amount,
    required WalletTransactionCategory category,
    String? referenceId,
    String? description,
  }) async {
    final result = await datasource.credit(
      userId: userId,
      amount: amount,
      category: category.dbValue,
      referenceId: referenceId,
      description: description,
    );
    return (
      success: result.success,
      message: result.message,
      newBalance: result.newBalance,
    );
  }

  @override
  Future<List<WalletTransactionEntity>> getTransactions(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final models = await datasource.getTransactions(
      userId,
      limit: limit,
      offset: offset,
    );
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> returnAuctionDeposits(String auctionId) async {
    await datasource.returnAuctionDeposits(auctionId);
  }
}
