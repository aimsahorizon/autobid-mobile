import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/browse/domain/usecases/unlike_question_usecase.dart';
import 'package:autobid_mobile/modules/browse/domain/usecases/process_deposit_usecase.dart';
import 'package:autobid_mobile/modules/browse/domain/usecases/get_bid_increment_usecase.dart';
import 'package:autobid_mobile/modules/browse/domain/usecases/upsert_bid_increment_usecase.dart';
import 'package:autobid_mobile/modules/browse/domain/repositories/auction_detail_repository.dart';
import 'package:autobid_mobile/core/error/failures.dart';

class MockAuctionDetailRepository extends Mock
    implements AuctionDetailRepository {}

void main() {
  late UnlikeQuestionUseCase unlikeQuestionUseCase;
  late ProcessDepositUseCase processDepositUseCase;
  late GetBidIncrementUseCase getBidIncrementUseCase;
  late UpsertBidIncrementUseCase upsertBidIncrementUseCase;
  late MockAuctionDetailRepository mockRepository;

  setUp(() {
    mockRepository = MockAuctionDetailRepository();
    unlikeQuestionUseCase = UnlikeQuestionUseCase(mockRepository);
    processDepositUseCase = ProcessDepositUseCase(mockRepository);
    getBidIncrementUseCase = GetBidIncrementUseCase(mockRepository);
    upsertBidIncrementUseCase = UpsertBidIncrementUseCase(mockRepository);
  });

  const testQuestionId = 'question-123';
  const testUserId = 'user-123';
  const testAuctionId = 'auction-123';
  const testIncrement = 500.0;

  group('UnlikeQuestionUseCase', () {
    test('should unlike question successfully', () async {
      // Arrange
      when(
        () => mockRepository.unlikeQuestion(
          questionId: testQuestionId,
          userId: testUserId,
        ),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final result = await unlikeQuestionUseCase(
        questionId: testQuestionId,
        userId: testUserId,
      );

      // Assert
      expect(result.isRight(), true);

      verify(
        () => mockRepository.unlikeQuestion(
          questionId: testQuestionId,
          userId: testUserId,
        ),
      ).called(1);
    });

    test('should return ServerFailure when unlike fails', () async {
      // Arrange
      when(
        () => mockRepository.unlikeQuestion(
          questionId: any(named: 'questionId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer(
        (_) async => Left(ServerFailure('Failed to unlike question')),
      );

      // Act
      final result = await unlikeQuestionUseCase(
        questionId: testQuestionId,
        userId: testUserId,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Failed to unlike question');
      }, (_) => fail('Should return failure'));
    });

    test(
      'should return NotFoundFailure when question does not exist',
      () async {
        // Arrange
        when(
          () => mockRepository.unlikeQuestion(
            questionId: any(named: 'questionId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => Left(NotFoundFailure('Question not found')));

        // Act
        final result = await unlikeQuestionUseCase(
          questionId: 'non-existent',
          userId: testUserId,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<NotFoundFailure>()),
          (_) => fail('Should return failure'),
        );
      },
    );

    test(
      'should return PermissionFailure when user not authenticated',
      () async {
        // Arrange
        when(
          () => mockRepository.unlikeQuestion(
            questionId: any(named: 'questionId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer(
          (_) async => Left(PermissionFailure('User not authenticated')),
        );

        // Act
        final result = await unlikeQuestionUseCase(
          questionId: testQuestionId,
          userId: '',
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<PermissionFailure>()),
          (_) => fail('Should return failure'),
        );
      },
    );

    test('should handle NetworkFailure when offline', () async {
      // Arrange
      when(
        () => mockRepository.unlikeQuestion(
          questionId: any(named: 'questionId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => Left(NetworkFailure('No internet connection')));

      // Act
      final result = await unlikeQuestionUseCase(
        questionId: testQuestionId,
        userId: testUserId,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('should return GeneralFailure when question was not liked', () async {
      // Arrange
      when(
        () => mockRepository.unlikeQuestion(
          questionId: any(named: 'questionId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer(
        (_) async => Left(GeneralFailure('Question was not liked by user')),
      );

      // Act
      final result = await unlikeQuestionUseCase(
        questionId: testQuestionId,
        userId: testUserId,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<GeneralFailure>());
        expect(failure.message, contains('not liked'));
      }, (_) => fail('Should return failure'));
    });
  });

  group('ProcessDepositUseCase', () {
    test('should process deposit successfully', () async {
      // Arrange
      when(
        () => mockRepository.processDeposit(auctionId: testAuctionId),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final result = await processDepositUseCase(auctionId: testAuctionId);

      // Assert
      expect(result.isRight(), true);

      verify(
        () => mockRepository.processDeposit(auctionId: testAuctionId),
      ).called(1);
    });

    test('should return ServerFailure when payment processing fails', () async {
      // Arrange
      when(
        () => mockRepository.processDeposit(auctionId: any(named: 'auctionId')),
      ).thenAnswer(
        (_) async => Left(ServerFailure('Payment processing failed')),
      );

      // Act
      final result = await processDepositUseCase(auctionId: testAuctionId);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, contains('Payment processing failed'));
      }, (_) => fail('Should return failure'));
    });

    test('should return NotFoundFailure when auction does not exist', () async {
      // Arrange
      when(
        () => mockRepository.processDeposit(auctionId: any(named: 'auctionId')),
      ).thenAnswer((_) async => Left(NotFoundFailure('Auction not found')));

      // Act
      final result = await processDepositUseCase(auctionId: 'non-existent');

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NotFoundFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test(
      'should return GeneralFailure when deposit already processed',
      () async {
        // Arrange
        when(
          () =>
              mockRepository.processDeposit(auctionId: any(named: 'auctionId')),
        ).thenAnswer(
          (_) async => Left(GeneralFailure('Deposit already processed')),
        );

        // Act
        final result = await processDepositUseCase(auctionId: testAuctionId);

        // Assert
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<GeneralFailure>());
          expect(failure.message, contains('already processed'));
        }, (_) => fail('Should return failure'));
      },
    );

    test('should return GeneralFailure when insufficient balance', () async {
      // Arrange
      when(
        () => mockRepository.processDeposit(auctionId: any(named: 'auctionId')),
      ).thenAnswer((_) async => Left(GeneralFailure('Insufficient balance')));

      // Act
      final result = await processDepositUseCase(auctionId: testAuctionId);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<GeneralFailure>());
        expect(failure.message, contains('Insufficient'));
      }, (_) => fail('Should return failure'));
    });

    test(
      'should return PermissionFailure when user not authenticated',
      () async {
        // Arrange
        when(
          () =>
              mockRepository.processDeposit(auctionId: any(named: 'auctionId')),
        ).thenAnswer(
          (_) async => Left(PermissionFailure('User not authenticated')),
        );

        // Act
        final result = await processDepositUseCase(auctionId: testAuctionId);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<PermissionFailure>()),
          (_) => fail('Should return failure'),
        );
      },
    );
  });

  group('GetBidIncrementUseCase', () {
    test('should get bid increment preference successfully', () async {
      // Arrange
      when(
        () => mockRepository.getBidIncrement(
          auctionId: testAuctionId,
          userId: testUserId,
        ),
      ).thenAnswer((_) async => const Right(500.0));

      // Act
      final result = await getBidIncrementUseCase(
        auctionId: testAuctionId,
        userId: testUserId,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return increment value'),
        (increment) => expect(increment, 500.0),
      );

      verify(
        () => mockRepository.getBidIncrement(
          auctionId: testAuctionId,
          userId: testUserId,
        ),
      ).called(1);
    });

    test('should return null when no preference set', () async {
      // Arrange
      when(
        () => mockRepository.getBidIncrement(
          auctionId: testAuctionId,
          userId: testUserId,
        ),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final result = await getBidIncrementUseCase(
        auctionId: testAuctionId,
        userId: testUserId,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return null'),
        (increment) => expect(increment, isNull),
      );
    });

    test('should return ServerFailure when retrieval fails', () async {
      // Arrange
      when(
        () => mockRepository.getBidIncrement(
          auctionId: any(named: 'auctionId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer(
        (_) async => Left(ServerFailure('Failed to get bid increment')),
      );

      // Act
      final result = await getBidIncrementUseCase(
        auctionId: testAuctionId,
        userId: testUserId,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('should handle different increment values', () async {
      // Arrange
      const increments = [100.0, 250.0, 500.0, 1000.0];

      for (final increment in increments) {
        when(
          () => mockRepository.getBidIncrement(
            auctionId: testAuctionId,
            userId: testUserId,
          ),
        ).thenAnswer((_) async => Right(increment));

        // Act
        final result = await getBidIncrementUseCase(
          auctionId: testAuctionId,
          userId: testUserId,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return increment value'),
          (value) => expect(value, increment),
        );
      }
    });

    test('should return NotFoundFailure when auction not found', () async {
      // Arrange
      when(
        () => mockRepository.getBidIncrement(
          auctionId: any(named: 'auctionId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => Left(NotFoundFailure('Auction not found')));

      // Act
      final result = await getBidIncrementUseCase(
        auctionId: 'non-existent',
        userId: testUserId,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NotFoundFailure>()),
        (_) => fail('Should return failure'),
      );
    });
  });

  group('UpsertBidIncrementUseCase', () {
    test('should save bid increment preference successfully', () async {
      // Arrange
      when(
        () => mockRepository.upsertBidIncrement(
          auctionId: testAuctionId,
          userId: testUserId,
          increment: testIncrement,
        ),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final result = await upsertBidIncrementUseCase(
        auctionId: testAuctionId,
        userId: testUserId,
        increment: testIncrement,
      );

      // Assert
      expect(result.isRight(), true);

      verify(
        () => mockRepository.upsertBidIncrement(
          auctionId: testAuctionId,
          userId: testUserId,
          increment: testIncrement,
        ),
      ).called(1);
    });

    test('should update existing bid increment preference', () async {
      // Arrange
      const newIncrement = 1000.0;
      when(
        () => mockRepository.upsertBidIncrement(
          auctionId: testAuctionId,
          userId: testUserId,
          increment: newIncrement,
        ),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final result = await upsertBidIncrementUseCase(
        auctionId: testAuctionId,
        userId: testUserId,
        increment: newIncrement,
      );

      // Assert
      expect(result.isRight(), true);

      verify(
        () => mockRepository.upsertBidIncrement(
          auctionId: testAuctionId,
          userId: testUserId,
          increment: newIncrement,
        ),
      ).called(1);
    });

    test('should return ServerFailure when save fails', () async {
      // Arrange
      when(
        () => mockRepository.upsertBidIncrement(
          auctionId: any(named: 'auctionId'),
          userId: any(named: 'userId'),
          increment: any(named: 'increment'),
        ),
      ).thenAnswer(
        (_) async => Left(ServerFailure('Failed to save bid increment')),
      );

      // Act
      final result = await upsertBidIncrementUseCase(
        auctionId: testAuctionId,
        userId: testUserId,
        increment: testIncrement,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('should return GeneralFailure for invalid increment value', () async {
      // Arrange
      when(
        () => mockRepository.upsertBidIncrement(
          auctionId: any(named: 'auctionId'),
          userId: any(named: 'userId'),
          increment: any(named: 'increment'),
        ),
      ).thenAnswer(
        (_) async => Left(GeneralFailure('Invalid increment value')),
      );

      // Act
      final result = await upsertBidIncrementUseCase(
        auctionId: testAuctionId,
        userId: testUserId,
        increment: -100.0,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<GeneralFailure>());
        expect(failure.message, contains('Invalid'));
      }, (_) => fail('Should return failure'));
    });

    test('should handle different increment values', () async {
      // Arrange
      const increments = [100.0, 250.0, 500.0, 1000.0, 5000.0];

      for (final increment in increments) {
        when(
          () => mockRepository.upsertBidIncrement(
            auctionId: testAuctionId,
            userId: testUserId,
            increment: increment,
          ),
        ).thenAnswer((_) async => const Right(null));

        // Act
        final result = await upsertBidIncrementUseCase(
          auctionId: testAuctionId,
          userId: testUserId,
          increment: increment,
        );

        // Assert
        expect(result.isRight(), true);

        verify(
          () => mockRepository.upsertBidIncrement(
            auctionId: testAuctionId,
            userId: testUserId,
            increment: increment,
          ),
        ).called(1);
      }
    });

    test('should return NotFoundFailure when auction not found', () async {
      // Arrange
      when(
        () => mockRepository.upsertBidIncrement(
          auctionId: any(named: 'auctionId'),
          userId: any(named: 'userId'),
          increment: any(named: 'increment'),
        ),
      ).thenAnswer((_) async => Left(NotFoundFailure('Auction not found')));

      // Act
      final result = await upsertBidIncrementUseCase(
        auctionId: 'non-existent',
        userId: testUserId,
        increment: testIncrement,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NotFoundFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test(
      'should return PermissionFailure when user not authenticated',
      () async {
        // Arrange
        when(
          () => mockRepository.upsertBidIncrement(
            auctionId: any(named: 'auctionId'),
            userId: any(named: 'userId'),
            increment: any(named: 'increment'),
          ),
        ).thenAnswer(
          (_) async => Left(PermissionFailure('User not authenticated')),
        );

        // Act
        final result = await upsertBidIncrementUseCase(
          auctionId: testAuctionId,
          userId: '',
          increment: testIncrement,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<PermissionFailure>()),
          (_) => fail('Should return failure'),
        );
      },
    );
  });
}
