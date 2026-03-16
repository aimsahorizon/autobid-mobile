import 'package:flutter_test/flutter_test.dart';
import 'package:autobid_mobile/modules/profile/data/models/virtual_wallet_model.dart';
import 'package:autobid_mobile/modules/profile/domain/entities/virtual_wallet_entity.dart';

void main() {
  group('VirtualWalletModel', () {
    test('fromJson parses wallet_id key', () {
      final json = {
        'wallet_id': 'w-1',
        'user_id': 'u-1',
        'balance': 100000.0,
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-01T00:00:00.000Z',
      };

      final model = VirtualWalletModel.fromJson(json);

      expect(model.id, 'w-1');
      expect(model.userId, 'u-1');
      expect(model.balance, 100000.0);
    });

    test('fromJson falls back to id key', () {
      final json = {
        'id': 'w-2',
        'user_id': 'u-2',
        'balance': 50000,
        'created_at': '2025-06-01T12:00:00.000Z',
        'updated_at': '2025-06-01T12:00:00.000Z',
      };

      final model = VirtualWalletModel.fromJson(json);

      expect(model.id, 'w-2');
    });

    test('fromJson handles int balance', () {
      final json = {
        'id': 'w-3',
        'balance': 75000,
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-01T00:00:00.000Z',
      };

      final model = VirtualWalletModel.fromJson(json);

      expect(model.balance, 75000.0);
    });

    test('fromJson handles string balance', () {
      final json = {
        'id': 'w-4',
        'balance': '99999.99',
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-01T00:00:00.000Z',
      };

      final model = VirtualWalletModel.fromJson(json);

      expect(model.balance, 99999.99);
    });

    test('toEntity converts correctly', () {
      final json = {
        'wallet_id': 'w-1',
        'user_id': 'u-1',
        'balance': 100000.0,
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-01T00:00:00.000Z',
      };

      final entity = VirtualWalletModel.fromJson(json).toEntity();

      expect(entity, isA<VirtualWalletEntity>());
      expect(entity.id, 'w-1');
      expect(entity.balance, 100000.0);
    });
  });

  group('WalletTransactionModel', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 't-1',
        'amount': 5000.0,
        'type': 'debit',
        'category': 'deposit',
        'reference_id': 'auction-1',
        'description': 'Deposit for auction',
        'balance_after': 95000.0,
        'created_at': '2025-01-01T10:00:00.000Z',
      };

      final model = WalletTransactionModel.fromJson(json);

      expect(model.id, 't-1');
      expect(model.amount, 5000.0);
      expect(model.type, 'debit');
      expect(model.category, 'deposit');
      expect(model.referenceId, 'auction-1');
      expect(model.description, 'Deposit for auction');
      expect(model.balanceAfter, 95000.0);
    });

    test('fromJson handles nullable fields', () {
      final json = {
        'id': 't-2',
        'amount': 50000,
        'type': 'credit',
        'category': 'top_up',
        'reference_id': null,
        'description': null,
        'balance_after': 150000,
        'created_at': '2025-01-02T10:00:00.000Z',
      };

      final model = WalletTransactionModel.fromJson(json);

      expect(model.referenceId, isNull);
      expect(model.description, isNull);
    });

    test('toEntity maps credit type correctly', () {
      final json = {
        'id': 't-3',
        'amount': 5000.0,
        'type': 'credit',
        'category': 'deposit_return',
        'balance_after': 105000.0,
        'created_at': '2025-01-03T10:00:00.000Z',
      };

      final entity = WalletTransactionModel.fromJson(json).toEntity();

      expect(entity.type, WalletTransactionType.credit);
      expect(entity.category, WalletTransactionCategory.depositReturn);
    });

    test('toEntity maps debit type correctly', () {
      final json = {
        'id': 't-4',
        'amount': 2000.0,
        'type': 'debit',
        'category': 'token_purchase',
        'balance_after': 98000.0,
        'created_at': '2025-01-04T10:00:00.000Z',
      };

      final entity = WalletTransactionModel.fromJson(json).toEntity();

      expect(entity.type, WalletTransactionType.debit);
      expect(entity.category, WalletTransactionCategory.tokenPurchase);
    });
  });
}
