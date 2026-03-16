/// Represents a user's virtual wallet
class VirtualWalletEntity {
  final String id;
  final String userId;
  final double balance;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VirtualWalletEntity({
    required this.id,
    required this.userId,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// Represents a single transaction in the virtual wallet
class WalletTransactionEntity {
  final String id;
  final double amount;
  final WalletTransactionType type;
  final WalletTransactionCategory category;
  final String? referenceId;
  final String? description;
  final double balanceAfter;
  final DateTime createdAt;

  const WalletTransactionEntity({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    this.referenceId,
    this.description,
    required this.balanceAfter,
    required this.createdAt,
  });
}

enum WalletTransactionType { credit, debit }

enum WalletTransactionCategory {
  deposit,
  depositReturn,
  tokenPurchase,
  subscription,
  topUp,
  withdrawal,
}

extension WalletTransactionCategoryExt on WalletTransactionCategory {
  String get dbValue {
    switch (this) {
      case WalletTransactionCategory.deposit:
        return 'deposit';
      case WalletTransactionCategory.depositReturn:
        return 'deposit_return';
      case WalletTransactionCategory.tokenPurchase:
        return 'token_purchase';
      case WalletTransactionCategory.subscription:
        return 'subscription';
      case WalletTransactionCategory.topUp:
        return 'top_up';
      case WalletTransactionCategory.withdrawal:
        return 'withdrawal';
    }
  }

  String get label {
    switch (this) {
      case WalletTransactionCategory.deposit:
        return 'Auction Deposit';
      case WalletTransactionCategory.depositReturn:
        return 'Deposit Return';
      case WalletTransactionCategory.tokenPurchase:
        return 'Token Purchase';
      case WalletTransactionCategory.subscription:
        return 'Subscription';
      case WalletTransactionCategory.topUp:
        return 'Top Up';
      case WalletTransactionCategory.withdrawal:
        return 'Withdrawal';
    }
  }

  static WalletTransactionCategory fromDb(String value) {
    switch (value) {
      case 'deposit':
        return WalletTransactionCategory.deposit;
      case 'deposit_return':
        return WalletTransactionCategory.depositReturn;
      case 'token_purchase':
        return WalletTransactionCategory.tokenPurchase;
      case 'subscription':
        return WalletTransactionCategory.subscription;
      case 'top_up':
        return WalletTransactionCategory.topUp;
      case 'withdrawal':
        return WalletTransactionCategory.withdrawal;
      default:
        return WalletTransactionCategory.topUp;
    }
  }
}
