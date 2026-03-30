import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:autobid_mobile/modules/transactions/presentation/controllers/installment_controller.dart';
import 'package:autobid_mobile/modules/transactions/presentation/controllers/transaction_realtime_controller.dart';
import 'package:autobid_mobile/modules/transactions/data/datasources/installment_supabase_datasource.dart';
import 'package:autobid_mobile/modules/transactions/data/datasources/transaction_realtime_datasource.dart';
import 'package:autobid_mobile/modules/transactions/domain/entities/transaction_entity.dart';
import 'package:autobid_mobile/modules/transactions/domain/entities/installment_plan_entity.dart';
import 'package:autobid_mobile/modules/transactions/domain/entities/installment_payment_entity.dart';
import 'package:autobid_mobile/modules/transactions/presentation/widgets/transaction_realtime/installment_tracker_tab.dart';

@GenerateMocks([InstallmentSupabaseDatasource, TransactionRealtimeDataSource])
import 'installment_tracker_widget_test.mocks.dart';

void main() {
  const testTransactionId = 'txn_001';
  const buyerId = 'buyer_001';
  const sellerId = 'seller_001';

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

  // Payments with one submitted (for seller action testing)
  final paymentsWithSubmitted = [
    testPayments[0].copyWith(status: InstallmentPaymentStatus.confirmed),
    testPayments[1].copyWith(status: InstallmentPaymentStatus.submitted),
    ...testPayments.sublist(2),
  ];

  late MockInstallmentSupabaseDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockInstallmentSupabaseDatasource();
  });

  /// Helper to create the controller pre-loaded with plan + payments
  Future<InstallmentController> buildController({
    List<InstallmentPaymentEntity>? payments,
  }) async {
    final controller = InstallmentController(datasource: mockDatasource);

    when(
      mockDatasource.getInstallmentPlan(testTransactionId),
    ).thenAnswer((_) async => testPlan);
    when(
      mockDatasource.getPayments('plan_001'),
    ).thenAnswer((_) async => payments ?? testPayments);
    when(
      mockDatasource.streamInstallmentPlan(any),
    ).thenAnswer((_) => const Stream.empty());
    when(
      mockDatasource.streamPayments(any),
    ).thenAnswer((_) => const Stream.empty());

    await controller.loadInstallmentPlan(testTransactionId);
    return controller;
  }

  Widget buildWidget({
    required InstallmentController controller,
    required FormRole role,
    required bool bothConfirmed,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 600,
          child: InstallmentTrackerTab(
            controller: controller,
            transactionId: testTransactionId,
            userId: role == FormRole.buyer ? buyerId : sellerId,
            userRole: role,
            bothConfirmed: bothConfirmed,
          ),
        ),
      ),
    );
  }

  group('Gives tab shows schedule after plan proposed', () {
    testWidgets('displays payment cards when plan has payments', (
      tester,
    ) async {
      final controller = await buildController();

      await tester.pumpWidget(
        buildWidget(
          controller: controller,
          role: FormRole.buyer,
          bothConfirmed: false,
        ),
      );
      await tester.pumpAndSettle();

      // Schedule entries should be visible
      expect(find.text('₱20000'), findsWidgets);
      expect(find.text('No gives scheduled'), findsNothing);
      // DP badge
      expect(find.text('DP'), findsOneWidget);
      // Give badges #1-#4
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('#3'), findsOneWidget);
      expect(find.text('#4'), findsOneWidget);
    });

    testWidgets('displays progress header with plan info', (tester) async {
      final controller = await buildController();

      await tester.pumpWidget(
        buildWidget(
          controller: controller,
          role: FormRole.buyer,
          bothConfirmed: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gives Progress'), findsOneWidget);
      expect(find.text('₱100000 total'), findsOneWidget);
      expect(find.text('4 gives'), findsOneWidget);
    });

    testWidgets('shows "No gives scheduled" when payments list is empty', (
      tester,
    ) async {
      final controller = InstallmentController(datasource: mockDatasource);

      when(
        mockDatasource.getInstallmentPlan(testTransactionId),
      ).thenAnswer((_) async => testPlan);
      when(mockDatasource.getPayments('plan_001')).thenAnswer((_) async => []);
      // Recovery also returns empty
      when(
        mockDatasource.generatePaymentSchedule(
          planId: anyNamed('planId'),
          downPayment: anyNamed('downPayment'),
          remaining: anyNamed('remaining'),
          numInstallments: anyNamed('numInstallments'),
          frequency: anyNamed('frequency'),
          startDate: anyNamed('startDate'),
        ),
      ).thenAnswer((_) async => []);
      when(
        mockDatasource.streamInstallmentPlan(any),
      ).thenAnswer((_) => const Stream.empty());
      when(
        mockDatasource.streamPayments(any),
      ).thenAnswer((_) => const Stream.empty());

      await controller.loadInstallmentPlan(testTransactionId);

      await tester.pumpWidget(
        buildWidget(
          controller: controller,
          role: FormRole.buyer,
          bothConfirmed: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No gives scheduled'), findsOneWidget);
    });

    testWidgets('shows no plan view when plan is null', (tester) async {
      final controller = InstallmentController(datasource: mockDatasource);

      when(
        mockDatasource.getInstallmentPlan(testTransactionId),
      ).thenAnswer((_) async => null);
      when(
        mockDatasource.streamInstallmentPlan(any),
      ).thenAnswer((_) => const Stream.empty());
      when(
        mockDatasource.streamPayments(any),
      ).thenAnswer((_) => const Stream.empty());

      await controller.loadInstallmentPlan(testTransactionId);

      await tester.pumpWidget(
        buildWidget(
          controller: controller,
          role: FormRole.buyer,
          bothConfirmed: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Gives Plan'), findsOneWidget);
    });
  });

  group('Gives tab inaccessible before both confirmed', () {
    testWidgets('pre-confirm banner shown when bothConfirmed=false', (
      tester,
    ) async {
      final controller = await buildController();

      await tester.pumpWidget(
        buildWidget(
          controller: controller,
          role: FormRole.buyer,
          bothConfirmed: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Lock and confirm the agreement to enable payment submissions.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('buyer action bar hidden when bothConfirmed=false', (
      tester,
    ) async {
      final controller = await buildController();

      await tester.pumpWidget(
        buildWidget(
          controller: controller,
          role: FormRole.buyer,
          bothConfirmed: false,
        ),
      );
      await tester.pumpAndSettle();

      // No "Log" button should appear
      expect(find.textContaining('Log Down Payment'), findsNothing);
      expect(find.textContaining('Log Give'), findsNothing);
    });

    testWidgets('seller confirm/reject hidden when bothConfirmed=false', (
      tester,
    ) async {
      final controller = await buildController(payments: paymentsWithSubmitted);

      await tester.pumpWidget(
        buildWidget(
          controller: controller,
          role: FormRole.seller,
          bothConfirmed: false,
        ),
      );
      await tester.pumpAndSettle();

      // Seller action buttons should not appear
      expect(find.text('Confirm'), findsNothing);
      expect(find.text('Reject'), findsNothing);
    });
  });

  group('Gives tab accessible after both confirmed', () {
    testWidgets('pre-confirm banner hidden when bothConfirmed=true', (
      tester,
    ) async {
      final controller = await buildController();

      await tester.pumpWidget(
        buildWidget(
          controller: controller,
          role: FormRole.buyer,
          bothConfirmed: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Lock and confirm the agreement to enable payment submissions.',
        ),
        findsNothing,
      );
    });

    testWidgets('buyer sees action bar when bothConfirmed=true', (
      tester,
    ) async {
      final controller = await buildController();

      await tester.pumpWidget(
        buildWidget(
          controller: controller,
          role: FormRole.buyer,
          bothConfirmed: true,
        ),
      );
      await tester.pumpAndSettle();

      // Buyer should see the "Log Down Payment" button (payment #0 is first pending)
      expect(find.textContaining('Log Down Payment'), findsOneWidget);
    });

    testWidgets('seller sees confirm/reject for submitted payment', (
      tester,
    ) async {
      final controller = await buildController(payments: paymentsWithSubmitted);

      await tester.pumpWidget(
        buildWidget(
          controller: controller,
          role: FormRole.seller,
          bothConfirmed: true,
        ),
      );
      await tester.pumpAndSettle();

      // Seller should see Confirm and Reject buttons for submitted payment
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
    });

    testWidgets('seller does NOT see action bar (buyer-only)', (tester) async {
      final controller = await buildController();

      await tester.pumpWidget(
        buildWidget(
          controller: controller,
          role: FormRole.seller,
          bothConfirmed: true,
        ),
      );
      await tester.pumpAndSettle();

      // Seller should not see Log buttons
      expect(find.textContaining('Log Down Payment'), findsNothing);
      expect(find.textContaining('Log Give'), findsNothing);
    });
  });

  group('Controller createPlan → Gives tab shows schedule', () {
    testWidgets('schedule appears immediately after createPlan', (
      tester,
    ) async {
      final controller = InstallmentController(datasource: mockDatasource);

      // Initially no plan
      when(
        mockDatasource.getInstallmentPlan(testTransactionId),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(
        buildWidget(
          controller: controller,
          role: FormRole.buyer,
          bothConfirmed: false,
        ),
      );

      // Load → shows "No Gives Plan"
      await controller.loadInstallmentPlan(testTransactionId);
      await tester.pumpAndSettle();
      expect(find.text('No Gives Plan'), findsOneWidget);

      // Now simulate createPlan
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
        mockDatasource.getPayments('plan_001'),
      ).thenAnswer((_) async => testPayments);
      when(
        mockDatasource.streamInstallmentPlan(any),
      ).thenAnswer((_) => const Stream.empty());
      when(
        mockDatasource.streamPayments(any),
      ).thenAnswer((_) => const Stream.empty());

      await controller.createPlan(
        transactionId: testTransactionId,
        totalAmount: 100000,
        downPayment: 20000,
        numInstallments: 4,
        frequency: 'monthly',
        startDate: DateTime(2026, 1, 1),
      );
      await tester.pumpAndSettle();

      // No Gives Plan should be gone, schedule visible
      expect(find.text('No Gives Plan'), findsNothing);
      expect(find.text('Gives Progress'), findsOneWidget);
      expect(find.text('DP'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('#3'), findsOneWidget);
      expect(find.text('#4'), findsOneWidget);
    });
  });

  // =========================================================================
  // Frequency variations
  // =========================================================================

  group('Frequency display labels', () {
    Future<InstallmentController> buildControllerWithPlan(
      InstallmentPlanEntity plan,
      List<InstallmentPaymentEntity> payments,
    ) async {
      final controller = InstallmentController(datasource: mockDatasource);
      when(
        mockDatasource.getInstallmentPlan(testTransactionId),
      ).thenAnswer((_) async => plan);
      when(
        mockDatasource.getPayments(plan.id),
      ).thenAnswer((_) async => payments);
      when(
        mockDatasource.streamInstallmentPlan(any),
      ).thenAnswer((_) => const Stream.empty());
      when(
        mockDatasource.streamPayments(any),
      ).thenAnswer((_) => const Stream.empty());
      await controller.loadInstallmentPlan(testTransactionId);
      return controller;
    }

    testWidgets('weekly frequency shows "Weekly" chip', (tester) async {
      final weeklyPlan = InstallmentPlanEntity(
        id: 'plan_weekly',
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
      final payments = List.generate(
        3,
        (i) => InstallmentPaymentEntity(
          id: 'pw_${i + 1}',
          installmentPlanId: 'plan_weekly',
          paymentNumber: i + 1,
          amount: 20000,
          dueDate: DateTime(2026, 1, 8 + 7 * i),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final controller = await buildControllerWithPlan(weeklyPlan, payments);
      await tester.pumpWidget(
        buildWidget(
          controller: controller,
          role: FormRole.buyer,
          bothConfirmed: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('3 gives'), findsOneWidget);
      // No DP badge
      expect(find.text('DP'), findsNothing);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('#3'), findsOneWidget);
    });

    testWidgets('bi-weekly frequency shows "Bi-weekly" chip', (tester) async {
      final biWeeklyPlan = InstallmentPlanEntity(
        id: 'plan_bw',
        transactionId: testTransactionId,
        totalAmount: 40000,
        downPayment: 10000,
        remainingAmount: 30000,
        numInstallments: 2,
        frequency: 'bi-weekly',
        startDate: DateTime(2026, 1, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final payments = [
        InstallmentPaymentEntity(
          id: 'pbw_0',
          installmentPlanId: 'plan_bw',
          paymentNumber: 0,
          amount: 10000,
          dueDate: DateTime(2026, 1, 4),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        InstallmentPaymentEntity(
          id: 'pbw_1',
          installmentPlanId: 'plan_bw',
          paymentNumber: 1,
          amount: 15000,
          dueDate: DateTime(2026, 1, 15),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        InstallmentPaymentEntity(
          id: 'pbw_2',
          installmentPlanId: 'plan_bw',
          paymentNumber: 2,
          amount: 15000,
          dueDate: DateTime(2026, 1, 29),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final controller = await buildControllerWithPlan(biWeeklyPlan, payments);
      await tester.pumpWidget(
        buildWidget(
          controller: controller,
          role: FormRole.buyer,
          bothConfirmed: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bi-weekly'), findsOneWidget);
      expect(find.text('2 gives'), findsOneWidget);
      expect(find.text('₱10000 down'), findsOneWidget);
      expect(find.text('DP'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
    });

    testWidgets('no_schedule frequency shows "Buyer\'s discretion" chip', (
      tester,
    ) async {
      final noSchedPlan = InstallmentPlanEntity(
        id: 'plan_ns',
        transactionId: testTransactionId,
        totalAmount: 50000,
        downPayment: 0,
        remainingAmount: 50000,
        numInstallments: 5,
        frequency: 'no_schedule',
        startDate: DateTime(2026, 1, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final payments = List.generate(
        5,
        (i) => InstallmentPaymentEntity(
          id: 'pns_${i + 1}',
          installmentPlanId: 'plan_ns',
          paymentNumber: i + 1,
          amount: 10000,
          dueDate: DateTime(9999, 12, 31), // sentinel
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final controller = await buildControllerWithPlan(noSchedPlan, payments);
      await tester.pumpWidget(
        buildWidget(
          controller: controller,
          role: FormRole.buyer,
          bothConfirmed: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Buyer's discretion"), findsOneWidget);
      expect(find.text('5 gives'), findsOneWidget);
      // Due dates should show buyer's discretion text
      expect(find.text("Due: Upon buyer's discretion"), findsNWidgets(5));
    });

    testWidgets('monthly frequency shows "Monthly" chip', (tester) async {
      final controller = await buildController();
      await tester.pumpWidget(
        buildWidget(
          controller: controller,
          role: FormRole.buyer,
          bothConfirmed: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Monthly'), findsOneWidget);
    });
  });

  // =========================================================================
  // Down payment variations
  // =========================================================================

  group('Down payment variations', () {
    Future<InstallmentController> buildWithPlan(
      InstallmentPlanEntity plan,
      List<InstallmentPaymentEntity> payments,
    ) async {
      final controller = InstallmentController(datasource: mockDatasource);
      when(
        mockDatasource.getInstallmentPlan(testTransactionId),
      ).thenAnswer((_) async => plan);
      when(
        mockDatasource.getPayments(plan.id),
      ).thenAnswer((_) async => payments);
      when(
        mockDatasource.streamInstallmentPlan(any),
      ).thenAnswer((_) => const Stream.empty());
      when(
        mockDatasource.streamPayments(any),
      ).thenAnswer((_) => const Stream.empty());
      await controller.loadInstallmentPlan(testTransactionId);
      return controller;
    }

    testWidgets('no downpayment: no DP badge, starts at #1', (tester) async {
      final plan = InstallmentPlanEntity(
        id: 'plan_nodp',
        transactionId: testTransactionId,
        totalAmount: 60000,
        downPayment: 0,
        remainingAmount: 60000,
        numInstallments: 3,
        frequency: 'monthly',
        startDate: DateTime(2026, 1, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final payments = List.generate(
        3,
        (i) => InstallmentPaymentEntity(
          id: 'pnd_${i + 1}',
          installmentPlanId: 'plan_nodp',
          paymentNumber: i + 1,
          amount: 20000,
          dueDate: DateTime(2026, 2 + i, 1),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final controller = await buildWithPlan(plan, payments);
      await tester.pumpWidget(
        buildWidget(
          controller: controller,
          role: FormRole.buyer,
          bothConfirmed: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DP'), findsNothing);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('#3'), findsOneWidget);
      // Down payment chip should not appear
      expect(find.textContaining('down'), findsNothing);
      // Buyer action bar shows "Log Give #1"
      expect(find.textContaining('Log Give #1'), findsOneWidget);
    });

    testWidgets(
      'with downpayment: DP badge first, buyer sees Log Down Payment',
      (tester) async {
        final controller = await buildController();
        await tester.pumpWidget(
          buildWidget(
            controller: controller,
            role: FormRole.buyer,
            bothConfirmed: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('DP'), findsOneWidget);
        expect(find.text('₱20000 down'), findsOneWidget);
        expect(find.textContaining('Log Down Payment'), findsOneWidget);
      },
    );
  });

  // =========================================================================
  // Installment count variations
  // =========================================================================

  group('Installment count variations', () {
    Future<InstallmentController> buildWithPlan(
      InstallmentPlanEntity plan,
      List<InstallmentPaymentEntity> payments,
    ) async {
      final controller = InstallmentController(datasource: mockDatasource);
      when(
        mockDatasource.getInstallmentPlan(testTransactionId),
      ).thenAnswer((_) async => plan);
      when(
        mockDatasource.getPayments(plan.id),
      ).thenAnswer((_) async => payments);
      when(
        mockDatasource.streamInstallmentPlan(any),
      ).thenAnswer((_) => const Stream.empty());
      when(
        mockDatasource.streamPayments(any),
      ).thenAnswer((_) => const Stream.empty());
      await controller.loadInstallmentPlan(testTransactionId);
      return controller;
    }

    testWidgets('single installment shows "1 gives"', (tester) async {
      final plan = InstallmentPlanEntity(
        id: 'plan_single',
        transactionId: testTransactionId,
        totalAmount: 50000,
        downPayment: 0,
        remainingAmount: 50000,
        numInstallments: 1,
        frequency: 'monthly',
        startDate: DateTime(2026, 1, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final payments = [
        InstallmentPaymentEntity(
          id: 'ps_1',
          installmentPlanId: 'plan_single',
          paymentNumber: 1,
          amount: 50000,
          dueDate: DateTime(2026, 2, 1),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final controller = await buildWithPlan(plan, payments);
      await tester.pumpWidget(
        buildWidget(
          controller: controller,
          role: FormRole.buyer,
          bothConfirmed: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 gives'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('₱50000'), findsWidgets);
    });

    testWidgets('large installment count (6) shows all cards', (tester) async {
      final plan = InstallmentPlanEntity(
        id: 'plan_large',
        transactionId: testTransactionId,
        totalAmount: 120000,
        downPayment: 0,
        remainingAmount: 120000,
        numInstallments: 6,
        frequency: 'weekly',
        startDate: DateTime(2026, 1, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final payments = List.generate(
        6,
        (i) => InstallmentPaymentEntity(
          id: 'pl_${i + 1}',
          installmentPlanId: 'plan_large',
          paymentNumber: i + 1,
          amount: 20000,
          dueDate: DateTime(2026, 1, 8 + 7 * i),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final controller = await buildWithPlan(plan, payments);
      await tester.pumpWidget(
        buildWidget(
          controller: controller,
          role: FormRole.buyer,
          bothConfirmed: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('6 gives'), findsOneWidget);
      // Verify card count in the list (some may need scrolling)
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('#3'), findsOneWidget);
      // Cards #4-#6 may be off-screen; verify total payment count via controller
      expect(controller.payments.length, 6);
    });
  });

  // =========================================================================
  // Payment status display
  // =========================================================================

  group('Payment status display', () {
    Future<InstallmentController> buildWithPayments(
      List<InstallmentPaymentEntity> payments,
    ) async {
      final controller = InstallmentController(datasource: mockDatasource);
      when(
        mockDatasource.getInstallmentPlan(testTransactionId),
      ).thenAnswer((_) async => testPlan);
      when(
        mockDatasource.getPayments('plan_001'),
      ).thenAnswer((_) async => payments);
      when(
        mockDatasource.streamInstallmentPlan(any),
      ).thenAnswer((_) => const Stream.empty());
      when(
        mockDatasource.streamPayments(any),
      ).thenAnswer((_) => const Stream.empty());
      await controller.loadInstallmentPlan(testTransactionId);
      return controller;
    }

    testWidgets('overdue payment shows (OVERDUE) text', (tester) async {
      final overduePayments = [
        InstallmentPaymentEntity(
          id: 'pov_0',
          installmentPlanId: 'plan_001',
          paymentNumber: 0,
          amount: 20000,
          dueDate: DateTime(2024, 1, 1), // past date
          status: InstallmentPaymentStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        // Use far-future dates so only the first one is overdue
        ...List.generate(
          4,
          (i) => InstallmentPaymentEntity(
            id: 'pov_${i + 1}',
            installmentPlanId: 'plan_001',
            paymentNumber: i + 1,
            amount: 20000,
            dueDate: DateTime(2028, i + 1, 1),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
      ];

      final controller = await buildWithPayments(overduePayments);
      await tester.pumpWidget(
        buildWidget(
          controller: controller,
          role: FormRole.buyer,
          bothConfirmed: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('(OVERDUE)'), findsOneWidget);
    });

    testWidgets('rejected payment shows rejection reason', (tester) async {
      final rejectedPayments = [
        InstallmentPaymentEntity(
          id: 'pr_0',
          installmentPlanId: 'plan_001',
          paymentNumber: 0,
          amount: 20000,
          dueDate: DateTime(2026, 1, 4),
          status: InstallmentPaymentStatus.rejected,
          rejectionReason: 'Blurry proof image',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ...testPayments.sublist(1),
      ];

      final controller = await buildWithPayments(rejectedPayments);
      await tester.pumpWidget(
        buildWidget(
          controller: controller,
          role: FormRole.buyer,
          bothConfirmed: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rejected: Blurry proof image'), findsOneWidget);
    });

    testWidgets('confirmed payment shows Confirmed status chip', (
      tester,
    ) async {
      final confirmedPayments = [
        InstallmentPaymentEntity(
          id: 'pc_0',
          installmentPlanId: 'plan_001',
          paymentNumber: 0,
          amount: 20000,
          dueDate: DateTime(2026, 1, 4),
          status: InstallmentPaymentStatus.confirmed,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ...testPayments.sublist(1),
      ];

      final controller = await buildWithPayments(confirmedPayments);
      await tester.pumpWidget(
        buildWidget(
          controller: controller,
          role: FormRole.buyer,
          bothConfirmed: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirmed'), findsOneWidget);
    });

    testWidgets('submitted payment shows Submitted status chip', (
      tester,
    ) async {
      final submittedPayments = [
        InstallmentPaymentEntity(
          id: 'psb_0',
          installmentPlanId: 'plan_001',
          paymentNumber: 0,
          amount: 20000,
          dueDate: DateTime(2026, 1, 4),
          status: InstallmentPaymentStatus.submitted,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ...testPayments.sublist(1),
      ];

      final controller = await buildWithPayments(submittedPayments);
      await tester.pumpWidget(
        buildWidget(
          controller: controller,
          role: FormRole.buyer,
          bothConfirmed: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Submitted'), findsOneWidget);
    });
  });

  // =========================================================================
  // Plan status display
  // =========================================================================

  group('Plan status display', () {
    testWidgets('active plan shows Active status label', (tester) async {
      final controller = await buildController();
      await tester.pumpWidget(
        buildWidget(
          controller: controller,
          role: FormRole.buyer,
          bothConfirmed: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('completed plan shows Completed status label', (tester) async {
      final completedPlan = InstallmentPlanEntity(
        id: 'plan_comp',
        transactionId: testTransactionId,
        totalAmount: 100000,
        downPayment: 20000,
        remainingAmount: 0,
        totalPaid: 100000,
        numInstallments: 4,
        frequency: 'monthly',
        startDate: DateTime(2026, 1, 1),
        status: InstallmentPlanStatus.completed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final allConfirmed = testPayments
          .map((p) => p.copyWith(status: InstallmentPaymentStatus.confirmed))
          .toList();

      final controller = InstallmentController(datasource: mockDatasource);
      when(
        mockDatasource.getInstallmentPlan(testTransactionId),
      ).thenAnswer((_) async => completedPlan);
      when(
        mockDatasource.getPayments('plan_comp'),
      ).thenAnswer((_) async => allConfirmed);
      when(
        mockDatasource.streamInstallmentPlan(any),
      ).thenAnswer((_) => const Stream.empty());
      when(
        mockDatasource.streamPayments(any),
      ).thenAnswer((_) => const Stream.empty());
      await controller.loadInstallmentPlan(testTransactionId);

      await tester.pumpWidget(
        buildWidget(
          controller: controller,
          role: FormRole.buyer,
          bothConfirmed: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Completed'), findsOneWidget);
    });
  });

  // =========================================================================
  // Progress header amounts
  // =========================================================================

  group('Progress header amounts', () {
    testWidgets(
      'shows correct total, paid, and remaining for partial progress',
      (tester) async {
        final partialPlan = InstallmentPlanEntity(
          id: 'plan_partial',
          transactionId: testTransactionId,
          totalAmount: 100000,
          downPayment: 20000,
          remainingAmount: 60000,
          totalPaid: 40000,
          numInstallments: 4,
          frequency: 'monthly',
          startDate: DateTime(2026, 1, 1),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final mixedPayments = [
          testPayments[0].copyWith(status: InstallmentPaymentStatus.confirmed),
          testPayments[1].copyWith(status: InstallmentPaymentStatus.confirmed),
          ...testPayments.sublist(2),
        ];

        final controller = InstallmentController(datasource: mockDatasource);
        when(
          mockDatasource.getInstallmentPlan(testTransactionId),
        ).thenAnswer((_) async => partialPlan);
        when(
          mockDatasource.getPayments('plan_partial'),
        ).thenAnswer((_) async => mixedPayments);
        when(
          mockDatasource.streamInstallmentPlan(any),
        ).thenAnswer((_) => const Stream.empty());
        when(
          mockDatasource.streamPayments(any),
        ).thenAnswer((_) => const Stream.empty());
        await controller.loadInstallmentPlan(testTransactionId);

        await tester.pumpWidget(
          buildWidget(
            controller: controller,
            role: FormRole.buyer,
            bothConfirmed: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('₱40000 paid'), findsOneWidget);
        expect(find.text('₱100000 total'), findsOneWidget);
        expect(find.text('₱60000 remaining'), findsOneWidget);
      },
    );
  });

  // =========================================================================
  // Buyer next action bar
  // =========================================================================

  group('Buyer next action bar', () {
    Future<InstallmentController> buildWithPayments(
      List<InstallmentPaymentEntity> payments,
    ) async {
      final controller = InstallmentController(datasource: mockDatasource);
      when(
        mockDatasource.getInstallmentPlan(testTransactionId),
      ).thenAnswer((_) async => testPlan);
      when(
        mockDatasource.getPayments('plan_001'),
      ).thenAnswer((_) async => payments);
      when(
        mockDatasource.streamInstallmentPlan(any),
      ).thenAnswer((_) => const Stream.empty());
      when(
        mockDatasource.streamPayments(any),
      ).thenAnswer((_) => const Stream.empty());
      await controller.loadInstallmentPlan(testTransactionId);
      return controller;
    }

    testWidgets('after DP confirmed, buyer sees "Log Give #1" as next action', (
      tester,
    ) async {
      final paymentsAfterDp = [
        testPayments[0].copyWith(status: InstallmentPaymentStatus.confirmed),
        ...testPayments.sublist(1),
      ];
      final controller = await buildWithPayments(paymentsAfterDp);
      await tester.pumpWidget(
        buildWidget(
          controller: controller,
          role: FormRole.buyer,
          bothConfirmed: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Log Give #1'), findsOneWidget);
    });

    testWidgets('rejected payment becomes next pending so buyer can resubmit', (
      tester,
    ) async {
      final paymentsWithRejected = [
        testPayments[0].copyWith(status: InstallmentPaymentStatus.rejected),
        ...testPayments.sublist(1),
      ];
      final controller = await buildWithPayments(paymentsWithRejected);
      await tester.pumpWidget(
        buildWidget(
          controller: controller,
          role: FormRole.buyer,
          bothConfirmed: true,
        ),
      );
      await tester.pumpAndSettle();

      // Rejected DP becomes next pending → buyer can re-submit
      expect(find.textContaining('Log Down Payment'), findsOneWidget);
    });

    testWidgets('no action bar when all payments confirmed', (tester) async {
      final allConfirmed = testPayments
          .map((p) => p.copyWith(status: InstallmentPaymentStatus.confirmed))
          .toList();
      final controller = await buildWithPayments(allConfirmed);
      await tester.pumpWidget(
        buildWidget(
          controller: controller,
          role: FormRole.buyer,
          bothConfirmed: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Log'), findsNothing);
    });
  });
}
