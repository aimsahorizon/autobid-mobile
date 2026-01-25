import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/bids/presentation/controllers/bids_controller.dart';
import 'package:autobid_mobile/modules/bids/domain/usecases/get_user_bids_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';
import 'package:autobid_mobile/modules/bids/domain/entities/user_bid_entity.dart';
import 'package:autobid_mobile/modules/auth/domain/entities/user_entity.dart';
import 'package:autobid_mobile/core/error/failures.dart';

class MockGetUserBidsUseCase extends Mock implements GetUserBidsUseCase {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late BidsController controller;
  late MockGetUserBidsUseCase mockGetUserBidsUseCase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockGetUserBidsUseCase = MockGetUserBidsUseCase();
    mockAuthRepository = MockAuthRepository();
    controller = BidsController(mockGetUserBidsUseCase, mockAuthRepository);
  });

  tearDown(() {
    controller.dispose();
  });

  const testUser = UserEntity(
    id: 'user-123',
    email: 'test@example.com',
    phoneNumber: '+1234567890',
  );

  final activeBid1 = UserBidEntity(
    id: 'bid-1',
    auctionId: 'auction-1',
    carImageUrl: 'https://example.com/car1.jpg',
    year: 2020,
    make: 'Toyota',
    model: 'Supra',
    userBidAmount: 1000,
    currentHighestBid: 1000,
    endTime: DateTime.now().add(const Duration(hours: 1)),
    status: UserBidStatus.active,
    hasDeposited: true,
    isHighestBidder: true,
    userBidCount: 3,
    canAccess: false,
  );

  final activeBid2 = UserBidEntity(
    id: 'bid-2',
    auctionId: 'auction-2',
    carImageUrl: 'https://example.com/car2.jpg',
    year: 2019,
    make: 'Honda',
    model: 'Civic',
    userBidAmount: 2000,
    currentHighestBid: 2500,
    endTime: DateTime.now().add(const Duration(hours: 2)),
    status: UserBidStatus.active,
    hasDeposited: true,
    isHighestBidder: false,
    userBidCount: 2,
    canAccess: false,
  );

  final wonBid = UserBidEntity(
    id: 'bid-3',
    auctionId: 'auction-3',
    carImageUrl: 'https://example.com/car3.jpg',
    year: 2021,
    make: 'BMW',
    model: 'M3',
    userBidAmount: 3000,
    currentHighestBid: 3000,
    endTime: DateTime.now().subtract(const Duration(hours: 1)),
    status: UserBidStatus.won,
    hasDeposited: true,
    isHighestBidder: true,
    userBidCount: 5,
    canAccess: true,
  );

  final lostBid = UserBidEntity(
    id: 'bid-4',
    auctionId: 'auction-4',
    carImageUrl: 'https://example.com/car4.jpg',
    year: 2018,
    make: 'Audi',
    model: 'A4',
    userBidAmount: 1500,
    currentHighestBid: 2000,
    endTime: DateTime.now().subtract(const Duration(hours: 2)),
    status: UserBidStatus.lost,
    hasDeposited: false,
    isHighestBidder: false,
    userBidCount: 1,
    canAccess: false,
  );

  final cancelledBid = UserBidEntity(
    id: 'bid-5',
    auctionId: 'auction-5',
    carImageUrl: 'https://example.com/car5.jpg',
    year: 2022,
    make: 'Mercedes',
    model: 'C-Class',
    userBidAmount: 500,
    currentHighestBid: 1000,
    endTime: DateTime.now().add(const Duration(hours: 3)),
    status: UserBidStatus.cancelled,
    hasDeposited: false,
    isHighestBidder: false,
    userBidCount: 1,
    canAccess: false,
  );

  group('Initial State', () {
    test('should have correct initial values', () {
      expect(controller.activeBids, isEmpty);
      expect(controller.wonBids, isEmpty);
      expect(controller.lostBids, isEmpty);
      expect(controller.cancelledBids, isEmpty);
      expect(controller.isLoading, false);
      expect(controller.errorMessage, isNull);
      expect(controller.hasError, false);
      expect(controller.totalBidsCount, 0);
      expect(controller.winningBidsCount, 0);
      expect(controller.outbidCount, 0);
    });
  });

  group('loadUserBids', () {
    test('should load user bids successfully', () async {
      // Arrange
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(testUser));
      when(() => mockGetUserBidsUseCase.call('user-123')).thenAnswer(
        (_) async => Right({
          'active': [activeBid1, activeBid2],
          'won': [wonBid],
          'lost': [lostBid],
          'cancelled': [cancelledBid],
        }),
      );

      // Act
      await controller.loadUserBids();

      // Assert
      expect(controller.activeBids, [activeBid1, activeBid2]);
      expect(controller.wonBids, [wonBid]);
      expect(controller.lostBids, [lostBid]);
      expect(controller.cancelledBids, [cancelledBid]);
      expect(controller.isLoading, false);
      expect(controller.errorMessage, isNull);
      expect(controller.totalBidsCount, 5);

      verify(() => mockAuthRepository.getCurrentUser()).called(1);
      verify(() => mockGetUserBidsUseCase.call('user-123')).called(1);
    });

    test('should handle empty bid lists', () async {
      // Arrange
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(testUser));
      when(() => mockGetUserBidsUseCase.call('user-123')).thenAnswer(
        (_) async =>
            const Right({'active': [], 'won': [], 'lost': [], 'cancelled': []}),
      );

      // Act
      await controller.loadUserBids();

      // Assert
      expect(controller.activeBids, isEmpty);
      expect(controller.wonBids, isEmpty);
      expect(controller.lostBids, isEmpty);
      expect(controller.cancelledBids, isEmpty);
      expect(controller.totalBidsCount, 0);
    });

    test('should set loading state during load', () async {
      // Arrange
      when(() => mockAuthRepository.getCurrentUser()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return const Right(testUser);
      });
      when(
        () => mockGetUserBidsUseCase.call(any()),
      ).thenAnswer((_) async => const Right({}));

      // Act
      final future = controller.loadUserBids();
      await Future.delayed(const Duration(milliseconds: 5));

      // Assert - During loading
      expect(controller.isLoading, true);

      // Wait for completion
      await future;
      expect(controller.isLoading, false);
    });

    test('should handle user not authenticated', () async {
      // Arrange
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(null));

      // Act
      await controller.loadUserBids();

      // Assert
      expect(controller.errorMessage, 'User not authenticated');
      expect(controller.hasError, true);
      expect(controller.isLoading, false);

      verifyNever(() => mockGetUserBidsUseCase.call(any()));
    });

    test('should handle AuthFailure when getting current user', () async {
      // Arrange
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => Left(AuthFailure('Session expired')));

      // Act
      await controller.loadUserBids();

      // Assert
      expect(controller.errorMessage, 'User not authenticated');
      expect(controller.isLoading, false);
    });

    test('should handle ServerFailure when loading bids', () async {
      // Arrange
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(testUser));
      when(
        () => mockGetUserBidsUseCase.call(any()),
      ).thenAnswer((_) async => Left(ServerFailure('Failed to load bids')));

      // Act
      await controller.loadUserBids();

      // Assert
      expect(controller.errorMessage, 'Failed to load bids');
      expect(controller.hasError, true);
      expect(controller.isLoading, false);
    });

    test('should handle NetworkFailure when offline', () async {
      // Arrange
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(testUser));
      when(
        () => mockGetUserBidsUseCase.call(any()),
      ).thenAnswer((_) async => Left(NetworkFailure('No internet connection')));

      // Act
      await controller.loadUserBids();

      // Assert
      expect(controller.errorMessage, 'No internet connection');
      expect(controller.isLoading, false);
    });

    test('should clear error when starting new load', () async {
      // Arrange - Set initial error
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(null));
      await controller.loadUserBids();
      expect(controller.errorMessage, isNotNull);

      // Act - Try again
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(testUser));
      when(
        () => mockGetUserBidsUseCase.call(any()),
      ).thenAnswer((_) async => const Right({}));
      await controller.loadUserBids();

      // Assert
      expect(controller.errorMessage, isNull);
    });

    test('should notify listeners during load process', () async {
      // Arrange
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(testUser));
      when(
        () => mockGetUserBidsUseCase.call(any()),
      ).thenAnswer((_) async => const Right({}));

      var notificationCount = 0;
      controller.addListener(() => notificationCount++);

      // Act
      await controller.loadUserBids();

      // Assert - Should notify at least twice (loading start + completion)
      expect(notificationCount, greaterThanOrEqualTo(2));
    });

    test('should handle exception during load', () async {
      // Arrange
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenThrow(Exception('Unexpected error'));

      // Act
      await controller.loadUserBids();

      // Assert
      expect(
        controller.errorMessage,
        'Failed to load your bids. Please try again.',
      );
      expect(controller.isLoading, false);
    });
  });

  group('Bid Counts', () {
    setUp(() async {
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(testUser));
      when(() => mockGetUserBidsUseCase.call(any())).thenAnswer(
        (_) async => Right({
          'active': [activeBid1, activeBid2],
          'won': [wonBid],
          'lost': [lostBid],
          'cancelled': [cancelledBid],
        }),
      );
      await controller.loadUserBids();
    });

    test('should calculate total bids count correctly', () {
      expect(controller.totalBidsCount, 5);
    });

    test('should calculate winning bids count correctly', () {
      // activeBid1 has isHighestBidder = true
      expect(controller.winningBidsCount, 1);
    });

    test('should calculate outbid count correctly', () {
      // activeBid2 has isHighestBidder = false
      expect(controller.outbidCount, 1);
    });

    test('should have correct active bids count', () {
      expect(controller.activeBids.length, 2);
    });

    test('should have correct won bids count', () {
      expect(controller.wonBids.length, 1);
    });

    test('should have correct lost bids count', () {
      expect(controller.lostBids.length, 1);
    });

    test('should have correct cancelled bids count', () {
      expect(controller.cancelledBids.length, 1);
    });
  });

  group('refreshActiveBids', () {
    test('should refresh active bids without showing loading state', () async {
      // Arrange - Load initial bids
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(testUser));
      when(() => mockGetUserBidsUseCase.call(any())).thenAnswer(
        (_) async => Right({
          'active': [activeBid1],
          'won': [wonBid],
          'lost': [],
          'cancelled': [],
        }),
      );
      await controller.loadUserBids();

      // Act - Refresh with new active bid
      when(() => mockGetUserBidsUseCase.call(any())).thenAnswer(
        (_) async => Right({
          'active': [activeBid1, activeBid2],
          'won': [wonBid],
          'lost': [],
          'cancelled': [],
        }),
      );
      await controller.refreshActiveBids();

      // Assert
      expect(controller.activeBids, [activeBid1, activeBid2]);
      expect(controller.wonBids, [wonBid]); // Should remain unchanged
      expect(controller.isLoading, false); // Should not show loading
    });

    test('should handle failure silently during refresh', () async {
      // Arrange
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(testUser));
      when(
        () => mockGetUserBidsUseCase.call(any()),
      ).thenAnswer((_) async => Left(ServerFailure('Refresh failed')));

      // Act
      await controller.refreshActiveBids();

      // Assert - Should not set error message
      expect(controller.errorMessage, isNull);
    });

    test('should handle user not authenticated during refresh', () async {
      // Arrange
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(null));

      // Act
      await controller.refreshActiveBids();

      // Assert - Should fail silently
      expect(controller.errorMessage, isNull);
    });
  });

  group('clearError', () {
    test('should clear error message', () async {
      // Arrange - Set error
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(null));
      await controller.loadUserBids();
      expect(controller.errorMessage, isNotNull);

      // Act
      controller.clearError();

      // Assert
      expect(controller.errorMessage, isNull);
      expect(controller.hasError, false);
    });

    test('should notify listeners when clearing error', () {
      // Arrange
      controller.loadUserBids();

      var notified = false;
      controller.addListener(() => notified = true);

      // Act
      controller.clearError();

      // Assert
      expect(notified, true);
    });
  });

  group('Edge Cases', () {
    test('should handle missing categories in bids map', () async {
      // Arrange
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(testUser));
      when(
        () => mockGetUserBidsUseCase.call(any()),
      ).thenAnswer((_) async => Right(<String, List<UserBidEntity>>{}));

      // Act
      await controller.loadUserBids();

      // Assert
      expect(controller.activeBids, isEmpty);
      expect(controller.wonBids, isEmpty);
      expect(controller.lostBids, isEmpty);
      expect(controller.cancelledBids, isEmpty);
    });

    test('should handle only active bids', () async {
      // Arrange
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(testUser));
      when(() => mockGetUserBidsUseCase.call(any())).thenAnswer(
        (_) async => Right({
          'active': [activeBid1, activeBid2],
        }),
      );

      // Act
      await controller.loadUserBids();

      // Assert
      expect(controller.activeBids, [activeBid1, activeBid2]);
      expect(controller.wonBids, isEmpty);
      expect(controller.lostBids, isEmpty);
      expect(controller.totalBidsCount, 2);
    });

    test('should handle only completed bids', () async {
      // Arrange
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(testUser));
      when(() => mockGetUserBidsUseCase.call(any())).thenAnswer(
        (_) async => Right({
          'won': [wonBid],
          'lost': [lostBid],
        }),
      );

      // Act
      await controller.loadUserBids();

      // Assert
      expect(controller.activeBids, isEmpty);
      expect(controller.wonBids, [wonBid]);
      expect(controller.lostBids, [lostBid]);
      expect(controller.totalBidsCount, 2);
    });

    test('should handle all bids being outbid', () async {
      // Arrange
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(testUser));
      when(() => mockGetUserBidsUseCase.call(any())).thenAnswer(
        (_) async => Right({
          'active': [activeBid2], // isHighestBidder = false
        }),
      );

      // Act
      await controller.loadUserBids();

      // Assert
      expect(controller.winningBidsCount, 0);
      expect(controller.outbidCount, 1);
    });

    test('should handle all bids winning', () async {
      // Arrange
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(testUser));
      when(() => mockGetUserBidsUseCase.call(any())).thenAnswer(
        (_) async => Right({
          'active': [activeBid1], // isHighestBidder = true
        }),
      );

      // Act
      await controller.loadUserBids();

      // Assert
      expect(controller.winningBidsCount, 1);
      expect(controller.outbidCount, 0);
    });
  });
}
