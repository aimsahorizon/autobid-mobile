import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/browse/domain/repositories/auction_detail_repository.dart';
import 'package:autobid_mobile/modules/browse/domain/usecases/like_question_usecase.dart';

class MockAuctionDetailRepository extends Mock
    implements AuctionDetailRepository {}

void main() {
  late LikeQuestionUseCase useCase;
  late MockAuctionDetailRepository mockRepository;

  setUp(() {
    mockRepository = MockAuctionDetailRepository();
    useCase = LikeQuestionUseCase(mockRepository);
  });

  group('LikeQuestionUseCase', () {
    const testQuestionId = 'question-123';
    const testUserId = 'user-456';

    test('should like question successfully', () async {
      // Arrange
      when(
        () => mockRepository.likeQuestion(
          questionId: any(named: 'questionId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final result = await useCase(
        questionId: testQuestionId,
        userId: testUserId,
      );

      // Assert
      expect(result, equals(const Right(null)));
      verify(
        () => mockRepository.likeQuestion(
          questionId: testQuestionId,
          userId: testUserId,
        ),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ServerFailure when liking fails', () async {
      // Arrange
      const failure = ServerFailure('Failed to like question');
      when(
        () => mockRepository.likeQuestion(
          questionId: any(named: 'questionId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(
        questionId: testQuestionId,
        userId: testUserId,
      );

      // Assert
      expect(result, equals(const Left(failure)));
      verify(
        () => mockRepository.likeQuestion(
          questionId: testQuestionId,
          userId: testUserId,
        ),
      ).called(1);
    });

    test(
      'should return NotFoundFailure when question does not exist',
      () async {
        // Arrange
        const failure = NotFoundFailure('Question not found');
        when(
          () => mockRepository.likeQuestion(
            questionId: any(named: 'questionId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => const Left(failure));

        // Act
        final result = await useCase(
          questionId: 'non-existent-question',
          userId: testUserId,
        );

        // Assert
        expect(result, equals(const Left(failure)));
      },
    );

    test(
      'should return PermissionFailure when user is not authenticated',
      () async {
        // Arrange
        const failure = PermissionFailure('User not authenticated');
        when(
          () => mockRepository.likeQuestion(
            questionId: any(named: 'questionId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => const Left(failure));

        // Act
        final result = await useCase(questionId: testQuestionId, userId: '');

        // Assert
        expect(result, equals(const Left(failure)));
      },
    );

    test('should pass correct parameters to repository', () async {
      // Arrange
      const specificQuestionId = 'question-999';
      const specificUserId = 'user-888';

      when(
        () => mockRepository.likeQuestion(
          questionId: any(named: 'questionId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => const Right(null));

      // Act
      await useCase(questionId: specificQuestionId, userId: specificUserId);

      // Assert
      verify(
        () => mockRepository.likeQuestion(
          questionId: specificQuestionId,
          userId: specificUserId,
        ),
      ).called(1);
    });

    test('should handle duplicate like attempt', () async {
      // Arrange
      const failure = GeneralFailure('Question already liked');
      when(
        () => mockRepository.likeQuestion(
          questionId: any(named: 'questionId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(
        questionId: testQuestionId,
        userId: testUserId,
      );

      // Assert
      expect(result, equals(const Left(failure)));
    });
  });
}
