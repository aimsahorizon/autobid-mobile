import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/browse/domain/entities/qa_entity.dart';
import 'package:autobid_mobile/modules/browse/domain/repositories/auction_detail_repository.dart';
import 'package:autobid_mobile/modules/browse/domain/usecases/post_question_usecase.dart';

class MockAuctionDetailRepository extends Mock
    implements AuctionDetailRepository {}

class FakeQAEntity extends Fake implements QAEntity {}

void main() {
  late PostQuestionUseCase useCase;
  late MockAuctionDetailRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeQAEntity());
  });

  setUp(() {
    mockRepository = MockAuctionDetailRepository();
    useCase = PostQuestionUseCase(mockRepository);
  });

  group('PostQuestionUseCase', () {
    const testAuctionId = 'auction-123';
    const testUserId = 'user-456';
    const testCategory = 'Mechanical';
    const testQuestion = 'Has the timing belt been replaced?';

    final testQAEntity = QAEntity(
      id: 'qa-789',
      auctionId: testAuctionId,
      category: testCategory,
      question: testQuestion,
      askedBy: 'Test User',
      askedAt: DateTime(2026, 1, 22, 10, 0),
      answers: const [],
      likesCount: 0,
      isLikedByUser: false,
    );

    test('should post question successfully', () async {
      // Arrange
      when(
        () => mockRepository.postQuestion(
          auctionId: any(named: 'auctionId'),
          userId: any(named: 'userId'),
          category: any(named: 'category'),
          question: any(named: 'question'),
        ),
      ).thenAnswer((_) async => Right(testQAEntity));

      // Act
      final result = await useCase(
        auctionId: testAuctionId,
        userId: testUserId,
        category: testCategory,
        question: testQuestion,
      );

      // Assert
      expect(result, equals(Right(testQAEntity)));
      verify(
        () => mockRepository.postQuestion(
          auctionId: testAuctionId,
          userId: testUserId,
          category: testCategory,
          question: testQuestion,
        ),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ServerFailure when posting fails', () async {
      // Arrange
      const failure = ServerFailure('Failed to post question');
      when(
        () => mockRepository.postQuestion(
          auctionId: any(named: 'auctionId'),
          userId: any(named: 'userId'),
          category: any(named: 'category'),
          question: any(named: 'question'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(
        auctionId: testAuctionId,
        userId: testUserId,
        category: testCategory,
        question: testQuestion,
      );

      // Assert
      expect(result, equals(const Left(failure)));
      verify(
        () => mockRepository.postQuestion(
          auctionId: testAuctionId,
          userId: testUserId,
          category: testCategory,
          question: testQuestion,
        ),
      ).called(1);
    });

    test('should return NotFoundFailure when auction does not exist', () async {
      // Arrange
      const failure = NotFoundFailure('Auction not found');
      when(
        () => mockRepository.postQuestion(
          auctionId: any(named: 'auctionId'),
          userId: any(named: 'userId'),
          category: any(named: 'category'),
          question: any(named: 'question'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(
        auctionId: 'non-existent-auction',
        userId: testUserId,
        category: testCategory,
        question: testQuestion,
      );

      // Assert
      expect(result, equals(const Left(failure)));
    });

    test(
      'should return PermissionFailure when user is not authenticated',
      () async {
        // Arrange
        const failure = PermissionFailure('User not authenticated');
        when(
          () => mockRepository.postQuestion(
            auctionId: any(named: 'auctionId'),
            userId: any(named: 'userId'),
            category: any(named: 'category'),
            question: any(named: 'question'),
          ),
        ).thenAnswer((_) async => const Left(failure));

        // Act
        final result = await useCase(
          auctionId: testAuctionId,
          userId: '',
          category: testCategory,
          question: testQuestion,
        );

        // Assert
        expect(result, equals(const Left(failure)));
      },
    );

    test('should pass correct parameters to repository', () async {
      // Arrange
      const specificAuctionId = 'auction-999';
      const specificUserId = 'user-888';
      const specificCategory = 'General';
      const specificQuestion = 'Is the car still available?';

      when(
        () => mockRepository.postQuestion(
          auctionId: any(named: 'auctionId'),
          userId: any(named: 'userId'),
          category: any(named: 'category'),
          question: any(named: 'question'),
        ),
      ).thenAnswer((_) async => Right(testQAEntity));

      // Act
      await useCase(
        auctionId: specificAuctionId,
        userId: specificUserId,
        category: specificCategory,
        question: specificQuestion,
      );

      // Assert
      verify(
        () => mockRepository.postQuestion(
          auctionId: specificAuctionId,
          userId: specificUserId,
          category: specificCategory,
          question: specificQuestion,
        ),
      ).called(1);
    });

    test('should handle different question categories', () async {
      // Arrange
      final categories = ['General', 'Mechanical', 'History', 'Documentation'];

      for (final category in categories) {
        when(
          () => mockRepository.postQuestion(
            auctionId: any(named: 'auctionId'),
            userId: any(named: 'userId'),
            category: any(named: 'category'),
            question: any(named: 'question'),
          ),
        ).thenAnswer((_) async => Right(testQAEntity));

        // Act
        final result = await useCase(
          auctionId: testAuctionId,
          userId: testUserId,
          category: category,
          question: testQuestion,
        );

        // Assert
        expect(result.isRight(), true);
      }
    });
  });
}
