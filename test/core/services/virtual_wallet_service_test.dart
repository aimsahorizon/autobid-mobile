import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:autobid_mobile/core/services/virtual_wallet_service.dart';
import 'package:autobid_mobile/modules/profile/domain/entities/virtual_wallet_entity.dart';
import 'package:autobid_mobile/modules/profile/domain/repositories/virtual_wallet_repository.dart';

class MockVirtualWalletRepository extends Mock
    implements VirtualWalletRepository {}

void main() {
  late VirtualWalletService service;
  late MockVirtualWalletRepository mockRepo;

  const testUserId = 'user-123';
  final testWallet = VirtualWalletEntity(
    id: 'w-1',
    userId: testUserId,
    balance: 100000.0,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );

  setUp(() {
    mockRepo = MockVirtualWalletRepository();
    service = VirtualWalletService.withRepository(mockRepo);
  });

  group('loadBalance', () {
    test('returns balance from repository', () async {
      when(
        () => mockRepo.getOrCreateWallet(testUserId),
      ).thenAnswer((_) async => testWallet);

      final balance = await service.loadBalance(testUserId);

      expect(balance, 100000.0);
      expect(service.balance, 100000.0);
      verify(() => mockRepo.getOrCreateWallet(testUserId)).called(1);
    });

    test('returns current balance on error', () async {
      when(
        () => mockRepo.getOrCreateWallet(testUserId),
      ).thenThrow(Exception('Network error'));

      final balance = await service.loadBalance(testUserId);

      expect(balance, 0.0); // default balance
    });
  });

  group('pay', () {
    test('deducts from wallet on success', () async {
      when(
        () => mockRepo.debit(
          userId: testUserId,
          amount: 5000.0,
          category: WalletTransactionCategory.deposit,
          referenceId: 'auction-1',
          description: 'Deposit payment',
        ),
      ).thenAnswer(
        (_) async =>
            (success: true, message: 'Payment successful', newBalance: 95000.0),
      );

      final result = await service.pay(
        userId: testUserId,
        amount: 5000.0,
        category: WalletTransactionCategory.deposit,
        referenceId: 'auction-1',
        description: 'Deposit payment',
      );

      expect(result.success, isTrue);
      expect(result.newBalance, 95000.0);
      expect(service.balance, 95000.0);
    });

    test('returns failure for insufficient balance', () async {
      when(
        () => mockRepo.debit(
          userId: testUserId,
          amount: 200000.0,
          category: WalletTransactionCategory.tokenPurchase,
          referenceId: null,
          description: null,
        ),
      ).thenAnswer(
        (_) async => (
          success: false,
          message: 'Insufficient wallet balance',
          newBalance: 100000.0,
        ),
      );

      final result = await service.pay(
        userId: testUserId,
        amount: 200000.0,
        category: WalletTransactionCategory.tokenPurchase,
      );

      expect(result.success, isFalse);
      expect(result.message, 'Insufficient wallet balance');
    });

    test('handles exception gracefully', () async {
      when(
        () => mockRepo.debit(
          userId: testUserId,
          amount: 5000.0,
          category: WalletTransactionCategory.deposit,
          referenceId: null,
          description: null,
        ),
      ).thenThrow(Exception('Server error'));

      final result = await service.pay(
        userId: testUserId,
        amount: 5000.0,
        category: WalletTransactionCategory.deposit,
      );

      expect(result.success, isFalse);
      expect(result.message, contains('Payment failed'));
    });
  });

  group('topUp', () {
    test('credits wallet on success', () async {
      when(
        () => mockRepo.credit(
          userId: testUserId,
          amount: 50000.0,
          category: WalletTransactionCategory.topUp,
          referenceId: null,
          description: 'Wallet top up',
        ),
      ).thenAnswer(
        (_) async =>
            (success: true, message: 'Credit successful', newBalance: 150000.0),
      );

      final result = await service.topUp(userId: testUserId, amount: 50000.0);

      expect(result.success, isTrue);
      expect(result.newBalance, 150000.0);
      expect(service.balance, 150000.0);
    });
  });

  group('withdraw', () {
    test('debits wallet on success', () async {
      when(
        () => mockRepo.debit(
          userId: testUserId,
          amount: 10000.0,
          category: WalletTransactionCategory.withdrawal,
          referenceId: null,
          description: 'Wallet withdrawal',
        ),
      ).thenAnswer(
        (_) async =>
            (success: true, message: 'Payment successful', newBalance: 90000.0),
      );

      final result = await service.withdraw(
        userId: testUserId,
        amount: 10000.0,
      );

      expect(result.success, isTrue);
      expect(result.newBalance, 90000.0);
      expect(service.balance, 90000.0);
    });
  });

  group('getTransactions', () {
    test('returns transaction list', () async {
      final transactions = [
        WalletTransactionEntity(
          id: 't-1',
          amount: 5000.0,
          type: WalletTransactionType.debit,
          category: WalletTransactionCategory.deposit,
          balanceAfter: 95000.0,
          createdAt: DateTime(2025, 1, 1),
        ),
        WalletTransactionEntity(
          id: 't-2',
          amount: 5000.0,
          type: WalletTransactionType.credit,
          category: WalletTransactionCategory.depositReturn,
          balanceAfter: 100000.0,
          createdAt: DateTime(2025, 1, 2),
        ),
      ];

      when(
        () => mockRepo.getTransactions(testUserId, limit: 50, offset: 0),
      ).thenAnswer((_) async => transactions);

      final result = await service.getTransactions(testUserId);

      expect(result.length, 2);
      expect(result[0].category, WalletTransactionCategory.deposit);
      expect(result[1].category, WalletTransactionCategory.depositReturn);
    });
  });

  group('returnAuctionDeposits', () {
    test('calls repository returnAuctionDeposits', () async {
      when(
        () => mockRepo.returnAuctionDeposits('auction-1'),
      ).thenAnswer((_) async {});

      await service.returnAuctionDeposits('auction-1');

      verify(() => mockRepo.returnAuctionDeposits('auction-1')).called(1);
    });
  });
}
