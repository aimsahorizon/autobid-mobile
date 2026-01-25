import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/guest/domain/usecases/get_guest_auction_listings_usecase.dart';
import 'package:autobid_mobile/modules/guest/domain/repositories/guest_repository.dart';
import 'package:autobid_mobile/core/error/failures.dart';

class MockGuestRepository extends Mock implements GuestRepository {}

void main() {
  late GetGuestAuctionListingsUseCase useCase;
  late MockGuestRepository mockRepository;

  final testListings = [
    {
      'id': 'auction-1',
      'title': 'Toyota Camry 2020',
      'currentBid': 50000.0,
      'endTime': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
      'imageUrl': 'https://example.com/car1.jpg',
    },
    {
      'id': 'auction-2',
      'title': 'Honda Civic 2019',
      'currentBid': 45000.0,
      'endTime': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      'imageUrl': 'https://example.com/car2.jpg',
    },
    {
      'id': 'auction-3',
      'title': 'Ford Mustang 2021',
      'currentBid': 80000.0,
      'endTime': DateTime.now()
          .add(const Duration(hours: 12))
          .toIso8601String(),
      'imageUrl': 'https://example.com/car3.jpg',
    },
  ];

  setUp(() {
    mockRepository = MockGuestRepository();
    useCase = GetGuestAuctionListingsUseCase(mockRepository);
  });

  group('GetGuestAuctionListingsUseCase', () {
    test(
      'should return list of auction listings when repository succeeds',
      () async {
        // Arrange
        when(
          () => mockRepository.getGuestAuctionListings(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => Right(testListings));

        // Act
        final result = await useCase(limit: 20, offset: 0);

        // Assert
        expect(result.isRight(), true);
        result.fold((failure) => fail('Expected Right but got Left'), (
          listings,
        ) {
          expect(listings.length, equals(3));
          expect(listings[0]['id'], equals('auction-1'));
          expect(listings[1]['id'], equals('auction-2'));
          expect(listings[2]['id'], equals('auction-3'));
        });
        verify(
          () => mockRepository.getGuestAuctionListings(limit: 20, offset: 0),
        ).called(1);
      },
    );

    test('should use default pagination values when not provided', () async {
      // Arrange
      when(
        () => mockRepository.getGuestAuctionListings(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => Right(testListings));

      // Act
      final result = await useCase();

      // Assert
      expect(result.isRight(), true);
      verify(
        () => mockRepository.getGuestAuctionListings(limit: 20, offset: 0),
      ).called(1);
    });

    test('should return empty list when no auctions available', () async {
      // Arrange
      when(
        () => mockRepository.getGuestAuctionListings(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => const Right([]));

      // Act
      final result = await useCase(limit: 20, offset: 0);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right but got Left'),
        (listings) => expect(listings, isEmpty),
      );
    });

    test('should return ServerFailure when repository fails', () async {
      // Arrange
      const failure = ServerFailure('Failed to fetch auction listings');
      when(
        () => mockRepository.getGuestAuctionListings(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(limit: 20, offset: 0);

      // Assert
      expect(result, equals(const Left(failure)));
      verify(
        () => mockRepository.getGuestAuctionListings(limit: 20, offset: 0),
      ).called(1);
    });

    test('should return NetworkFailure when network error occurs', () async {
      // Arrange
      const failure = NetworkFailure('No internet connection');
      when(
        () => mockRepository.getGuestAuctionListings(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(limit: 20, offset: 0);

      // Assert
      expect(result, equals(const Left(failure)));
    });

    test('should handle custom pagination parameters', () async {
      // Arrange
      when(
        () => mockRepository.getGuestAuctionListings(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => Right(testListings));

      // Act
      final result = await useCase(limit: 10, offset: 5);

      // Assert
      expect(result.isRight(), true);
      verify(
        () => mockRepository.getGuestAuctionListings(limit: 10, offset: 5),
      ).called(1);
    });

    test('should handle large result sets', () async {
      // Arrange
      final largeListings = List.generate(
        100,
        (index) => {
          'id': 'auction-$index',
          'title': 'Car $index',
          'currentBid': 50000.0 + index * 1000,
          'endTime': DateTime.now()
              .add(Duration(hours: index))
              .toIso8601String(),
          'imageUrl': 'https://example.com/car$index.jpg',
        },
      );
      when(
        () => mockRepository.getGuestAuctionListings(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => Right(largeListings));

      // Act
      final result = await useCase(limit: 100, offset: 0);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right but got Left'),
        (listings) => expect(listings.length, equals(100)),
      );
    });
  });
}
