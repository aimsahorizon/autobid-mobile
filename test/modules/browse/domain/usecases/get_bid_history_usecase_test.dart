import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/browse/domain/entities/bid_history_entity.dart';
import 'package:autobid_mobile/modules/browse/domain/repositories/auction_detail_repository.dart';
import 'package:autobid_mobile/modules/browse/domain/usecases/get_bid_history_usecase.dart';

class MockAuctionDetailRepository extends Mock
    implements AuctionDetailRepository {}

class FakeBidHistoryEntity extends Fake implements BidHistoryEntity {}

void main() {
  late GetBidHistoryUseCase useCase;
  late MockAuctionDetailRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeBidHistoryEntity());
  });

  setUp(() {
    mockRepository = MockAuctionDetailRepository();
    useCase = GetBidHistoryUseCase(mockRepository);
  });

  group('GetBidHistoryUseCase', () {
    const testAuctionId = 'auction-123';

    final testBidHistory = [
      BidHistoryEntity(
        id: 'bid-1',
        auctionId: testAuctionId,
        bidderName: 'User A',
        amount: 50000.0,
        timestamp: DateTime(2026, 1, 20, 10, 0),
        isCurrentUser: false,
        isWinning: false,
      ),
      BidHistoryEntity(
        id: 'bid-2',
        auctionId: testAuctionId,
        bidderName: 'User B',
        amount: 52000.0,
        timestamp: DateTime(2026, 1, 20, 10, 30),
        isCurrentUser: true,
        isWinning: false,
      ),
      BidHistoryEntity(
        id: 'bid-3',
        auctionId: testAuctionId,
        bidderName: 'User C',
        amount: 55000.0,
        timestamp: DateTime(2026, 1, 20, 11, 0),
        isCurrentUser: false,
        isWinning: true,
      ),
    ];

    test('should return bid history list when successful', () async {
      // Arrange
      when(
        () => mockRepository.getBidHistory(auctionId: any(named: 'auctionId')),
      ).thenAnswer((_) async => Right(testBidHistory));

      // Act
      final result = await useCase(auctionId: testAuctionId);

      // Assert
      expect(result, equals(Right(testBidHistory)));
      verify(
        () => mockRepository.getBidHistory(auctionId: testAuctionId),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return empty list when no bids exist', () async {
      // Arrange
      when(
        () => mockRepository.getBidHistory(auctionId: any(named: 'auctionId')),
      ).thenAnswer((_) async => const Right([]));

      // Act
      final result = await useCase(auctionId: testAuctionId);

      // Assert
      expect(result, equals(const Right<Failure, List<BidHistoryEntity>>([])));
      expect(result.getOrElse((l) => []), isEmpty);
    });

    test('should return ServerFailure when repository fails', () async {
      // Arrange
      const failure = ServerFailure('Failed to fetch bid history');
      when(
        () => mockRepository.getBidHistory(auctionId: any(named: 'auctionId')),
      ).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(auctionId: testAuctionId);

      // Assert
      expect(result, equals(const Left(failure)));
      verify(
        () => mockRepository.getBidHistory(auctionId: testAuctionId),
      ).called(1);
    });

    test('should return NotFoundFailure when auction does not exist', () async {
      // Arrange
      const failure = NotFoundFailure('Auction not found');
      when(
        () => mockRepository.getBidHistory(auctionId: any(named: 'auctionId')),
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
        () => mockRepository.getBidHistory(auctionId: any(named: 'auctionId')),
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
        () => mockRepository.getBidHistory(auctionId: any(named: 'auctionId')),
      ).thenAnswer((_) async => const Right([]));

      // Act
      await useCase(auctionId: specificAuctionId);

      // Assert
      verify(
        () => mockRepository.getBidHistory(auctionId: specificAuctionId),
      ).called(1);
    });

    test('should handle large bid history list', () async {
      // Arrange
      final largeBidHistory = List.generate(
        100,
        (index) => BidHistoryEntity(
          id: 'bid-$index',
          auctionId: testAuctionId,
          bidderName: 'User $index',
          amount: 50000.0 + (index * 500),
          timestamp: DateTime(2026, 1, 20).add(Duration(minutes: index)),
          isCurrentUser: index == 50,
          isWinning: index == 99,
        ),
      );
      when(
        () => mockRepository.getBidHistory(auctionId: any(named: 'auctionId')),
      ).thenAnswer((_) async => Right(largeBidHistory));

      // Act
      final result = await useCase(auctionId: testAuctionId);

      // Assert
      expect(result.isRight(), true);
      expect(result.getOrElse((l) => []).length, equals(100));
    });
  });
}
