import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/transactions/presentation/controllers/transaction_controller.dart';
import 'package:autobid_mobile/modules/transactions/domain/usecases/get_transaction_usecases.dart';
import 'package:autobid_mobile/modules/transactions/domain/usecases/manage_transaction_usecases.dart';
import 'package:autobid_mobile/modules/transactions/domain/entities/transaction_entity.dart';
import 'package:autobid_mobile/core/error/failures.dart';

class MockGetTransactionUseCase extends Mock implements GetTransactionUseCase {}

class MockGetChatMessagesUseCase extends Mock
    implements GetChatMessagesUseCase {}

class MockGetTransactionFormUseCase extends Mock
    implements GetTransactionFormUseCase {}

class MockGetTimelineUseCase extends Mock implements GetTimelineUseCase {}

class MockSendMessageUseCase extends Mock implements SendMessageUseCase {}

class MockSubmitFormUseCase extends Mock implements SubmitFormUseCase {}

class MockConfirmFormUseCase extends Mock implements ConfirmFormUseCase {}

class MockSubmitToAdminUseCase extends Mock implements SubmitToAdminUseCase {}

class MockUpdateDeliveryStatusUseCase extends Mock
    implements UpdateDeliveryStatusUseCase {}

class MockAcceptVehicleUseCase extends Mock implements AcceptVehicleUseCase {}

class MockRejectVehicleUseCase extends Mock implements RejectVehicleUseCase {}

class FakeTransactionFormEntity extends Fake implements TransactionFormEntity {}

void main() {
  late TransactionController controller;
  late MockGetTransactionUseCase mockGetTransactionUseCase;
  late MockGetChatMessagesUseCase mockGetChatMessagesUseCase;
  late MockGetTransactionFormUseCase mockGetTransactionFormUseCase;
  late MockGetTimelineUseCase mockGetTimelineUseCase;
  late MockSendMessageUseCase mockSendMessageUseCase;
  late MockSubmitFormUseCase mockSubmitFormUseCase;
  late MockConfirmFormUseCase mockConfirmFormUseCase;
  late MockSubmitToAdminUseCase mockSubmitToAdminUseCase;
  late MockUpdateDeliveryStatusUseCase mockUpdateDeliveryStatusUseCase;
  late MockAcceptVehicleUseCase mockAcceptVehicleUseCase;
  late MockRejectVehicleUseCase mockRejectVehicleUseCase;

  setUpAll(() {
    registerFallbackValue(FakeTransactionFormEntity());
    registerFallbackValue(FormRole.seller);
    registerFallbackValue(DeliveryStatus.pending);
  });

  setUp(() {
    mockGetTransactionUseCase = MockGetTransactionUseCase();
    mockGetChatMessagesUseCase = MockGetChatMessagesUseCase();
    mockGetTransactionFormUseCase = MockGetTransactionFormUseCase();
    mockGetTimelineUseCase = MockGetTimelineUseCase();
    mockSendMessageUseCase = MockSendMessageUseCase();
    mockSubmitFormUseCase = MockSubmitFormUseCase();
    mockConfirmFormUseCase = MockConfirmFormUseCase();
    mockSubmitToAdminUseCase = MockSubmitToAdminUseCase();
    mockUpdateDeliveryStatusUseCase = MockUpdateDeliveryStatusUseCase();
    mockAcceptVehicleUseCase = MockAcceptVehicleUseCase();
    mockRejectVehicleUseCase = MockRejectVehicleUseCase();

    controller = TransactionController(
      getTransactionUseCase: mockGetTransactionUseCase,
      getChatMessagesUseCase: mockGetChatMessagesUseCase,
      getTransactionFormUseCase: mockGetTransactionFormUseCase,
      getTimelineUseCase: mockGetTimelineUseCase,
      sendMessageUseCase: mockSendMessageUseCase,
      submitFormUseCase: mockSubmitFormUseCase,
      confirmFormUseCase: mockConfirmFormUseCase,
      submitToAdminUseCase: mockSubmitToAdminUseCase,
      updateDeliveryStatusUseCase: mockUpdateDeliveryStatusUseCase,
      acceptVehicleUseCase: mockAcceptVehicleUseCase,
      rejectVehicleUseCase: mockRejectVehicleUseCase,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  final testTransaction = TransactionEntity(
    id: 'transaction-123',
    listingId: 'listing-123',
    sellerId: 'seller-123',
    buyerId: 'buyer-123',
    carName: '2020 Toyota Supra',
    carImageUrl: 'https://example.com/car.jpg',
    agreedPrice: 50000,
    status: TransactionStatus.discussion,
    createdAt: DateTime.now(),
    sellerFormSubmitted: true,
    buyerFormSubmitted: true,
    sellerConfirmed: true,
    buyerConfirmed: true,
  );

  final testChatMessage = ChatMessageEntity(
    id: 'msg-1',
    transactionId: 'transaction-123',
    senderId: 'seller-123',
    senderName: 'Seller Name',
    message: 'Hello buyer',
    timestamp: DateTime.now(),
  );

  final testForm = TransactionFormEntity(
    id: 'form-1',
    transactionId: 'transaction-123',
    role: FormRole.seller,
    status: FormStatus.submitted,
    submittedAt: DateTime.now(),
    preferredDate: DateTime.now().add(const Duration(days: 7)),
    contactNumber: '+1234567890',
  );

  final testTimeline = TransactionTimelineEntity(
    id: 'timeline-1',
    transactionId: 'transaction-123',
    title: 'Transaction started',
    description: 'Transaction has been created and is now in discussion phase',
    timestamp: DateTime.now(),
    type: TimelineEventType.created,
  );

  group('Initial State', () {
    test('should have correct initial values', () {
      expect(controller.transaction, isNull);
      expect(controller.chatMessages, isEmpty);
      expect(controller.myForm, isNull);
      expect(controller.otherPartyForm, isNull);
      expect(controller.timeline, isEmpty);
      expect(controller.isLoading, false);
      expect(controller.isProcessing, false);
      expect(controller.errorMessage, isNull);
      expect(controller.hasError, false);
    });
  });

  group('getUserRole', () {
    test('should return seller role for seller user', () async {
      // Arrange - Set transaction
      when(
        () => mockGetTransactionUseCase.call(any()),
      ).thenAnswer((_) async => Right(testTransaction));
      when(
        () => mockGetChatMessagesUseCase.call(any()),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => mockGetTransactionFormUseCase.call(any(), any()),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockGetTimelineUseCase.call(any()),
      ).thenAnswer((_) async => const Right([]));

      await controller.loadTransaction('transaction-123', 'seller-123');

      // Act
      final role = controller.getUserRole('seller-123');

      // Assert
      expect(role, FormRole.seller);
    });

    test('should return buyer role for buyer user', () async {
      // Arrange
      when(
        () => mockGetTransactionUseCase.call(any()),
      ).thenAnswer((_) async => Right(testTransaction));
      when(
        () => mockGetChatMessagesUseCase.call(any()),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => mockGetTransactionFormUseCase.call(any(), any()),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockGetTimelineUseCase.call(any()),
      ).thenAnswer((_) async => const Right([]));

      await controller.loadTransaction('transaction-123', 'buyer-123');

      // Act
      final role = controller.getUserRole('buyer-123');

      // Assert
      expect(role, FormRole.buyer);
    });
  });

  group('loadTransaction', () {
    test('should load transaction and all related data successfully', () async {
      // Arrange
      when(
        () => mockGetTransactionUseCase.call(any()),
      ).thenAnswer((_) async => Right(testTransaction));
      when(
        () => mockGetChatMessagesUseCase.call(any()),
      ).thenAnswer((_) async => Right([testChatMessage]));
      when(
        () => mockGetTransactionFormUseCase.call(any(), any()),
      ).thenAnswer((_) async => Right(testForm));
      when(
        () => mockGetTimelineUseCase.call(any()),
      ).thenAnswer((_) async => Right([testTimeline]));

      // Act
      await controller.loadTransaction('transaction-123', 'seller-123');

      // Assert
      expect(controller.transaction, testTransaction);
      expect(controller.chatMessages, [testChatMessage]);
      expect(controller.myForm, testForm);
      expect(controller.otherPartyForm, testForm);
      expect(controller.timeline, [testTimeline]);
      expect(controller.isLoading, false);
      expect(controller.errorMessage, isNull);

      verify(() => mockGetTransactionUseCase.call('transaction-123')).called(1);
      verify(
        () => mockGetChatMessagesUseCase.call('transaction-123'),
      ).called(1);
      verify(
        () => mockGetTransactionFormUseCase.call('transaction-123', any()),
      ).called(2);
      verify(() => mockGetTimelineUseCase.call('transaction-123')).called(1);
    });

    test('should handle ServerFailure when loading transaction', () async {
      // Arrange
      when(() => mockGetTransactionUseCase.call(any())).thenAnswer(
        (_) async => Left(ServerFailure('Failed to load transaction')),
      );

      // Act
      await controller.loadTransaction('transaction-123', 'seller-123');

      // Assert
      expect(controller.errorMessage, 'Failed to load transaction');
      expect(controller.isLoading, false);
      expect(controller.transaction, isNull);
    });

    test('should handle null transaction', () async {
      // Arrange
      when(
        () => mockGetTransactionUseCase.call(any()),
      ).thenAnswer((_) async => const Right(null));

      // Act
      await controller.loadTransaction('transaction-123', 'seller-123');

      // Assert
      expect(controller.errorMessage, 'Transaction not found');
      expect(controller.isLoading, false);
    });

    test('should set loading state during load', () async {
      // Arrange
      when(() => mockGetTransactionUseCase.call(any())).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return Right(testTransaction);
      });
      when(
        () => mockGetChatMessagesUseCase.call(any()),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => mockGetTransactionFormUseCase.call(any(), any()),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockGetTimelineUseCase.call(any()),
      ).thenAnswer((_) async => const Right([]));

      // Act
      final future = controller.loadTransaction(
        'transaction-123',
        'seller-123',
      );
      await Future.delayed(const Duration(milliseconds: 5));

      // Assert - During loading
      expect(controller.isLoading, true);

      // Wait for completion
      await future;
      expect(controller.isLoading, false);
    });

    test('should handle exception during load', () async {
      // Arrange
      when(
        () => mockGetTransactionUseCase.call(any()),
      ).thenThrow(Exception('Unexpected error'));

      // Act
      await controller.loadTransaction('transaction-123', 'seller-123');

      // Assert
      expect(controller.errorMessage, contains('Failed to load transaction'));
      expect(controller.isLoading, false);
    });
  });

  group('sendMessage', () {
    setUp(() async {
      when(
        () => mockGetTransactionUseCase.call(any()),
      ).thenAnswer((_) async => Right(testTransaction));
      when(
        () => mockGetChatMessagesUseCase.call(any()),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => mockGetTransactionFormUseCase.call(any(), any()),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockGetTimelineUseCase.call(any()),
      ).thenAnswer((_) async => const Right([]));
      await controller.loadTransaction('transaction-123', 'seller-123');
    });

    test('should send message successfully', () async {
      // Arrange
      when(
        () => mockSendMessageUseCase.call(any(), any(), any(), any()),
      ).thenAnswer((_) async => const Right(true));

      // Act
      await controller.sendMessage('seller-123', 'Seller Name', 'Hello buyer');

      // Assert
      expect(controller.isProcessing, false);
      expect(controller.errorMessage, isNull);

      verify(
        () => mockSendMessageUseCase.call(
          'transaction-123',
          'seller-123',
          'Seller Name',
          'Hello buyer',
        ),
      ).called(1);
    });

    test('should not send empty message', () async {
      // Act
      await controller.sendMessage('seller-123', 'Seller Name', '   ');

      // Assert
      verifyNever(
        () => mockSendMessageUseCase.call(any(), any(), any(), any()),
      );
    });

    test('should handle ServerFailure when sending message', () async {
      // Arrange
      when(
        () => mockSendMessageUseCase.call(any(), any(), any(), any()),
      ).thenAnswer((_) async => Left(ServerFailure('Failed to send message')));

      // Act
      await controller.sendMessage('seller-123', 'Seller Name', 'Hello');

      // Assert
      expect(controller.errorMessage, 'Failed to send message');
      expect(controller.isProcessing, false);
    });

    test('should handle exception when sending message', () async {
      // Arrange
      when(
        () => mockSendMessageUseCase.call(any(), any(), any(), any()),
      ).thenThrow(Exception('Unexpected error'));

      // Act
      await controller.sendMessage('seller-123', 'Seller Name', 'Hello');

      // Assert
      expect(controller.errorMessage, 'Failed to send message');
      expect(controller.isProcessing, false);
    });
  });

  group('submitForm', () {
    setUp(() async {
      when(
        () => mockGetTransactionUseCase.call(any()),
      ).thenAnswer((_) async => Right(testTransaction));
      when(
        () => mockGetChatMessagesUseCase.call(any()),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => mockGetTransactionFormUseCase.call(any(), any()),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockGetTimelineUseCase.call(any()),
      ).thenAnswer((_) async => const Right([]));
      await controller.loadTransaction('transaction-123', 'seller-123');
    });

    test('should submit form successfully', () async {
      // Arrange
      when(
        () => mockSubmitFormUseCase.call(any()),
      ).thenAnswer((_) async => const Right(true));

      // Act
      final result = await controller.submitForm(testForm);

      // Assert
      expect(result, true);
      expect(controller.isProcessing, false);

      verify(() => mockSubmitFormUseCase.call(testForm)).called(1);
    });

    test('should return false when transaction is null', () async {
      // Arrange - Create controller without loading transaction
      final freshController = TransactionController(
        getTransactionUseCase: mockGetTransactionUseCase,
        getChatMessagesUseCase: mockGetChatMessagesUseCase,
        getTransactionFormUseCase: mockGetTransactionFormUseCase,
        getTimelineUseCase: mockGetTimelineUseCase,
        sendMessageUseCase: mockSendMessageUseCase,
        submitFormUseCase: mockSubmitFormUseCase,
        confirmFormUseCase: mockConfirmFormUseCase,
        submitToAdminUseCase: mockSubmitToAdminUseCase,
        updateDeliveryStatusUseCase: mockUpdateDeliveryStatusUseCase,
        acceptVehicleUseCase: mockAcceptVehicleUseCase,
        rejectVehicleUseCase: mockRejectVehicleUseCase,
      );

      // Act
      final result = await freshController.submitForm(testForm);

      // Assert
      expect(result, false);
      verifyNever(() => mockSubmitFormUseCase.call(any()));

      freshController.dispose();
    });

    test('should handle ServerFailure when submitting form', () async {
      // Arrange
      when(
        () => mockSubmitFormUseCase.call(any()),
      ).thenAnswer((_) async => Left(ServerFailure('Failed to submit form')));

      // Act
      final result = await controller.submitForm(testForm);

      // Assert
      expect(result, false);
      expect(controller.errorMessage, 'Failed to submit form');
      expect(controller.isProcessing, false);
    });
  });

  group('confirmForm', () {
    setUp(() async {
      when(
        () => mockGetTransactionUseCase.call(any()),
      ).thenAnswer((_) async => Right(testTransaction));
      when(
        () => mockGetChatMessagesUseCase.call(any()),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => mockGetTransactionFormUseCase.call(any(), any()),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockGetTimelineUseCase.call(any()),
      ).thenAnswer((_) async => const Right([]));
      await controller.loadTransaction('transaction-123', 'seller-123');
    });

    test('should confirm form successfully', () async {
      // Arrange
      when(
        () => mockConfirmFormUseCase.call(any(), any()),
      ).thenAnswer((_) async => const Right(true));

      // Act
      final result = await controller.confirmForm(FormRole.buyer);

      // Assert
      expect(result, true);
      expect(controller.isProcessing, false);

      verify(
        () => mockConfirmFormUseCase.call('transaction-123', FormRole.buyer),
      ).called(1);
    });

    test('should handle ServerFailure when confirming form', () async {
      // Arrange
      when(
        () => mockConfirmFormUseCase.call(any(), any()),
      ).thenAnswer((_) async => Left(ServerFailure('Failed to confirm form')));

      // Act
      final result = await controller.confirmForm(FormRole.buyer);

      // Assert
      expect(result, false);
      expect(controller.errorMessage, 'Failed to confirm form');
    });
  });

  group('submitToAdmin', () {
    test('should submit to admin successfully', () async {
      // Arrange
      final readyTransaction = testTransaction.copyWith(
        sellerFormSubmitted: true,
        buyerFormSubmitted: true,
        sellerConfirmed: true,
        buyerConfirmed: true,
      );

      when(
        () => mockGetTransactionUseCase.call(any()),
      ).thenAnswer((_) async => Right(readyTransaction));
      when(
        () => mockGetChatMessagesUseCase.call(any()),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => mockGetTransactionFormUseCase.call(any(), any()),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockGetTimelineUseCase.call(any()),
      ).thenAnswer((_) async => const Right([]));
      await controller.loadTransaction('transaction-123', 'seller-123');

      when(
        () => mockSubmitToAdminUseCase.call(any()),
      ).thenAnswer((_) async => const Right(true));

      // Act
      final result = await controller.submitToAdmin();

      // Assert
      expect(result, true);
      expect(controller.isProcessing, false);

      verify(() => mockSubmitToAdminUseCase.call('transaction-123')).called(1);
    });

    test('should return false when transaction not ready', () async {
      // Arrange
      final notReadyTransaction = testTransaction.copyWith(
        sellerFormSubmitted: true,
        buyerFormSubmitted: false,
      );

      when(
        () => mockGetTransactionUseCase.call(any()),
      ).thenAnswer((_) async => Right(notReadyTransaction));
      when(
        () => mockGetChatMessagesUseCase.call(any()),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => mockGetTransactionFormUseCase.call(any(), any()),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockGetTimelineUseCase.call(any()),
      ).thenAnswer((_) async => const Right([]));
      await controller.loadTransaction('transaction-123', 'seller-123');

      // Act
      final result = await controller.submitToAdmin();

      // Assert
      expect(result, false);
      verifyNever(() => mockSubmitToAdminUseCase.call(any()));
    });
  });

  group('updateDeliveryStatus', () {
    setUp(() async {
      when(
        () => mockGetTransactionUseCase.call(any()),
      ).thenAnswer((_) async => Right(testTransaction));
      when(
        () => mockGetChatMessagesUseCase.call(any()),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => mockGetTransactionFormUseCase.call(any(), any()),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockGetTimelineUseCase.call(any()),
      ).thenAnswer((_) async => const Right([]));
      await controller.loadTransaction('transaction-123', 'seller-123');
    });

    test('should update delivery status successfully', () async {
      // Arrange
      when(
        () => mockUpdateDeliveryStatusUseCase.call(any(), any(), any()),
      ).thenAnswer((_) async => const Right(true));

      // Act
      final result = await controller.updateDeliveryStatus(
        DeliveryStatus.inTransit,
      );

      // Assert
      expect(result, true);
      expect(controller.isProcessing, false);

      verify(
        () => mockUpdateDeliveryStatusUseCase.call(
          'transaction-123',
          'seller-123',
          DeliveryStatus.inTransit,
        ),
      ).called(1);
    });

    test('should handle ServerFailure when updating delivery status', () async {
      // Arrange
      when(
        () => mockUpdateDeliveryStatusUseCase.call(any(), any(), any()),
      ).thenAnswer((_) async => Left(ServerFailure('Failed to update status')));

      // Act
      final result = await controller.updateDeliveryStatus(
        DeliveryStatus.delivered,
      );

      // Assert
      expect(result, false);
      expect(controller.errorMessage, 'Failed to update status');
    });
  });

  group('acceptVehicle', () {
    test('should accept vehicle successfully', () async {
      // Arrange
      final deliveredTransaction = testTransaction.copyWith(
        deliveryStatus: DeliveryStatus.delivered,
        buyerAcceptanceStatus: BuyerAcceptanceStatus.pending,
      );

      when(
        () => mockGetTransactionUseCase.call(any()),
      ).thenAnswer((_) async => Right(deliveredTransaction));
      when(
        () => mockGetChatMessagesUseCase.call(any()),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => mockGetTransactionFormUseCase.call(any(), any()),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockGetTimelineUseCase.call(any()),
      ).thenAnswer((_) async => const Right([]));
      await controller.loadTransaction('transaction-123', 'buyer-123');

      when(
        () => mockAcceptVehicleUseCase.call(any(), any()),
      ).thenAnswer((_) async => const Right(true));

      // Act
      final result = await controller.acceptVehicle('buyer-123');

      // Assert
      expect(result, true);
      expect(controller.isProcessing, false);

      verify(
        () => mockAcceptVehicleUseCase.call('transaction-123', 'buyer-123'),
      ).called(1);
    });

    test('should return false when buyer cannot respond', () async {
      // Arrange - Transaction not delivered yet
      when(
        () => mockGetTransactionUseCase.call(any()),
      ).thenAnswer((_) async => Right(testTransaction));
      when(
        () => mockGetChatMessagesUseCase.call(any()),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => mockGetTransactionFormUseCase.call(any(), any()),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockGetTimelineUseCase.call(any()),
      ).thenAnswer((_) async => const Right([]));
      await controller.loadTransaction('transaction-123', 'buyer-123');

      // Act
      final result = await controller.acceptVehicle('buyer-123');

      // Assert
      expect(result, false);
      expect(controller.errorMessage, 'Cannot accept at this stage');
      verifyNever(() => mockAcceptVehicleUseCase.call(any(), any()));
    });
  });

  group('rejectVehicle', () {
    test('should reject vehicle successfully', () async {
      // Arrange
      final deliveredTransaction = testTransaction.copyWith(
        deliveryStatus: DeliveryStatus.delivered,
        buyerAcceptanceStatus: BuyerAcceptanceStatus.pending,
      );

      when(
        () => mockGetTransactionUseCase.call(any()),
      ).thenAnswer((_) async => Right(deliveredTransaction));
      when(
        () => mockGetChatMessagesUseCase.call(any()),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => mockGetTransactionFormUseCase.call(any(), any()),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockGetTimelineUseCase.call(any()),
      ).thenAnswer((_) async => const Right([]));
      await controller.loadTransaction('transaction-123', 'buyer-123');

      when(
        () => mockRejectVehicleUseCase.call(any(), any(), any()),
      ).thenAnswer((_) async => const Right(true));

      // Act
      final result = await controller.rejectVehicle(
        'buyer-123',
        'Not as described',
      );

      // Assert
      expect(result, true);
      expect(controller.isProcessing, false);

      verify(
        () => mockRejectVehicleUseCase.call(
          'transaction-123',
          'buyer-123',
          'Not as described',
        ),
      ).called(1);
    });

    test('should return false when buyer cannot respond', () async {
      // Arrange
      when(
        () => mockGetTransactionUseCase.call(any()),
      ).thenAnswer((_) async => Right(testTransaction));
      when(
        () => mockGetChatMessagesUseCase.call(any()),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => mockGetTransactionFormUseCase.call(any(), any()),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockGetTimelineUseCase.call(any()),
      ).thenAnswer((_) async => const Right([]));
      await controller.loadTransaction('transaction-123', 'buyer-123');

      // Act
      final result = await controller.rejectVehicle('buyer-123', 'reason');

      // Assert
      expect(result, false);
      expect(controller.errorMessage, 'Cannot reject at this stage');
    });
  });

  group('clearError', () {
    test('should clear error message', () async {
      // Arrange - Set error
      when(
        () => mockGetTransactionUseCase.call(any()),
      ).thenAnswer((_) async => Left(ServerFailure('Error')));
      await controller.loadTransaction('transaction-123', 'seller-123');
      expect(controller.errorMessage, isNotNull);

      // Act
      controller.clearError();

      // Assert
      expect(controller.errorMessage, isNull);
      expect(controller.hasError, false);
    });
  });
}
