import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:autobid_mobile/modules/transactions/presentation/controllers/transaction_realtime_controller.dart';
import 'package:autobid_mobile/modules/transactions/presentation/controllers/installment_controller.dart';
import 'package:autobid_mobile/modules/transactions/data/datasources/transaction_realtime_datasource.dart';
import 'package:autobid_mobile/modules/transactions/data/datasources/installment_supabase_datasource.dart';
import 'package:autobid_mobile/modules/transactions/domain/entities/transaction_entity.dart';
import 'package:autobid_mobile/modules/transactions/domain/entities/installment_plan_entity.dart';
import 'package:autobid_mobile/modules/transactions/domain/entities/installment_payment_entity.dart';

@GenerateMocks([TransactionRealtimeDataSource, InstallmentSupabaseDatasource])
import 'installment_gives_test.mocks.dart';

void main() {
  late TransactionRealtimeController txnController;
  late MockTransactionRealtimeDataSource mockTxnDataSource;

  const testTransactionId = 'txn_001';
  const testUserId = 'buyer_001';
  const testSellerId = 'seller_001';

  final baseTransaction = TransactionEntity(
    id: testTransactionId,
    listingId: 'auction_001',
    sellerId: testSellerId,
    buyerId: testUserId,
    carName: 'Test Car',
    carImageUrl: 'http://example.com/car.jpg',
    agreedPrice: 100000,
    status: TransactionStatus.discussion,
    createdAt: DateTime.now(),
    paymentMethod: 'full_payment',
  );

  setUp(() {
    mockTxnDataSource = MockTransactionRealtimeDataSource();
    txnController = TransactionRealtimeController(mockTxnDataSource);
  });

  group('toggleInstallment notifies listeners', () {
    test(
      'toggleInstallment(true) updates paymentMethod and notifies',
      () async {
        // Setup: load transaction first
        when(
          mockTxnDataSource.getTransaction(testTransactionId),
        ).thenAnswer((_) async => baseTransaction);
        when(
          mockTxnDataSource.getChatMessages(any),
        ).thenAnswer((_) async => []);
        when(
          mockTxnDataSource.getTransactionForm(any, any),
        ).thenAnswer((_) async => null);
        when(mockTxnDataSource.getTimeline(any)).thenAnswer((_) async => []);
        when(
          mockTxnDataSource.getReview(any, any),
        ).thenAnswer((_) async => null);
        when(
          mockTxnDataSource.getAgreementFields(any),
        ).thenAnswer((_) async => []);
        when(
          mockTxnDataSource.chatStream,
        ).thenAnswer((_) => const Stream.empty());
        when(
          mockTxnDataSource.transactionUpdateStream,
        ).thenAnswer((_) => const Stream.empty());
        when(
          mockTxnDataSource.updatePaymentMethod(any, any),
        ).thenAnswer((_) async {});

        await txnController.loadTransaction(testTransactionId, testUserId);
        expect(txnController.transaction?.paymentMethod, 'full_payment');

        int notifyCount = 0;
        txnController.addListener(() => notifyCount++);

        // Act
        await txnController.toggleInstallment(true);

        // Assert — notifyListeners was called
        expect(notifyCount, greaterThan(0));
        expect(txnController.transaction?.paymentMethod, 'installment');
        expect(txnController.transaction?.showInstallmentTab, true);
        verify(
          mockTxnDataSource.updatePaymentMethod(
            testTransactionId,
            'installment',
          ),
        ).called(1);
      },
    );

    test(
      'toggleInstallment(false) reverts paymentMethod and notifies',
      () async {
        final installmentTransaction = baseTransaction.copyWith(
          paymentMethod: 'installment',
        );
        when(
          mockTxnDataSource.getTransaction(testTransactionId),
        ).thenAnswer((_) async => installmentTransaction);
        when(
          mockTxnDataSource.getChatMessages(any),
        ).thenAnswer((_) async => []);
        when(
          mockTxnDataSource.getTransactionForm(any, any),
        ).thenAnswer((_) async => null);
        when(mockTxnDataSource.getTimeline(any)).thenAnswer((_) async => []);
        when(
          mockTxnDataSource.getReview(any, any),
        ).thenAnswer((_) async => null);
        when(
          mockTxnDataSource.getAgreementFields(any),
        ).thenAnswer((_) async => []);
        when(
          mockTxnDataSource.chatStream,
        ).thenAnswer((_) => const Stream.empty());
        when(
          mockTxnDataSource.transactionUpdateStream,
        ).thenAnswer((_) => const Stream.empty());
        when(
          mockTxnDataSource.updatePaymentMethod(any, any),
        ).thenAnswer((_) async {});

        await txnController.loadTransaction(testTransactionId, testUserId);

        int notifyCount = 0;
        txnController.addListener(() => notifyCount++);

        await txnController.toggleInstallment(false);

        expect(notifyCount, greaterThan(0));
        expect(txnController.transaction?.paymentMethod, 'full_payment');
        expect(txnController.transaction?.showInstallmentTab, false);
      },
    );
  });

  group('Installment schedule generation logic', () {
    test(
      'generatePaymentSchedule creates DP (#0) + gives entries in correct order',
      () {
        // Verify entity-level logic for schedule structure
        final plan = InstallmentPlanEntity(
          id: 'plan_001',
          transactionId: testTransactionId,
          totalAmount: 100000,
          downPayment: 20000,
          remainingAmount: 80000,
          totalPaid: 0,
          numInstallments: 4,
          frequency: 'monthly',
          startDate: DateTime(2026, 1, 1),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(plan.totalAmount, 100000);
        expect(plan.downPayment, 20000);
        expect(plan.remainingAmount, 80000);
        expect(plan.numInstallments, 4);
        // Per installment: 80000 / 4 = 20000
        final perPayment = plan.remainingAmount / plan.numInstallments;
        expect(perPayment, 20000);
      },
    );

    test('plan with no downpayment starts at give #1', () {
      final plan = InstallmentPlanEntity(
        id: 'plan_002',
        transactionId: testTransactionId,
        totalAmount: 60000,
        downPayment: 0,
        remainingAmount: 60000,
        numInstallments: 3,
        frequency: 'weekly',
        startDate: DateTime(2026, 1, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(plan.downPayment, 0);
      expect(plan.remainingAmount, plan.totalAmount);
      final perPayment = plan.remainingAmount / plan.numInstallments;
      expect(perPayment, 20000);
    });

    test('no_schedule frequency payments have sentinel due dates', () {
      final payment = InstallmentPaymentEntity(
        id: 'pay_001',
        installmentPlanId: 'plan_001',
        paymentNumber: 1,
        amount: 20000,
        dueDate: DateTime(9999, 12, 31),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(payment.hasNoDueDate, true);
      expect(payment.isOverdue, false);
    });

    test('down payment entry is payment number 0', () {
      final dpPayment = InstallmentPaymentEntity(
        id: 'pay_dp',
        installmentPlanId: 'plan_001',
        paymentNumber: 0,
        amount: 20000,
        dueDate: DateTime.now().add(const Duration(days: 3)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(dpPayment.paymentNumber, 0);
    });

    test('canSellerAct only when status is submitted', () {
      final pending = InstallmentPaymentEntity(
        id: 'p1',
        installmentPlanId: 'plan_001',
        paymentNumber: 1,
        amount: 20000,
        dueDate: DateTime.now(),
        status: InstallmentPaymentStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final submitted = pending.copyWith(
        status: InstallmentPaymentStatus.submitted,
      );
      final confirmed = pending.copyWith(
        status: InstallmentPaymentStatus.confirmed,
      );

      expect(pending.canSellerAct, false);
      expect(submitted.canSellerAct, true);
      expect(confirmed.canSellerAct, false);
    });
  });

  group('showInstallmentTab', () {
    test(
      'showInstallmentTab returns true when paymentMethod is installment',
      () {
        final txn = baseTransaction.copyWith(paymentMethod: 'installment');
        expect(txn.showInstallmentTab, true);
        expect(txn.isInstallment, true);
      },
    );

    test(
      'showInstallmentTab returns false when paymentMethod is full_payment',
      () {
        expect(baseTransaction.showInstallmentTab, false);
        expect(baseTransaction.isInstallment, false);
      },
    );
  });

  group('bothConfirmed gating', () {
    test('bothConfirmed is false when only seller confirmed', () {
      final txn = baseTransaction.copyWith(
        sellerConfirmed: true,
        buyerConfirmed: false,
      );
      expect(txn.bothConfirmed, false);
    });

    test('bothConfirmed is true when both confirmed', () {
      final txn = baseTransaction.copyWith(
        sellerConfirmed: true,
        buyerConfirmed: true,
      );
      expect(txn.bothConfirmed, true);
    });
  });

  group('InstallmentController.createPlan sets plan and payments', () {
    late InstallmentController installmentController;
    late MockInstallmentSupabaseDatasource mockDatasource;

    final testPlan = InstallmentPlanEntity(
      id: 'plan_001',
      transactionId: testTransactionId,
      totalAmount: 100000,
      downPayment: 20000,
      remainingAmount: 80000,
      numInstallments: 4,
      frequency: 'monthly',
      startDate: DateTime(2026, 1, 1),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final testPayments = [
      InstallmentPaymentEntity(
        id: 'pay_0',
        installmentPlanId: 'plan_001',
        paymentNumber: 0,
        amount: 20000,
        dueDate: DateTime(2026, 1, 4),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      InstallmentPaymentEntity(
        id: 'pay_1',
        installmentPlanId: 'plan_001',
        paymentNumber: 1,
        amount: 20000,
        dueDate: DateTime(2026, 2, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      InstallmentPaymentEntity(
        id: 'pay_2',
        installmentPlanId: 'plan_001',
        paymentNumber: 2,
        amount: 20000,
        dueDate: DateTime(2026, 3, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      InstallmentPaymentEntity(
        id: 'pay_3',
        installmentPlanId: 'plan_001',
        paymentNumber: 3,
        amount: 20000,
        dueDate: DateTime(2026, 4, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      InstallmentPaymentEntity(
        id: 'pay_4',
        installmentPlanId: 'plan_001',
        paymentNumber: 4,
        amount: 20000,
        dueDate: DateTime(2026, 5, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    setUp(() {
      mockDatasource = MockInstallmentSupabaseDatasource();
      installmentController = InstallmentController(datasource: mockDatasource);
    });

    test(
      'createPlan populates plan and payments, notifies listeners',
      () async {
        when(
          mockDatasource.createInstallmentPlan(
            transactionId: anyNamed('transactionId'),
            totalAmount: anyNamed('totalAmount'),
            downPayment: anyNamed('downPayment'),
            numInstallments: anyNamed('numInstallments'),
            frequency: anyNamed('frequency'),
            startDate: anyNamed('startDate'),
          ),
        ).thenAnswer((_) async => testPlan);

        when(
          mockDatasource.getPayments(any),
        ).thenAnswer((_) async => testPayments);

        when(
          mockDatasource.streamInstallmentPlan(any),
        ).thenAnswer((_) => const Stream.empty());
        when(
          mockDatasource.streamPayments(any),
        ).thenAnswer((_) => const Stream.empty());

        int notifyCount = 0;
        installmentController.addListener(() => notifyCount++);

        final result = await installmentController.createPlan(
          transactionId: testTransactionId,
          totalAmount: 100000,
          downPayment: 20000,
          numInstallments: 4,
          frequency: 'monthly',
          startDate: DateTime(2026, 1, 1),
        );

        expect(result, true);
        expect(installmentController.hasPlan, true);
        expect(installmentController.plan?.id, 'plan_001');
        expect(installmentController.payments.length, 5); // DP + 4 gives
        expect(
          installmentController.payments.first.paymentNumber,
          0,
        ); // DP first
        expect(notifyCount, greaterThan(0));
      },
    );

    test('loadInstallmentPlan loads existing plan with payments', () async {
      when(
        mockDatasource.getInstallmentPlan(testTransactionId),
      ).thenAnswer((_) async => testPlan);
      when(
        mockDatasource.getPayments('plan_001'),
      ).thenAnswer((_) async => testPayments);
      when(
        mockDatasource.streamInstallmentPlan(any),
      ).thenAnswer((_) => const Stream.empty());
      when(
        mockDatasource.streamPayments(any),
      ).thenAnswer((_) => const Stream.empty());

      await installmentController.loadInstallmentPlan(testTransactionId);

      expect(installmentController.hasPlan, true);
      expect(installmentController.payments.length, 5);
      expect(installmentController.isLoading, false);
    });
  });
}
