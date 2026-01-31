import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/lists/presentation/controllers/lists_controller.dart';
import 'package:autobid_mobile/modules/lists/domain/usecases/get_seller_listings_usecase.dart';
import 'package:autobid_mobile/modules/lists/domain/usecases/stream_seller_listings_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';
import 'package:autobid_mobile/modules/lists/domain/entities/seller_listing_entity.dart';
import 'package:autobid_mobile/modules/auth/domain/entities/user_entity.dart';
import 'package:autobid_mobile/core/error/failures.dart';

class MockGetSellerListingsUseCase extends Mock
    implements GetSellerListingsUseCase {}

class MockStreamSellerListingsUseCase extends Mock
    implements StreamSellerListingsUseCase {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late ListsController controller;
  late MockGetSellerListingsUseCase mockGetSellerListingsUseCase;
  late MockStreamSellerListingsUseCase mockStreamSellerListingsUseCase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockGetSellerListingsUseCase = MockGetSellerListingsUseCase();
    mockStreamSellerListingsUseCase = MockStreamSellerListingsUseCase();
    mockAuthRepository = MockAuthRepository();

    // Default mock behavior for stream
    when(() => mockStreamSellerListingsUseCase.call(any()))
        .thenAnswer((_) => const Stream.empty());

    controller = ListsController(
      mockGetSellerListingsUseCase,
      mockStreamSellerListingsUseCase,
      mockAuthRepository,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  const testUser = UserEntity(
    id: 'user-123',
    email: 'test@example.com',
    phoneNumber: '+1234567890',
  );

  final activeListing = SellerListingEntity(
    id: 'listing-1',
    imageUrl: 'https://example.com/car1.jpg',
    year: 2020,
    make: 'Toyota',
    model: 'Supra',
    status: ListingStatus.active,
    startingPrice: 3000,
    currentBid: 5000,
    totalBids: 10,
    createdAt: DateTime.now(),
    endTime: DateTime.now().add(const Duration(days: 1)),
  );

  final draftListing = SellerListingEntity(
    id: 'listing-2',
    imageUrl: 'https://example.com/car2.jpg',
    year: 2019,
    make: 'Honda',
    model: 'Civic',
    status: ListingStatus.draft,
    startingPrice: 2000,
    totalBids: 0,
    createdAt: DateTime.now(),
  );

  final soldListing = SellerListingEntity(
    id: 'listing-3',
    imageUrl: 'https://example.com/car3.jpg',
    year: 2021,
    make: 'BMW',
    model: 'M3',
    status: ListingStatus.sold,
    startingPrice: 8000,
    currentBid: 10000,
    totalBids: 25,
    createdAt: DateTime.now(),
    endTime: DateTime.now().subtract(const Duration(days: 1)),
    winnerName: 'John Doe',
    soldPrice: 10000,
  );

  final pendingListing = SellerListingEntity(
    id: 'listing-4',
    imageUrl: 'https://example.com/car4.jpg',
    year: 2022,
    make: 'Audi',
    model: 'A4',
    status: ListingStatus.pending,
    startingPrice: 2500,
    totalBids: 0,
    createdAt: DateTime.now(),
  );

  group('Initial State', () {
    test('should have correct initial values', () {
      expect(controller.listings, isEmpty);
      expect(controller.isLoading, false);
      expect(controller.isGridView, true);
      expect(controller.errorMessage, isNull);
    });

    test('should return empty list for any status initially', () {
      expect(controller.getListingsByStatus(ListingStatus.active), isEmpty);
      expect(controller.getListingsByStatus(ListingStatus.draft), isEmpty);
      expect(controller.getListingsByStatus(ListingStatus.sold), isEmpty);
    });

    test('should return zero count for any status initially', () {
      expect(controller.getCountByStatus(ListingStatus.active), 0);
      expect(controller.getCountByStatus(ListingStatus.draft), 0);
      expect(controller.getCountByStatus(ListingStatus.sold), 0);
    });
  });

  group('loadListings', () {
    test('should load listings successfully', () async {
      // Arrange
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(testUser));
      when(() => mockGetSellerListingsUseCase.call('user-123')).thenAnswer(
        (_) async => Right({
          ListingStatus.active: [activeListing],
          ListingStatus.draft: [draftListing],
          ListingStatus.sold: [soldListing],
          ListingStatus.pending: [pendingListing],
        }),
      );

      // Act
      await controller.loadListings();

      // Assert
      expect(controller.getListingsByStatus(ListingStatus.active), [
        activeListing,
      ]);
      expect(controller.getListingsByStatus(ListingStatus.draft), [
        draftListing,
      ]);
      expect(controller.getListingsByStatus(ListingStatus.sold), [soldListing]);
      expect(controller.getListingsByStatus(ListingStatus.pending), [
        pendingListing,
      ]);
      expect(controller.isLoading, false);
      expect(controller.errorMessage, isNull);

      verify(() => mockAuthRepository.getCurrentUser()).called(1);
      verify(() => mockGetSellerListingsUseCase.call('user-123')).called(1);
    });

    test('should handle empty listings', () async {
      // Arrange
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(testUser));
      when(
        () => mockGetSellerListingsUseCase.call('user-123'),
      ).thenAnswer((_) async => const Right({}));

      // Act
      await controller.loadListings();

      // Assert
      expect(controller.getListingsByStatus(ListingStatus.active), isEmpty);
      expect(controller.getCountByStatus(ListingStatus.active), 0);
      expect(controller.isLoading, false);
    });

    test('should set loading state during load', () async {
      // Arrange
      when(() => mockAuthRepository.getCurrentUser()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return const Right(testUser);
      });
      when(
        () => mockGetSellerListingsUseCase.call(any()),
      ).thenAnswer((_) async => const Right({}));

      // Act
      final future = controller.loadListings();
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
      await controller.loadListings();

      // Assert
      expect(controller.errorMessage, 'User not authenticated');
      expect(controller.isLoading, false);

      verifyNever(() => mockGetSellerListingsUseCase.call(any()));
    });

    test('should handle AuthFailure when getting current user', () async {
      // Arrange
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => Left(AuthFailure('Session expired')));

      // Act
      await controller.loadListings();

      // Assert
      expect(controller.errorMessage, 'User not authenticated');
      expect(controller.isLoading, false);
    });

    test('should handle ServerFailure when loading listings', () async {
      // Arrange
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(testUser));
      when(
        () => mockGetSellerListingsUseCase.call(any()),
      ).thenAnswer((_) async => Left(ServerFailure('Failed to load listings')));

      // Act
      await controller.loadListings();

      // Assert
      expect(controller.errorMessage, 'Failed to load listings');
      expect(controller.isLoading, false);
    });

    test('should handle NetworkFailure when offline', () async {
      // Arrange
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(testUser));
      when(
        () => mockGetSellerListingsUseCase.call(any()),
      ).thenAnswer((_) async => Left(NetworkFailure('No internet connection')));

      // Act
      await controller.loadListings();

      // Assert
      expect(controller.errorMessage, 'No internet connection');
      expect(controller.isLoading, false);
    });

    test('should clear error when starting new load', () async {
      // Arrange - Set initial error
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(null));
      await controller.loadListings();
      expect(controller.errorMessage, isNotNull);

      // Act - Try again
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(testUser));
      when(
        () => mockGetSellerListingsUseCase.call(any()),
      ).thenAnswer((_) async => const Right({}));
      await controller.loadListings();

      // Assert
      expect(controller.errorMessage, isNull);
    });

    test('should notify listeners during load process', () async {
      // Arrange
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(testUser));
      when(
        () => mockGetSellerListingsUseCase.call(any()),
      ).thenAnswer((_) async => const Right({}));

      var notificationCount = 0;
      controller.addListener(() => notificationCount++);

      // Act
      await controller.loadListings();

      // Assert - Should notify at least twice (loading start + completion)
      expect(notificationCount, greaterThanOrEqualTo(2));
    });

    test('should handle exception during load', () async {
      // Arrange
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenThrow(Exception('Unexpected error'));

      // Act
      await controller.loadListings();

      // Assert
      expect(controller.errorMessage, contains('Failed to load listings'));
      expect(controller.isLoading, false);
    });
  });

  group('getListingsByStatus', () {
    setUp(() async {
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(testUser));
      when(() => mockGetSellerListingsUseCase.call(any())).thenAnswer(
        (_) async => Right({
          ListingStatus.active: [activeListing],
          ListingStatus.draft: [draftListing],
          ListingStatus.sold: [soldListing],
        }),
      );
      await controller.loadListings();
    });

    test('should return active listings', () {
      expect(controller.getListingsByStatus(ListingStatus.active), [
        activeListing,
      ]);
    });

    test('should return draft listings', () {
      expect(controller.getListingsByStatus(ListingStatus.draft), [
        draftListing,
      ]);
    });

    test('should return sold listings', () {
      expect(controller.getListingsByStatus(ListingStatus.sold), [soldListing]);
    });

    test('should return empty list for status with no listings', () {
      expect(controller.getListingsByStatus(ListingStatus.pending), isEmpty);
    });
  });

  group('getCountByStatus', () {
    setUp(() async {
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(testUser));
      when(() => mockGetSellerListingsUseCase.call(any())).thenAnswer(
        (_) async => Right({
          ListingStatus.active: [activeListing],
          ListingStatus.draft: [draftListing],
          ListingStatus.sold: [soldListing],
        }),
      );
      await controller.loadListings();
    });

    test('should return correct count for active listings', () {
      expect(controller.getCountByStatus(ListingStatus.active), 1);
    });

    test('should return correct count for draft listings', () {
      expect(controller.getCountByStatus(ListingStatus.draft), 1);
    });

    test('should return correct count for sold listings', () {
      expect(controller.getCountByStatus(ListingStatus.sold), 1);
    });

    test('should return zero for status with no listings', () {
      expect(controller.getCountByStatus(ListingStatus.pending), 0);
    });
  });

  group('toggleViewMode', () {
    test('should toggle from grid to list view', () {
      // Initial state is grid view
      expect(controller.isGridView, true);

      // Toggle to list view
      controller.toggleViewMode();
      expect(controller.isGridView, false);
    });

    test('should toggle from list to grid view', () {
      // Toggle to list view
      controller.toggleViewMode();
      expect(controller.isGridView, false);

      // Toggle back to grid view
      controller.toggleViewMode();
      expect(controller.isGridView, true);
    });

    test('should notify listeners when toggled', () {
      var notified = false;
      controller.addListener(() => notified = true);

      controller.toggleViewMode();
      expect(notified, true);
    });

    test('should toggle multiple times correctly', () {
      controller.toggleViewMode(); // false
      controller.toggleViewMode(); // true
      controller.toggleViewMode(); // false
      controller.toggleViewMode(); // true

      expect(controller.isGridView, true);
    });
  });

  group('Edge Cases', () {
    test('should handle multiple listings of same status', () async {
      // Arrange
      final activeListing2 = SellerListingEntity(
        id: 'listing-5',
        imageUrl: 'https://example.com/car5.jpg',
        year: 2023,
        make: 'Tesla',
        model: 'Model 3',
        status: ListingStatus.active,
        startingPrice: 6000,
        currentBid: 8000,
        totalBids: 15,
        createdAt: DateTime.now(),
        endTime: DateTime.now().add(const Duration(days: 2)),
      );

      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(testUser));
      when(() => mockGetSellerListingsUseCase.call(any())).thenAnswer(
        (_) async => Right({
          ListingStatus.active: [activeListing, activeListing2],
        }),
      );

      // Act
      await controller.loadListings();

      // Assert
      expect(controller.getCountByStatus(ListingStatus.active), 2);
      expect(controller.getListingsByStatus(ListingStatus.active), [
        activeListing,
        activeListing2,
      ]);
    });

    test('should handle only draft listings', () async {
      // Arrange
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(testUser));
      when(() => mockGetSellerListingsUseCase.call(any())).thenAnswer(
        (_) async => Right({
          ListingStatus.draft: [draftListing],
        }),
      );

      // Act
      await controller.loadListings();

      // Assert
      expect(controller.getCountByStatus(ListingStatus.draft), 1);
      expect(controller.getCountByStatus(ListingStatus.active), 0);
      expect(controller.getCountByStatus(ListingStatus.sold), 0);
    });

    test('should handle all status types', () async {
      // Arrange
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(testUser));
      when(() => mockGetSellerListingsUseCase.call(any())).thenAnswer(
        (_) async => Right({
          ListingStatus.active: [activeListing],
          ListingStatus.draft: [draftListing],
          ListingStatus.sold: [soldListing],
          ListingStatus.pending: [pendingListing],
        }),
      );

      // Act
      await controller.loadListings();

      // Assert
      expect(controller.getCountByStatus(ListingStatus.active), 1);
      expect(controller.getCountByStatus(ListingStatus.draft), 1);
      expect(controller.getCountByStatus(ListingStatus.sold), 1);
      expect(controller.getCountByStatus(ListingStatus.pending), 1);
    });
  });
}
