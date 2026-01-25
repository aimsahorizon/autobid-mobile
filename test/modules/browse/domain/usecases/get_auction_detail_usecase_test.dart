import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/browse/domain/entities/auction_detail_entity.dart';
import 'package:autobid_mobile/modules/browse/domain/repositories/auction_detail_repository.dart';
import 'package:autobid_mobile/modules/browse/domain/usecases/get_auction_detail_usecase.dart';

class MockAuctionDetailRepository extends Mock
    implements AuctionDetailRepository {}

class FakeAuctionDetailEntity extends Fake implements AuctionDetailEntity {}

void main() {
  late GetAuctionDetailUseCase useCase;
  late MockAuctionDetailRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeAuctionDetailEntity());
  });

  setUp(() {
    mockRepository = MockAuctionDetailRepository();
    useCase = GetAuctionDetailUseCase(mockRepository);
  });

  group('GetAuctionDetailUseCase', () {
    const testAuctionId = 'auction-123';
    const testUserId = 'user-456';

    final testAuctionDetail = AuctionDetailEntity(
      id: testAuctionId,
      carImageUrl: 'https://example.com/car.jpg',
      currentBid: 50000.0,
      minimumBid: 30000.0,
      reservePrice: 60000.0,
      isReserveMet: false,
      showReservePrice: true,
      minBidIncrement: 500.0,
      enableIncrementalBidding: true,
      watchersCount: 15,
      biddersCount: 8,
      totalBids: 23,
      endTime: DateTime(2026, 2, 1, 12, 0),
      status: 'active',
      photos: const CarPhotosEntity(
        exterior: [],
        interior: [],
        engine: [],
        details: [],
        documents: [],
      ),
      hasUserDeposited: true,
      brand: 'BMW',
      model: 'M3',
      year: 2023,
      exteriorColor: 'Blue',
      province: 'Gauteng',
      plateNumber: 'ABC 123 GP',
      previousOwners: 1,
    );

    test('should return auction detail when successful', () async {
      // Arrange
      when(
        () => mockRepository.getAuctionDetail(
          auctionId: any(named: 'auctionId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => Right(testAuctionDetail));

      // Act
      final result = await useCase(
        auctionId: testAuctionId,
        userId: testUserId,
      );

      // Assert
      expect(result, equals(Right(testAuctionDetail)));
      verify(
        () => mockRepository.getAuctionDetail(
          auctionId: testAuctionId,
          userId: testUserId,
        ),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should work without userId parameter', () async {
      // Arrange
      when(
        () => mockRepository.getAuctionDetail(
          auctionId: any(named: 'auctionId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => Right(testAuctionDetail));

      // Act
      final result = await useCase(auctionId: testAuctionId);

      // Assert
      expect(result, equals(Right(testAuctionDetail)));
      verify(
        () => mockRepository.getAuctionDetail(
          auctionId: testAuctionId,
          userId: null,
        ),
      ).called(1);
    });

    test('should return ServerFailure when repository fails', () async {
      // Arrange
      const failure = ServerFailure('Failed to fetch auction detail');
      when(
        () => mockRepository.getAuctionDetail(
          auctionId: any(named: 'auctionId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(
        auctionId: testAuctionId,
        userId: testUserId,
      );

      // Assert
      expect(result, equals(const Left(failure)));
      verify(
        () => mockRepository.getAuctionDetail(
          auctionId: testAuctionId,
          userId: testUserId,
        ),
      ).called(1);
    });

    test('should return NotFoundFailure when auction does not exist', () async {
      // Arrange
      const failure = NotFoundFailure('Auction not found');
      when(
        () => mockRepository.getAuctionDetail(
          auctionId: any(named: 'auctionId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(auctionId: 'non-existent-id');

      // Assert
      expect(result, equals(const Left(failure)));
    });

    test('should return NetworkFailure when network error occurs', () async {
      // Arrange
      const failure = NetworkFailure('No internet connection');
      when(
        () => mockRepository.getAuctionDetail(
          auctionId: any(named: 'auctionId'),
          userId: any(named: 'userId'),
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
        () => mockRepository.getAuctionDetail(
          auctionId: any(named: 'auctionId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => Right(testAuctionDetail));

      // Act
      await useCase(auctionId: specificAuctionId);

      // Assert
      verify(
        () => mockRepository.getAuctionDetail(
          auctionId: specificAuctionId,
          userId: null,
        ),
      ).called(1);
    });
  });
}
