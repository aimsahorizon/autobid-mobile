import 'package:flutter_test/flutter_test.dart';
import 'package:autobid_mobile/modules/profile/domain/entities/virtual_wallet_entity.dart';

void main() {
  group('VirtualWalletEntity', () {
    test('creates with correct properties', () {
      final now = DateTime.now();
      final wallet = VirtualWalletEntity(
        id: 'w-1',
        userId: 'u-1',
        balance: 100000.0,
        createdAt: now,
        updatedAt: now,
      );

      expect(wallet.id, 'w-1');
      expect(wallet.userId, 'u-1');
      expect(wallet.balance, 100000.0);
      expect(wallet.createdAt, now);
      expect(wallet.updatedAt, now);
    });
  });

  group('WalletTransactionEntity', () {
    test('creates credit transaction', () {
      final txn = WalletTransactionEntity(
        id: 't-1',
        amount: 5000.0,
        type: WalletTransactionType.credit,
        category: WalletTransactionCategory.depositReturn,
        referenceId: 'auction-1',
        description: 'Deposit returned',
        balanceAfter: 105000.0,
        createdAt: DateTime(2025, 1, 1),
      );

      expect(txn.type, WalletTransactionType.credit);
      expect(txn.category, WalletTransactionCategory.depositReturn);
      expect(txn.referenceId, 'auction-1');
      expect(txn.balanceAfter, 105000.0);
    });

    test('creates debit transaction with nullable fields', () {
      final txn = WalletTransactionEntity(
        id: 't-2',
        amount: 2000.0,
        type: WalletTransactionType.debit,
        category: WalletTransactionCategory.tokenPurchase,
        balanceAfter: 98000.0,
        createdAt: DateTime(2025, 1, 2),
      );

      expect(txn.referenceId, isNull);
      expect(txn.description, isNull);
      expect(txn.amount, 2000.0);
    });
  });

  group('WalletTransactionCategory', () {
    test('dbValue returns correct snake_case strings', () {
      expect(WalletTransactionCategory.deposit.dbValue, 'deposit');
      expect(WalletTransactionCategory.depositReturn.dbValue, 'deposit_return');
      expect(WalletTransactionCategory.tokenPurchase.dbValue, 'token_purchase');
      expect(WalletTransactionCategory.subscription.dbValue, 'subscription');
      expect(WalletTransactionCategory.topUp.dbValue, 'top_up');
      expect(WalletTransactionCategory.withdrawal.dbValue, 'withdrawal');
    });

    test('label returns human-readable strings', () {
      expect(WalletTransactionCategory.deposit.label, 'Auction Deposit');
      expect(WalletTransactionCategory.depositReturn.label, 'Deposit Return');
      expect(WalletTransactionCategory.tokenPurchase.label, 'Token Purchase');
      expect(WalletTransactionCategory.subscription.label, 'Subscription');
      expect(WalletTransactionCategory.topUp.label, 'Top Up');
      expect(WalletTransactionCategory.withdrawal.label, 'Withdrawal');
    });

    test('fromDb converts all snake_case values correctly', () {
      expect(
        WalletTransactionCategoryExt.fromDb('deposit'),
        WalletTransactionCategory.deposit,
      );
      expect(
        WalletTransactionCategoryExt.fromDb('deposit_return'),
        WalletTransactionCategory.depositReturn,
      );
      expect(
        WalletTransactionCategoryExt.fromDb('token_purchase'),
        WalletTransactionCategory.tokenPurchase,
      );
      expect(
        WalletTransactionCategoryExt.fromDb('subscription'),
        WalletTransactionCategory.subscription,
      );
      expect(
        WalletTransactionCategoryExt.fromDb('top_up'),
        WalletTransactionCategory.topUp,
      );
      expect(
        WalletTransactionCategoryExt.fromDb('withdrawal'),
        WalletTransactionCategory.withdrawal,
      );
    });

    test('fromDb defaults to topUp for unknown value', () {
      expect(
        WalletTransactionCategoryExt.fromDb('unknown'),
        WalletTransactionCategory.topUp,
      );
    });

    test('roundtrip dbValue -> fromDb', () {
      for (final cat in WalletTransactionCategory.values) {
        expect(WalletTransactionCategoryExt.fromDb(cat.dbValue), cat);
      }
    });
  });
}
