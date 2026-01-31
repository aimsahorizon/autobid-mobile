import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
// ...existing code...
import 'package:autobid_mobile/modules/guest/data/repositories/guest_repository_impl.dart';
import 'package:autobid_mobile/modules/guest/data/datasources/guest_remote_datasource.dart';
import 'package:autobid_mobile/core/error/failures.dart';

class MockGuestRemoteDataSource extends Mock implements GuestRemoteDataSource {}

void main() {
  late GuestRepositoryImpl repository;
  late MockGuestRemoteDataSource mockDataSource;

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
  ];

  setUp(() {
    mockDataSource = MockGuestRemoteDataSource();
    repository = GuestRepositoryImpl(remoteDataSource: mockDataSource);
  });

  group('GuestRepositoryImpl', () {
    group('getGuestAuctionListings', () {
      test('should return list of listings when datasource succeeds', () async {
        // Arrange
        when(
          () => mockDataSource.getGuestAuctionListings(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => testListings);

        // Act
        final result = await repository.getGuestAuctionListings(
          limit: 20,
          offset: 0,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right but got Left: $failure'),
          (listings) {
            expect(listings.length, equals(2));
            expect(listings[0]['id'], equals('auction-1'));
          },
        );
        verify(
          () => mockDataSource.getGuestAuctionListings(limit: 20, offset: 0),
        ).called(1);
      });

      test('should return empty list when no listings available', () async {
        // Arrange
        when(
          () => mockDataSource.getGuestAuctionListings(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => []);

        // Act
        final result = await repository.getGuestAuctionListings(
          limit: 20,
          offset: 0,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right but got Left: $failure'),
          (listings) => expect(listings, isEmpty),
        );
      });

      test(
        'should return ServerFailure when datasource throws exception',
        () async {
          // Arrange
          when(
            () => mockDataSource.getGuestAuctionListings(
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
            ),
          ).thenThrow(Exception('Database error'));

          // Act
          final result = await repository.getGuestAuctionListings(
            limit: 20,
            offset: 0,
          );

          // Assert
          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<ServerFailure>());
            expect(
              failure.message,
              equals('Failed to fetch auctions: Exception: Database error'),
            );
          }, (listings) => fail('Expected Left but got Right'));
        },
      );

      test('should pass correct pagination parameters', () async {
        // Arrange
        when(
          () => mockDataSource.getGuestAuctionListings(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => testListings);

        // Act
        await repository.getGuestAuctionListings(limit: 10, offset: 5);

        // Assert
        verify(
          () => mockDataSource.getGuestAuctionListings(limit: 10, offset: 5),
        ).called(1);
      });
    });
  });
}
