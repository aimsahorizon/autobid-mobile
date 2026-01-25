import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/browse/domain/entities/qa_entity.dart';
import 'package:autobid_mobile/modules/browse/domain/repositories/auction_detail_repository.dart';
import 'package:autobid_mobile/modules/browse/domain/usecases/get_questions_usecase.dart';

class MockAuctionDetailRepository extends Mock
    implements AuctionDetailRepository {}

class FakeQAEntity extends Fake implements QAEntity {}

void main() {
  late GetQuestionsUseCase useCase;
  late MockAuctionDetailRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeQAEntity());
  });

  setUp(() {
    mockRepository = MockAuctionDetailRepository();
    useCase = GetQuestionsUseCase(mockRepository);
  });

  group('GetQuestionsUseCase', () {
    const testAuctionId = 'auction-123';
    const testUserId = 'user-456';

    final testQuestions = [
      QAEntity(
        id: 'qa-1',
        auctionId: testAuctionId,
        category: 'General',
        question: 'Is the car still available?',
        askedBy: 'User A',
        askedAt: DateTime(2026, 1, 20, 10, 0),
        answers: const [],
        likesCount: 5,
        isLikedByUser: false,
      ),
      QAEntity(
        id: 'qa-2',
        auctionId: testAuctionId,
        category: 'Mechanical',
        question: 'Has the timing belt been replaced?',
        askedBy: 'User B',
        askedAt: DateTime(2026, 1, 20, 11, 0),
        answers: [
          QAAnswerEntity(
            id: 'answer-1',
            sellerId: 'seller-123',
            answer: 'Yes, replaced at 100,000 km',
            createdAt: DateTime(2026, 1, 20, 12, 0),
          ),
        ],
        likesCount: 3,
        isLikedByUser: true,
      ),
    ];

    test('should return questions list when successful', () async {
      // Arrange
      when(
        () => mockRepository.getQuestions(
          auctionId: any(named: 'auctionId'),
          currentUserId: any(named: 'currentUserId'),
        ),
      ).thenAnswer((_) async => Right(testQuestions));

      // Act
      final result = await useCase(
        auctionId: testAuctionId,
        currentUserId: testUserId,
      );

      // Assert
      expect(result, equals(Right(testQuestions)));
      verify(
        () => mockRepository.getQuestions(
          auctionId: testAuctionId,
          currentUserId: testUserId,
        ),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should work without currentUserId parameter', () async {
      // Arrange
      when(
        () => mockRepository.getQuestions(
          auctionId: any(named: 'auctionId'),
          currentUserId: any(named: 'currentUserId'),
        ),
      ).thenAnswer((_) async => Right(testQuestions));

      // Act
      final result = await useCase(auctionId: testAuctionId);

      // Assert
      expect(result, equals(Right(testQuestions)));
      verify(
        () => mockRepository.getQuestions(
          auctionId: testAuctionId,
          currentUserId: null,
        ),
      ).called(1);
    });

    test('should return empty list when no questions exist', () async {
      // Arrange
      when(
        () => mockRepository.getQuestions(
          auctionId: any(named: 'auctionId'),
          currentUserId: any(named: 'currentUserId'),
        ),
      ).thenAnswer((_) async => const Right([]));

      // Act
      final result = await useCase(auctionId: testAuctionId);

      // Assert
      expect(result, equals(const Right<Failure, List<QAEntity>>([])));
      expect(result.getOrElse((l) => []), isEmpty);
    });

    test('should return ServerFailure when repository fails', () async {
      // Arrange
      const failure = ServerFailure('Failed to fetch questions');
      when(
        () => mockRepository.getQuestions(
          auctionId: any(named: 'auctionId'),
          currentUserId: any(named: 'currentUserId'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(
        auctionId: testAuctionId,
        currentUserId: testUserId,
      );

      // Assert
      expect(result, equals(const Left(failure)));
      verify(
        () => mockRepository.getQuestions(
          auctionId: testAuctionId,
          currentUserId: testUserId,
        ),
      ).called(1);
    });

    test('should return NotFoundFailure when auction does not exist', () async {
      // Arrange
      const failure = NotFoundFailure('Auction not found');
      when(
        () => mockRepository.getQuestions(
          auctionId: any(named: 'auctionId'),
          currentUserId: any(named: 'currentUserId'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(auctionId: 'non-existent-auction');

      // Assert
      expect(result, equals(const Left(failure)));
    });

    test('should return NetworkFailure when network error occurs', () async {
      // Arrange
      const failure = NetworkFailure('No internet connection');
      when(
        () => mockRepository.getQuestions(
          auctionId: any(named: 'auctionId'),
          currentUserId: any(named: 'currentUserId'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(auctionId: testAuctionId);

      // Assert
      expect(result, equals(const Left(failure)));
    });

    test('should pass correct auction ID to repository', () async {
      // Arrange
      const specificAuctionId = 'specific-auction-789';
      when(
        () => mockRepository.getQuestions(
          auctionId: any(named: 'auctionId'),
          currentUserId: any(named: 'currentUserId'),
        ),
      ).thenAnswer((_) async => const Right([]));

      // Act
      await useCase(auctionId: specificAuctionId);

      // Assert
      verify(
        () => mockRepository.getQuestions(
          auctionId: specificAuctionId,
          currentUserId: null,
        ),
      ).called(1);
    });
  });
}
