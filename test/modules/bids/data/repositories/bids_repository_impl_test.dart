import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
// ...existing code...
import 'package:autobid_mobile/modules/bids/data/repositories/bids_repository_impl.dart';
import 'package:autobid_mobile/modules/bids/data/datasources/bids_remote_datasource.dart';
import 'package:autobid_mobile/modules/bids/domain/entities/user_bid_entity.dart';
import 'package:autobid_mobile/core/error/failures.dart';

class MockBidsRemoteDataSource extends Mock implements BidsRemoteDataSource {}

void main() {
  late BidsRepositoryImpl repository;
  late MockBidsRemoteDataSource mockDataSource;

  const testUserId = 'user-123';

  final testActiveBids = [
    UserBidEntity(
      id: 'bid-1',
      auctionId: 'auction-1',
      carImageUrl: 'https://example.com/car1.jpg',
      year: 2020,
      make: 'Toyota',
      model: 'Camry',
      userBidAmount: 50000.0,
      currentHighestBid: 50000.0,
      endTime: DateTime(2026, 1, 25),
      status: UserBidStatus.active,
      hasDeposited: true,
      isHighestBidder: true,
      userBidCount: 3,
      canAccess: false,
    ),
  ];

  final testWonBids = [
    UserBidEntity(
      id: 'bid-2',
      auctionId: 'auction-2',
      carImageUrl: 'https://example.com/car2.jpg',
      year: 2019,
      make: 'Honda',
      model: 'Civic',
      userBidAmount: 60000.0,
      currentHighestBid: 60000.0,
      endTime: DateTime(2026, 1, 15),
      status: UserBidStatus.won,
      hasDeposited: true,
      isHighestBidder: true,
      userBidCount: 5,
      canAccess: true,
    ),
  ];

  final testLostBids = [
    UserBidEntity(
      id: 'bid-3',
      auctionId: 'auction-3',
      carImageUrl: 'https://example.com/car3.jpg',
      year: 2018,
      make: 'Nissan',
      model: 'Altima',
      userBidAmount: 45000.0,
      currentHighestBid: 48000.0,
      endTime: DateTime(2026, 1, 10),
      status: UserBidStatus.lost,
      hasDeposited: true,
      isHighestBidder: false,
      userBidCount: 2,
      canAccess: false,
    ),
  ];

  setUp(() {
    mockDataSource = MockBidsRemoteDataSource();
    repository = BidsRepositoryImpl(mockDataSource);
  });

  group('BidsRepositoryImpl', () {
    group('getUserBids', () {
      test(
        'should return categorized bids map when datasource succeeds',
        () async {
          // Arrange
          final bidsMap = <String, List<UserBidEntity>>{
            'active': testActiveBids,
            'won': testWonBids,
            'lost': testLostBids,
          };
          when(
            () => mockDataSource.getUserBids(any()),
          ).thenAnswer((_) async => bidsMap);

          // Act
          final result = await repository.getUserBids(testUserId);

          // Assert
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Expected Right but got Left: $failure'),
            (returnedMap) {
              expect(returnedMap['active']?.length, equals(1));
              expect(returnedMap['won']?.length, equals(1));
              expect(returnedMap['lost']?.length, equals(1));
            },
          );
          verify(() => mockDataSource.getUserBids(testUserId)).called(1);
        },
      );

      test('should return empty map when user has no bids', () async {
        // Arrange
        final emptyBidsMap = <String, List<UserBidEntity>>{
          'active': [],
          'won': [],
          'lost': [],
        };
        when(
          () => mockDataSource.getUserBids(any()),
        ).thenAnswer((_) async => emptyBidsMap);

        // Act
        final result = await repository.getUserBids(testUserId);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right but got Left: $failure'),
          (returnedMap) {
            expect(returnedMap['active'], isEmpty);
            expect(returnedMap['won'], isEmpty);
            expect(returnedMap['lost'], isEmpty);
          },
        );
      });

      test(
        'should return ServerFailure when datasource throws exception',
        () async {
          // Arrange
          when(
            () => mockDataSource.getUserBids(any()),
          ).thenThrow(Exception('Database error'));

          // Act
          final result = await repository.getUserBids(testUserId);

          // Assert
          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, equals('Exception: Database error'));
          }, (bidsMap) => fail('Expected Left but got Right'));
        },
      );

      test('should handle null or missing categories gracefully', () async {
        // Arrange
        final partialBidsMap = <String, List<UserBidEntity>>{
          'active': testActiveBids,
        };
        when(
          () => mockDataSource.getUserBids(any()),
        ).thenAnswer((_) async => partialBidsMap);

        // Act
        final result = await repository.getUserBids(testUserId);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right but got Left: $failure'),
          (returnedMap) {
            expect(returnedMap['active'], isNotEmpty);
          },
        );
      });
    });
  });
}
