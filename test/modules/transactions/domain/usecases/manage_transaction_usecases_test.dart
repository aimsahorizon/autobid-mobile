import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/transactions/domain/usecases/manage_transaction_usecases.dart';
import 'package:autobid_mobile/modules/transactions/domain/repositories/transaction_repository.dart';
import 'package:autobid_mobile/modules/transactions/domain/entities/transaction_entity.dart';
import 'package:autobid_mobile/core/error/failures.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late SendMessageUseCase sendMessageUseCase;
  late SubmitFormUseCase submitFormUseCase;
  late ConfirmFormUseCase confirmFormUseCase;
  late SubmitToAdminUseCase submitToAdminUseCase;
  late UpdateDeliveryStatusUseCase updateDeliveryStatusUseCase;
  late AcceptVehicleUseCase acceptVehicleUseCase;
  late RejectVehicleUseCase rejectVehicleUseCase;
  late MockTransactionRepository mockRepository;

  setUp(() {
    mockRepository = MockTransactionRepository();
    sendMessageUseCase = SendMessageUseCase(mockRepository);
    submitFormUseCase = SubmitFormUseCase(mockRepository);
    confirmFormUseCase = ConfirmFormUseCase(mockRepository);
    submitToAdminUseCase = SubmitToAdminUseCase(mockRepository);
    updateDeliveryStatusUseCase = UpdateDeliveryStatusUseCase(mockRepository);
    acceptVehicleUseCase = AcceptVehicleUseCase(mockRepository);
    rejectVehicleUseCase = RejectVehicleUseCase(mockRepository);
  });

  const testTransactionId = 'txn-123';
  const testUserId = 'user-123';
  const testUserName = 'John Doe';
  const testMessage = 'Hello, when can we schedule the pickup?';

  final testForm = TransactionFormEntity(
    id: 'form-123',
    transactionId: testTransactionId,
    role: FormRole.buyer,
    status: FormStatus.submitted,
    contactNumber: '+1234567890',
    preferredDate: DateTime(2024, 1, 15),
    submittedAt: DateTime(2024, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(testForm);
    registerFallbackValue(FormRole.buyer);
    registerFallbackValue(DeliveryStatus.pending);
  });

  group('SendMessageUseCase', () {
    test('should send message successfully', () async {
      // Arrange
      when(
        () => mockRepository.sendMessage(
          testTransactionId,
          testUserId,
          testUserName,
          testMessage,
        ),
      ).thenAnswer((_) async => const Right(true));

      // Act
      final result = await sendMessageUseCase(
        testTransactionId,
        testUserId,
        testUserName,
        testMessage,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return true'),
        (success) => expect(success, true),
      );

      verify(
        () => mockRepository.sendMessage(
          testTransactionId,
          testUserId,
          testUserName,
          testMessage,
        ),
      ).called(1);
    });

    test('should return ServerFailure on send error', () async {
      // Arrange
      when(
        () => mockRepository.sendMessage(any(), any(), any(), any()),
      ).thenAnswer((_) async => Left(ServerFailure('Failed to send message')));

      // Act
      final result = await sendMessageUseCase(
        testTransactionId,
        testUserId,
        testUserName,
        testMessage,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Failed to send message');
      }, (_) => fail('Should return failure'));
    });
  });

  group('SubmitFormUseCase', () {
    test('should submit form successfully', () async {
      // Arrange
      when(
        () => mockRepository.submitForm(any()),
      ).thenAnswer((_) async => const Right(true));

      // Act
      final result = await submitFormUseCase(testForm);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return true'),
        (success) => expect(success, true),
      );

      verify(() => mockRepository.submitForm(any())).called(1);
    });

    test('should return GeneralFailure on validation error', () async {
      // Arrange
      when(
        () => mockRepository.submitForm(any()),
      ).thenAnswer((_) async => Left(GeneralFailure('Form validation failed')));

      // Act
      final result = await submitFormUseCase(testForm);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<GeneralFailure>());
        expect(failure.message, 'Form validation failed');
      }, (_) => fail('Should return failure'));
    });
  });

  group('ConfirmFormUseCase', () {
    test('should confirm form successfully', () async {
      // Arrange
      when(
        () => mockRepository.confirmForm(testTransactionId, FormRole.seller),
      ).thenAnswer((_) async => const Right(true));

      // Act
      final result = await confirmFormUseCase(
        testTransactionId,
        FormRole.seller,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return true'),
        (success) => expect(success, true),
      );

      verify(
        () => mockRepository.confirmForm(testTransactionId, FormRole.seller),
      ).called(1);
    });

    test('should return GeneralFailure when form not submitted', () async {
      // Arrange
      when(
        () => mockRepository.confirmForm(any(), any()),
      ).thenAnswer((_) async => Left(GeneralFailure('Form not yet submitted')));

      // Act
      final result = await confirmFormUseCase(
        testTransactionId,
        FormRole.buyer,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<GeneralFailure>());
        expect(failure.message, 'Form not yet submitted');
      }, (_) => fail('Should return failure'));
    });
  });

  group('SubmitToAdminUseCase', () {
    test('should submit to admin successfully', () async {
      // Arrange
      when(
        () => mockRepository.submitToAdmin(testTransactionId),
      ).thenAnswer((_) async => const Right(true));

      // Act
      final result = await submitToAdminUseCase(testTransactionId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return true'),
        (success) => expect(success, true),
      );

      verify(() => mockRepository.submitToAdmin(testTransactionId)).called(1);
    });

    test('should return GeneralFailure when forms incomplete', () async {
      // Arrange
      when(() => mockRepository.submitToAdmin(testTransactionId)).thenAnswer(
        (_) async => Left(GeneralFailure('Both forms must be confirmed')),
      );

      // Act
      final result = await submitToAdminUseCase(testTransactionId);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<GeneralFailure>());
        expect(failure.message, contains('forms must be confirmed'));
      }, (_) => fail('Should return failure'));
    });
  });

  group('UpdateDeliveryStatusUseCase', () {
    test('should update delivery status successfully', () async {
      // Arrange
      when(
        () => mockRepository.updateDeliveryStatus(
          testTransactionId,
          'seller-123',
          DeliveryStatus.inTransit,
        ),
      ).thenAnswer((_) async => const Right(true));

      // Act
      final result = await updateDeliveryStatusUseCase(
        testTransactionId,
        'seller-123',
        DeliveryStatus.inTransit,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return true'),
        (success) => expect(success, true),
      );

      verify(
        () => mockRepository.updateDeliveryStatus(
          testTransactionId,
          'seller-123',
          DeliveryStatus.inTransit,
        ),
      ).called(1);
    });

    test('should return AuthFailure when unauthorized', () async {
      // Arrange
      when(
        () => mockRepository.updateDeliveryStatus(any(), any(), any()),
      ).thenAnswer(
        (_) async =>
            Left(AuthFailure('Only seller can update delivery status')),
      );

      // Act
      final result = await updateDeliveryStatusUseCase(
        testTransactionId,
        'wrong-user',
        DeliveryStatus.delivered,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<AuthFailure>());
        expect(failure.message, contains('Only seller'));
      }, (_) => fail('Should return failure'));
    });
  });

  group('AcceptVehicleUseCase', () {
    test('should accept vehicle successfully', () async {
      // Arrange
      when(
        () => mockRepository.acceptVehicle(testTransactionId, 'buyer-123'),
      ).thenAnswer((_) async => const Right(true));

      // Act
      final result = await acceptVehicleUseCase(testTransactionId, 'buyer-123');

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return true'),
        (success) => expect(success, true),
      );

      verify(
        () => mockRepository.acceptVehicle(testTransactionId, 'buyer-123'),
      ).called(1);
    });

    test('should return GeneralFailure when vehicle not delivered', () async {
      // Arrange
      when(() => mockRepository.acceptVehicle(any(), any())).thenAnswer(
        (_) async => Left(GeneralFailure('Vehicle must be delivered first')),
      );

      // Act
      final result = await acceptVehicleUseCase(testTransactionId, 'buyer-123');

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<GeneralFailure>());
        expect(failure.message, contains('must be delivered'));
      }, (_) => fail('Should return failure'));
    });
  });

  group('RejectVehicleUseCase', () {
    test('should reject vehicle successfully', () async {
      // Arrange
      const reason = 'Vehicle condition does not match description';
      when(
        () => mockRepository.rejectVehicle(
          testTransactionId,
          'buyer-123',
          reason,
        ),
      ).thenAnswer((_) async => const Right(true));

      // Act
      final result = await rejectVehicleUseCase(
        testTransactionId,
        'buyer-123',
        reason,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return true'),
        (success) => expect(success, true),
      );

      verify(
        () => mockRepository.rejectVehicle(
          testTransactionId,
          'buyer-123',
          reason,
        ),
      ).called(1);
    });

    test('should return GeneralFailure when reason is empty', () async {
      // Arrange
      when(() => mockRepository.rejectVehicle(any(), any(), any())).thenAnswer(
        (_) async => Left(GeneralFailure('Rejection reason is required')),
      );

      // Act
      final result = await rejectVehicleUseCase(
        testTransactionId,
        'buyer-123',
        '',
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<GeneralFailure>());
        expect(failure.message, contains('reason is required'));
      }, (_) => fail('Should return failure'));
    });
  });
}
