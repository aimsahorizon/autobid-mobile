import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/transactions/domain/usecases/get_transaction_usecases.dart';
import 'package:autobid_mobile/modules/transactions/domain/repositories/transaction_repository.dart';
import 'package:autobid_mobile/modules/transactions/domain/entities/transaction_entity.dart';
import 'package:autobid_mobile/core/error/failures.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late GetTransactionUseCase getTransactionUseCase;
  late GetChatMessagesUseCase getChatMessagesUseCase;
  late GetTransactionFormUseCase getTransactionFormUseCase;
  late GetTimelineUseCase getTimelineUseCase;
  late MockTransactionRepository mockRepository;

  setUp(() {
    mockRepository = MockTransactionRepository();
    getTransactionUseCase = GetTransactionUseCase(mockRepository);
    getChatMessagesUseCase = GetChatMessagesUseCase(mockRepository);
    getTransactionFormUseCase = GetTransactionFormUseCase(mockRepository);
    getTimelineUseCase = GetTimelineUseCase(mockRepository);
  });

  const testTransactionId = 'txn-123';

  final testTransaction = TransactionEntity(
    id: testTransactionId,
    listingId: 'listing-123',
    sellerId: 'seller-123',
    buyerId: 'buyer-123',
    carName: '2020 Toyota Camry',
    carImageUrl: 'https://example.com/car.jpg',
    agreedPrice: 15000.0,
    status: TransactionStatus.discussion,
    createdAt: DateTime(2024, 1, 1),
  );

  final testChatMessages = [
    ChatMessageEntity(
      id: 'msg-1',
      transactionId: testTransactionId,
      senderId: 'buyer-123',
      senderName: 'John Doe',
      message: 'Hello, when can we meet?',
      timestamp: DateTime(2024, 1, 1),
      isRead: true,
    ),
    ChatMessageEntity(
      id: 'msg-2',
      transactionId: testTransactionId,
      senderId: 'seller-123',
      senderName: 'Jane Smith',
      message: 'Tomorrow at 2 PM works for me',
      timestamp: DateTime(2024, 1, 1, 12),
      isRead: false,
    ),
  ];

  final testForm = TransactionFormEntity(
    id: 'form-123',
    transactionId: testTransactionId,
    role: FormRole.buyer,
    status: FormStatus.submitted,
    contactNumber: '+1234567890',
    preferredDate: DateTime(2024, 1, 15),
    submittedAt: DateTime(2024, 1, 1),
  );

  final testTimeline = [
    TransactionTimelineEntity(
      id: '1',
      transactionId: testTransactionId,
      title: 'Transaction Created',
      description: 'Transaction initiated by winning bid',
      timestamp: DateTime(2024, 1, 1),
      type: TimelineEventType.created,
      actorName: 'System',
    ),
    TransactionTimelineEntity(
      id: '2',
      transactionId: testTransactionId,
      title: 'Buyer Form Submitted',
      description: 'Buyer submitted contact information',
      timestamp: DateTime(2024, 1, 2),
      type: TimelineEventType.formSubmitted,
      actorName: 'John Doe',
    ),
  ];

  group('GetTransactionUseCase', () {
    test('should get transaction by id', () async {
      // Arrange
      when(
        () => mockRepository.getTransaction(testTransactionId),
      ).thenAnswer((_) async => Right(testTransaction));

      // Act
      final result = await getTransactionUseCase(testTransactionId);

      // Assert
      expect(result.isRight(), true);
      result.fold((failure) => fail('Should return transaction'), (
        transaction,
      ) {
        expect(transaction, isNotNull);
        expect(transaction!.id, testTransactionId);
        expect(transaction.status, TransactionStatus.discussion);
      });

      verify(() => mockRepository.getTransaction(testTransactionId)).called(1);
    });

    test('should return null when transaction not found', () async {
      // Arrange
      when(
        () => mockRepository.getTransaction(testTransactionId),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final result = await getTransactionUseCase(testTransactionId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return null'),
        (transaction) => expect(transaction, isNull),
      );
    });

    test('should return NotFoundFailure on error', () async {
      // Arrange
      when(
        () => mockRepository.getTransaction(testTransactionId),
      ).thenAnswer((_) async => Left(NotFoundFailure('Transaction not found')));

      // Act
      final result = await getTransactionUseCase(testTransactionId);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<NotFoundFailure>());
        expect(failure.message, 'Transaction not found');
      }, (_) => fail('Should return failure'));
    });
  });

  group('GetChatMessagesUseCase', () {
    test('should get chat messages for transaction', () async {
      // Arrange
      when(
        () => mockRepository.getChatMessages(testTransactionId),
      ).thenAnswer((_) async => Right(testChatMessages));

      // Act
      final result = await getChatMessagesUseCase(testTransactionId);

      // Assert
      expect(result.isRight(), true);
      result.fold((failure) => fail('Should return messages'), (messages) {
        expect(messages.length, 2);
        expect(messages.first.message, 'Hello, when can we meet?');
      });

      verify(() => mockRepository.getChatMessages(testTransactionId)).called(1);
    });

    test('should handle empty chat messages', () async {
      // Arrange
      when(
        () => mockRepository.getChatMessages(testTransactionId),
      ).thenAnswer((_) async => const Right([]));

      // Act
      final result = await getChatMessagesUseCase(testTransactionId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return empty list'),
        (messages) => expect(messages, isEmpty),
      );
    });

    test('should return ServerFailure on error', () async {
      // Arrange
      when(() => mockRepository.getChatMessages(testTransactionId)).thenAnswer(
        (_) async => Left(ServerFailure('Failed to fetch messages')),
      );

      // Act
      final result = await getChatMessagesUseCase(testTransactionId);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Failed to fetch messages');
      }, (_) => fail('Should return failure'));
    });
  });

  group('GetTransactionFormUseCase', () {
    test('should get transaction form for buyer', () async {
      // Arrange
      when(
        () => mockRepository.getTransactionForm(
          testTransactionId,
          FormRole.buyer,
        ),
      ).thenAnswer((_) async => Right(testForm));

      // Act
      final result = await getTransactionFormUseCase(
        testTransactionId,
        FormRole.buyer,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold((failure) => fail('Should return form'), (form) {
        expect(form, isNotNull);
        expect(form!.role, FormRole.buyer);
        expect(form.contactNumber, '+1234567890');
      });

      verify(
        () => mockRepository.getTransactionForm(
          testTransactionId,
          FormRole.buyer,
        ),
      ).called(1);
    });

    test('should return null when form not submitted', () async {
      // Arrange
      when(
        () => mockRepository.getTransactionForm(
          testTransactionId,
          FormRole.seller,
        ),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final result = await getTransactionFormUseCase(
        testTransactionId,
        FormRole.seller,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return null'),
        (form) => expect(form, isNull),
      );
    });

    test('should return ServerFailure on error', () async {
      // Arrange
      when(
        () => mockRepository.getTransactionForm(
          testTransactionId,
          FormRole.buyer,
        ),
      ).thenAnswer((_) async => Left(ServerFailure('Failed to fetch form')));

      // Act
      final result = await getTransactionFormUseCase(
        testTransactionId,
        FormRole.buyer,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Failed to fetch form');
      }, (_) => fail('Should return failure'));
    });
  });

  group('GetTimelineUseCase', () {
    test('should get transaction timeline', () async {
      // Arrange
      when(
        () => mockRepository.getTimeline(testTransactionId),
      ).thenAnswer((_) async => Right(testTimeline));

      // Act
      final result = await getTimelineUseCase(testTransactionId);

      // Assert
      expect(result.isRight(), true);
      result.fold((failure) => fail('Should return timeline'), (timeline) {
        expect(timeline.length, 2);
        expect(timeline.first.title, 'Transaction Created');
        expect(timeline.last.title, 'Buyer Form Submitted');
      });

      verify(() => mockRepository.getTimeline(testTransactionId)).called(1);
    });

    test('should handle empty timeline', () async {
      // Arrange
      when(
        () => mockRepository.getTimeline(testTransactionId),
      ).thenAnswer((_) async => const Right([]));

      // Act
      final result = await getTimelineUseCase(testTransactionId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return empty list'),
        (timeline) => expect(timeline, isEmpty),
      );
    });

    test('should return ServerFailure on error', () async {
      // Arrange
      when(() => mockRepository.getTimeline(testTransactionId)).thenAnswer(
        (_) async => Left(ServerFailure('Failed to fetch timeline')),
      );

      // Act
      final result = await getTimelineUseCase(testTransactionId);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Failed to fetch timeline');
      }, (_) => fail('Should return failure'));
    });
  });
}
