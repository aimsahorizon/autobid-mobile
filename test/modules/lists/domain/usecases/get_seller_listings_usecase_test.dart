import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/lists/domain/usecases/get_seller_listings_usecase.dart';
import 'package:autobid_mobile/modules/lists/domain/repositories/seller_repository.dart';
import 'package:autobid_mobile/modules/lists/domain/entities/seller_listing_entity.dart';
import 'package:autobid_mobile/core/error/failures.dart';

class MockSellerRepository extends Mock implements SellerRepository {}

void main() {
  late GetSellerListingsUseCase useCase;
  late MockSellerRepository mockRepository;

  setUp(() {
    mockRepository = MockSellerRepository();
    useCase = GetSellerListingsUseCase(mockRepository);
  });

  const testSellerId = 'seller-123';

  final testActiveListings = [
    SellerListingEntity(
      id: 'listing-1',
      imageUrl: 'https://example.com/car1.jpg',
      year: 2020,
      make: 'Toyota',
      model: 'Camry',
      status: ListingStatus.active,
      startingPrice: 15000.0,
      startTime: DateTime(2024, 1, 1),
      currentBid: 16000.0,
      reservePrice: 14000.0,
      totalBids: 5,
      watchersCount: 10,
      viewsCount: 50,
      createdAt: DateTime(2023, 12, 1),
      endTime: DateTime(2024, 1, 10),
      sellerId: testSellerId,
    ),
  ];

  final testPendingListings = [
    SellerListingEntity(
      id: 'listing-2',
      imageUrl: 'https://example.com/car2.jpg',
      year: 2019,
      make: 'Honda',
      model: 'Civic',
      status: ListingStatus.pending,
      startingPrice: 12000.0,
      startTime: null,
      currentBid: null,
      reservePrice: 11000.0,
      totalBids: 0,
      watchersCount: 0,
      viewsCount: 0,
      createdAt: DateTime(2023, 12, 15),
      endTime: null,
      sellerId: testSellerId,
    ),
  ];

  final testListingsMap = {
    ListingStatus.active: testActiveListings,
    ListingStatus.pending: testPendingListings,
    ListingStatus.scheduled: <SellerListingEntity>[],
    ListingStatus.inTransaction: <SellerListingEntity>[],
    ListingStatus.sold: <SellerListingEntity>[],
    ListingStatus.cancelled: <SellerListingEntity>[],
  };

  group('GetSellerListingsUseCase', () {
    test('should get seller listings grouped by status', () async {
      // Arrange
      when(
        () => mockRepository.getSellerListings(testSellerId),
      ).thenAnswer((_) async => Right(testListingsMap));

      // Act
      final result = await useCase(testSellerId);

      // Assert
      expect(result.isRight(), true);
      result.fold((failure) => fail('Should return listings'), (listings) {
        expect(listings[ListingStatus.active]?.length, 1);
        expect(listings[ListingStatus.pending]?.length, 1);
        expect(listings[ListingStatus.active]?.first.id, 'listing-1');
        expect(listings[ListingStatus.pending]?.first.id, 'listing-2');
      });

      verify(() => mockRepository.getSellerListings(testSellerId)).called(1);
    });

    test('should handle empty listings', () async {
      // Arrange
      final emptyMap = {
        ListingStatus.active: <SellerListingEntity>[],
        ListingStatus.pending: <SellerListingEntity>[],
        ListingStatus.scheduled: <SellerListingEntity>[],
        ListingStatus.inTransaction: <SellerListingEntity>[],
        ListingStatus.sold: <SellerListingEntity>[],
        ListingStatus.cancelled: <SellerListingEntity>[],
      };

      when(
        () => mockRepository.getSellerListings(testSellerId),
      ).thenAnswer((_) async => Right(emptyMap));

      // Act
      final result = await useCase(testSellerId);

      // Assert
      expect(result.isRight(), true);
      result.fold((failure) => fail('Should return empty map'), (listings) {
        expect(listings[ListingStatus.active], isEmpty);
        expect(listings[ListingStatus.pending], isEmpty);
      });
    });

    test('should return NotFoundFailure when seller not found', () async {
      // Arrange
      when(
        () => mockRepository.getSellerListings(testSellerId),
      ).thenAnswer((_) async => Left(NotFoundFailure('Seller not found')));

      // Act
      final result = await useCase(testSellerId);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<NotFoundFailure>());
        expect(failure.message, 'Seller not found');
      }, (_) => fail('Should return failure'));
    });

    test('should return NetworkFailure when network unavailable', () async {
      // Arrange
      when(
        () => mockRepository.getSellerListings(testSellerId),
      ).thenAnswer((_) async => Left(NetworkFailure('No internet connection')));

      // Act
      final result = await useCase(testSellerId);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<NetworkFailure>());
        expect(failure.message, 'No internet connection');
      }, (_) => fail('Should return failure'));
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      when(
        () => mockRepository.getSellerListings(testSellerId),
      ).thenAnswer((_) async => Left(ServerFailure('Server error')));

      // Act
      final result = await useCase(testSellerId);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Server error');
      }, (_) => fail('Should return failure'));
    });
  });
}
