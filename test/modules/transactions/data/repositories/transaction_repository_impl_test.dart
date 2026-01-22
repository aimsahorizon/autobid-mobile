import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:autobid_mobile/modules/transactions/data/datasources/transaction_remote_datasource.dart';
import 'package:autobid_mobile/modules/transactions/domain/entities/transaction_entity.dart';
import 'package:autobid_mobile/core/error/failures.dart';

class MockTransactionRemoteDataSource extends Mock
    implements TransactionRemoteDataSource {}

class FakeTransactionFormEntity extends Fake implements TransactionFormEntity {}

void main() {
  late TransactionRepositoryImpl repository;
  late MockTransactionRemoteDataSource mockDataSource;

  setUpAll(() {
    registerFallbackValue(FakeTransactionFormEntity());
    registerFallbackValue(FormRole.seller);
    registerFallbackValue(DeliveryStatus.pending);
  });

  setUp(() {
    mockDataSource = MockTransactionRemoteDataSource();
    repository = TransactionRepositoryImpl(mockDataSource);
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
    sellerFormSubmitted: false,
    buyerFormSubmitted: false,
    sellerConfirmed: false,
    buyerConfirmed: false,
  );

  final testMessage = ChatMessageEntity(
    id: 'msg-1',
    transactionId: 'transaction-123',
    senderId: 'seller-123',
    senderName: 'Seller',
    message: 'Hello',
    timestamp: DateTime.now(),
  );

  final testForm = TransactionFormEntity(
    id: 'form-1',
    transactionId: 'transaction-123',
    role: FormRole.seller,
    status: FormStatus.submitted,
    submittedAt: DateTime.now(),
    preferredDate: DateTime.now().add(const Duration(days: 7)),
  );

  final testTimeline = TransactionTimelineEntity(
    id: 'timeline-1',
    transactionId: 'transaction-123',
    title: 'Transaction Created',
    description: 'Transaction started',
    timestamp: DateTime.now(),
    type: TimelineEventType.created,
  );

  group('getTransaction', () {
    test('should return transaction when found', () async {
      when(
        () => mockDataSource.getTransaction(any()),
      ).thenAnswer((_) async => testTransaction);

      final result = await repository.getTransaction('transaction-123');

      expect(result, Right(testTransaction));
      verify(() => mockDataSource.getTransaction('transaction-123')).called(1);
    });

    test('should return null when not found', () async {
      when(
        () => mockDataSource.getTransaction(any()),
      ).thenAnswer((_) async => null);

      final result = await repository.getTransaction('transaction-123');

      expect(result, const Right<Failure, TransactionEntity?>(null));
    });

    test('should return ServerFailure on error', () async {
      when(
        () => mockDataSource.getTransaction(any()),
      ).thenThrow(Exception('Database error'));

      final result = await repository.getTransaction('transaction-123');

      expect(result.isLeft(), true);
    });
  });

  group('getChatMessages', () {
    test('should return list of messages', () async {
      when(
        () => mockDataSource.getChatMessages(any()),
      ).thenAnswer((_) async => [testMessage]);

      final result = await repository.getChatMessages('transaction-123');

      expect(result.isRight(), true);
      result.fold((_) => fail('Should succeed'), (messages) {
        expect(messages.length, 1);
        expect(messages.first.id, testMessage.id);
      });
    });

    test('should return empty list when no messages', () async {
      when(
        () => mockDataSource.getChatMessages(any()),
      ).thenAnswer((_) async => []);

      final result = await repository.getChatMessages('transaction-123');

      expect(result.isRight(), true);
      result.fold((_) => fail('Should succeed'), (messages) {
        expect(messages.length, 0);
      });
    });
  });

  group('getTransactionForm', () {
    test('should return form when found', () async {
      when(
        () => mockDataSource.getTransactionForm(any(), any()),
      ).thenAnswer((_) async => testForm);

      final result = await repository.getTransactionForm(
        'transaction-123',
        FormRole.seller,
      );

      expect(result, Right(testForm));
    });

    test('should return null when form not submitted', () async {
      when(
        () => mockDataSource.getTransactionForm(any(), any()),
      ).thenAnswer((_) async => null);

      final result = await repository.getTransactionForm(
        'transaction-123',
        FormRole.buyer,
      );

      expect(result, const Right<Failure, TransactionFormEntity?>(null));
    });
  });

  group('getTimeline', () {
    test('should return timeline events', () async {
      when(
        () => mockDataSource.getTimeline(any()),
      ).thenAnswer((_) async => [testTimeline]);

      final result = await repository.getTimeline('transaction-123');

      expect(result.isRight(), true);
      result.fold((_) => fail('Should succeed'), (events) {
        expect(events.length, 1);
        expect(events.first.id, testTimeline.id);
      });
    });
  });

  group('sendMessage', () {
    test('should send message successfully', () async {
      when(
        () => mockDataSource.sendMessage(any(), any(), any(), any()),
      ).thenAnswer((_) async => true);

      final result = await repository.sendMessage(
        'transaction-123',
        'user-123',
        'User',
        'Hello',
      );

      expect(result, const Right(true));
    });

    test('should return ServerFailure on error', () async {
      when(
        () => mockDataSource.sendMessage(any(), any(), any(), any()),
      ).thenThrow(Exception('Failed to send'));

      final result = await repository.sendMessage(
        'transaction-123',
        'user-123',
        'User',
        'Hello',
      );

      expect(result.isLeft(), true);
    });
  });

  group('submitForm', () {
    test('should submit form successfully', () async {
      when(
        () => mockDataSource.submitForm(any()),
      ).thenAnswer((_) async => true);

      final result = await repository.submitForm(testForm);

      expect(result, const Right(true));
    });
  });

  group('confirmForm', () {
    test('should confirm form successfully', () async {
      when(
        () => mockDataSource.confirmForm(any(), any()),
      ).thenAnswer((_) async => true);

      final result = await repository.confirmForm(
        'transaction-123',
        FormRole.buyer,
      );

      expect(result, const Right(true));
    });
  });

  group('submitToAdmin', () {
    test('should submit to admin successfully', () async {
      when(
        () => mockDataSource.submitToAdmin(any()),
      ).thenAnswer((_) async => true);

      final result = await repository.submitToAdmin('transaction-123');

      expect(result, const Right(true));
    });
  });

  group('updateDeliveryStatus', () {
    test('should update delivery status successfully', () async {
      when(
        () => mockDataSource.updateDeliveryStatus(any(), any(), any()),
      ).thenAnswer((_) async => true);

      final result = await repository.updateDeliveryStatus(
        'transaction-123',
        'seller-123',
        DeliveryStatus.inTransit,
      );

      expect(result, const Right(true));
    });
  });

  group('acceptVehicle', () {
    test('should accept vehicle successfully', () async {
      when(
        () => mockDataSource.acceptVehicle(any(), any()),
      ).thenAnswer((_) async => true);

      final result = await repository.acceptVehicle(
        'transaction-123',
        'buyer-123',
      );

      expect(result, const Right(true));
    });
  });

  group('rejectVehicle', () {
    test('should reject vehicle successfully', () async {
      when(
        () => mockDataSource.rejectVehicle(any(), any(), any()),
      ).thenAnswer((_) async => true);

      final result = await repository.rejectVehicle(
        'transaction-123',
        'buyer-123',
        'Not as described',
      );

      expect(result, const Right(true));
    });
  });
}
