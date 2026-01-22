import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/browse/domain/repositories/auction_detail_repository.dart';
import 'package:autobid_mobile/modules/browse/domain/usecases/place_bid_usecase.dart';

class MockAuctionDetailRepository extends Mock
    implements AuctionDetailRepository {}

void main() {
  late PlaceBidUseCase useCase;
  late MockAuctionDetailRepository mockRepository;

  setUp(() {
    mockRepository = MockAuctionDetailRepository();
    useCase = PlaceBidUseCase(mockRepository);
  });

  group('PlaceBidUseCase', () {
    const testAuctionId = 'auction-123';
    const testBidderId = 'bidder-456';
    const testAmount = 55000.0;

    test('should place regular bid successfully', () async {
      // Arrange
      when(
        () => mockRepository.placeBid(
          auctionId: any(named: 'auctionId'),
          bidderId: any(named: 'bidderId'),
          amount: any(named: 'amount'),
          isAutoBid: any(named: 'isAutoBid'),
          maxAutoBid: any(named: 'maxAutoBid'),
          autoBidIncrement: any(named: 'autoBidIncrement'),
        ),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final result = await useCase(
        auctionId: testAuctionId,
        bidderId: testBidderId,
        amount: testAmount,
      );

      // Assert
      expect(result, equals(const Right(null)));
      verify(
        () => mockRepository.placeBid(
          auctionId: testAuctionId,
          bidderId: testBidderId,
          amount: testAmount,
          isAutoBid: false,
          maxAutoBid: null,
          autoBidIncrement: null,
        ),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should place auto-bid with max amount successfully', () async {
      // Arrange
      const maxAutoBid = 70000.0;
      const increment = 1000.0;
      when(
        () => mockRepository.placeBid(
          auctionId: any(named: 'auctionId'),
          bidderId: any(named: 'bidderId'),
          amount: any(named: 'amount'),
          isAutoBid: any(named: 'isAutoBid'),
          maxAutoBid: any(named: 'maxAutoBid'),
          autoBidIncrement: any(named: 'autoBidIncrement'),
        ),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final result = await useCase(
        auctionId: testAuctionId,
        bidderId: testBidderId,
        amount: testAmount,
        isAutoBid: true,
        maxAutoBid: maxAutoBid,
        autoBidIncrement: increment,
      );

      // Assert
      expect(result, equals(const Right(null)));
      verify(
        () => mockRepository.placeBid(
          auctionId: testAuctionId,
          bidderId: testBidderId,
          amount: testAmount,
          isAutoBid: true,
          maxAutoBid: maxAutoBid,
          autoBidIncrement: increment,
        ),
      ).called(1);
    });

    test('should return ServerFailure when bid placement fails', () async {
      // Arrange
      const failure = ServerFailure('Failed to place bid');
      when(
        () => mockRepository.placeBid(
          auctionId: any(named: 'auctionId'),
          bidderId: any(named: 'bidderId'),
          amount: any(named: 'amount'),
          isAutoBid: any(named: 'isAutoBid'),
          maxAutoBid: any(named: 'maxAutoBid'),
          autoBidIncrement: any(named: 'autoBidIncrement'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(
        auctionId: testAuctionId,
        bidderId: testBidderId,
        amount: testAmount,
      );

      // Assert
      expect(result, equals(const Left(failure)));
      verify(
        () => mockRepository.placeBid(
          auctionId: testAuctionId,
          bidderId: testBidderId,
          amount: testAmount,
          isAutoBid: false,
          maxAutoBid: null,
          autoBidIncrement: null,
        ),
      ).called(1);
    });

    test('should return GeneralFailure when bid amount is too low', () async {
      // Arrange
      const failure = GeneralFailure('Bid amount below minimum');
      when(
        () => mockRepository.placeBid(
          auctionId: any(named: 'auctionId'),
          bidderId: any(named: 'bidderId'),
          amount: any(named: 'amount'),
          isAutoBid: any(named: 'isAutoBid'),
          maxAutoBid: any(named: 'maxAutoBid'),
          autoBidIncrement: any(named: 'autoBidIncrement'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(
        auctionId: testAuctionId,
        bidderId: testBidderId,
        amount: 100.0, // Too low
      );

      // Assert
      expect(result, equals(const Left(failure)));
    });

    test(
      'should return PermissionFailure when user has not deposited',
      () async {
        // Arrange
        const failure = PermissionFailure('Deposit required to bid');
        when(
          () => mockRepository.placeBid(
            auctionId: any(named: 'auctionId'),
            bidderId: any(named: 'bidderId'),
            amount: any(named: 'amount'),
            isAutoBid: any(named: 'isAutoBid'),
            maxAutoBid: any(named: 'maxAutoBid'),
            autoBidIncrement: any(named: 'autoBidIncrement'),
          ),
        ).thenAnswer((_) async => const Left(failure));

        // Act
        final result = await useCase(
          auctionId: testAuctionId,
          bidderId: testBidderId,
          amount: testAmount,
        );

        // Assert
        expect(result, equals(const Left(failure)));
      },
    );

    test('should pass correct parameters to repository', () async {
      // Arrange
      const specificAuctionId = 'auction-999';
      const specificBidderId = 'bidder-888';
      const specificAmount = 100000.0;
      when(
        () => mockRepository.placeBid(
          auctionId: any(named: 'auctionId'),
          bidderId: any(named: 'bidderId'),
          amount: any(named: 'amount'),
          isAutoBid: any(named: 'isAutoBid'),
          maxAutoBid: any(named: 'maxAutoBid'),
          autoBidIncrement: any(named: 'autoBidIncrement'),
        ),
      ).thenAnswer((_) async => const Right(null));

      // Act
      await useCase(
        auctionId: specificAuctionId,
        bidderId: specificBidderId,
        amount: specificAmount,
      );

      // Assert
      verify(
        () => mockRepository.placeBid(
          auctionId: specificAuctionId,
          bidderId: specificBidderId,
          amount: specificAmount,
          isAutoBid: false,
          maxAutoBid: null,
          autoBidIncrement: null,
        ),
      ).called(1);
    });

    test('should handle auction ended scenario', () async {
      // Arrange
      const failure = GeneralFailure('Auction has ended');
      when(
        () => mockRepository.placeBid(
          auctionId: any(named: 'auctionId'),
          bidderId: any(named: 'bidderId'),
          amount: any(named: 'amount'),
          isAutoBid: any(named: 'isAutoBid'),
          maxAutoBid: any(named: 'maxAutoBid'),
          autoBidIncrement: any(named: 'autoBidIncrement'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(
        auctionId: testAuctionId,
        bidderId: testBidderId,
        amount: testAmount,
      );

      // Assert
      expect(result, equals(const Left(failure)));
    });
  });
}
