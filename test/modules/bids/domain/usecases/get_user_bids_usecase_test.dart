import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/bids/domain/usecases/get_user_bids_usecase.dart';
import 'package:autobid_mobile/modules/bids/domain/repositories/bids_repository.dart';
import 'package:autobid_mobile/modules/bids/domain/entities/user_bid_entity.dart';
import 'package:autobid_mobile/core/error/failures.dart';

class MockBidsRepository extends Mock implements BidsRepository {}

void main() {
  late GetUserBidsUseCase useCase;
  late MockBidsRepository mockRepository;

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
    UserBidEntity(
      id: 'bid-2',
      auctionId: 'auction-2',
      carImageUrl: 'https://example.com/car2.jpg',
      year: 2021,
      make: 'Honda',
      model: 'Civic',
      userBidAmount: 75000.0,
      currentHighestBid: 75000.0,
      endTime: DateTime(2026, 1, 24),
      status: UserBidStatus.active,
      hasDeposited: true,
      isHighestBidder: true,
      userBidCount: 2,
      canAccess: false,
    ),
  ];

  final testWonBids = [
    UserBidEntity(
      id: 'bid-3',
      auctionId: 'auction-3',
      carImageUrl: 'https://example.com/car3.jpg',
      year: 2019,
      make: 'Ford',
      model: 'Mustang',
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
      id: 'bid-4',
      auctionId: 'auction-4',
      carImageUrl: 'https://example.com/car4.jpg',
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

  final testBidsMap = <String, List<UserBidEntity>>{
    'active': testActiveBids,
    'won': testWonBids,
    'lost': testLostBids,
  };

  setUp(() {
    mockRepository = MockBidsRepository();
    useCase = GetUserBidsUseCase(mockRepository);
  });

  group('GetUserBidsUseCase', () {
    test(
      'should return categorized bids when repository call succeeds',
      () async {
        // Arrange
        when(
          () => mockRepository.getUserBids(any()),
        ).thenAnswer((_) async => Right(testBidsMap));

        // Act
        final result = await useCase(testUserId);

        // Assert
        expect(result.isRight(), true);
        result.fold((failure) => fail('Expected Right but got Left'), (
          bidsMap,
        ) {
          expect(bidsMap.keys, containsAll(['active', 'won', 'lost']));
          expect(bidsMap['active']!.length, equals(2));
          expect(bidsMap['won']!.length, equals(1));
          expect(bidsMap['lost']!.length, equals(1));
        });
        verify(() => mockRepository.getUserBids(testUserId)).called(1);
      },
    );

    test('should return empty map when user has no bids', () async {
      // Arrange
      final emptyBidsMap = {
        'active': <UserBidEntity>[],
        'won': <UserBidEntity>[],
        'lost': <UserBidEntity>[],
      };
      when(
        () => mockRepository.getUserBids(any()),
      ).thenAnswer((_) async => Right(emptyBidsMap));

      // Act
      final result = await useCase(testUserId);

      // Assert
      expect(result.isRight(), true);
      result.fold((failure) => fail('Expected Right but got Left'), (bidsMap) {
        expect(bidsMap['active'], isEmpty);
        expect(bidsMap['won'], isEmpty);
        expect(bidsMap['lost'], isEmpty);
      });
    });

    test('should return ServerFailure when repository fails', () async {
      // Arrange
      const failure = ServerFailure('Failed to fetch bids');
      when(
        () => mockRepository.getUserBids(any()),
      ).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(testUserId);

      // Assert
      expect(result, equals(const Left(failure)));
      verify(() => mockRepository.getUserBids(testUserId)).called(1);
    });

    test('should return NetworkFailure when network error occurs', () async {
      // Arrange
      const failure = NetworkFailure('No internet connection');
      when(
        () => mockRepository.getUserBids(any()),
      ).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(testUserId);

      // Assert
      expect(result, equals(const Left(failure)));
    });

    test('should handle large number of bids', () async {
      // Arrange
      final largeBidsList = List.generate(
        100,
        (index) => UserBidEntity(
          id: 'bid-$index',
          auctionId: 'auction-$index',
          carImageUrl: 'https://example.com/car$index.jpg',
          year: 2020,
          make: 'Toyota',
          model: 'Camry',
          userBidAmount: 50000.0 + index * 1000,
          currentHighestBid: 50000.0 + index * 1000,
          endTime: DateTime.now().add(Duration(days: index)),
          status: UserBidStatus.active,
          hasDeposited: true,
          isHighestBidder: true,
          userBidCount: 1,
          canAccess: false,
        ),
      );
      final largeBidsMap = <String, List<UserBidEntity>>{
        'active': largeBidsList,
        'won': <UserBidEntity>[],
        'lost': <UserBidEntity>[],
      };
      when(
        () => mockRepository.getUserBids(any()),
      ).thenAnswer((_) async => Right(largeBidsMap));

      // Act
      final result = await useCase(testUserId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right but got Left'),
        (bidsMap) => expect(bidsMap['active']!.length, equals(100)),
      );
    });
  });
}
