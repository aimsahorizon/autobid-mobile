import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/guest/presentation/controllers/guest_controller.dart';
import 'package:autobid_mobile/modules/guest/domain/usecases/check_account_status_usecase.dart';
import 'package:autobid_mobile/modules/guest/domain/usecases/get_guest_auction_listings_usecase.dart';
import 'package:autobid_mobile/modules/guest/domain/entities/account_status_entity.dart';
import 'package:autobid_mobile/core/error/failures.dart';

class MockCheckAccountStatusUseCase extends Mock
    implements CheckAccountStatusUseCase {}

class MockGetGuestAuctionListingsUseCase extends Mock
    implements GetGuestAuctionListingsUseCase {}

void main() {
  late GuestController controller;
  late MockCheckAccountStatusUseCase mockCheckAccountStatusUseCase;
  late MockGetGuestAuctionListingsUseCase mockGetGuestAuctionListingsUseCase;

  setUp(() {
    mockCheckAccountStatusUseCase = MockCheckAccountStatusUseCase();
    mockGetGuestAuctionListingsUseCase = MockGetGuestAuctionListingsUseCase();
    controller = GuestController(
      checkAccountStatusUseCase: mockCheckAccountStatusUseCase,
      getGuestAuctionListingsUseCase: mockGetGuestAuctionListingsUseCase,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  const testEmail = 'test@example.com';

  final testAccountStatus = AccountStatusEntity(
    userId: 'user-123',
    status: AccountStatus.approved,
    submittedAt: DateTime(2024, 1, 1),
    reviewedAt: DateTime(2024, 1, 2),
    reviewNotes: 'Your account is approved',
    userEmail: testEmail,
    userName: 'Test User',
  );

  final testAuctions = [
    {
      'id': 'auction-1',
      'title': 'Toyota Camry 2020',
      'currentBid': 15000.0,
      'imageUrl': 'https://example.com/car1.jpg',
    },
    {
      'id': 'auction-2',
      'title': 'Honda Civic 2019',
      'currentBid': 12000.0,
      'imageUrl': 'https://example.com/car2.jpg',
    },
  ];

  group('GuestController', () {
    group('Initial State', () {
      test('should have correct initial values', () {
        expect(controller.currentTabIndex, 0);
        expect(controller.isLoadingStatus, false);
        expect(controller.isLoadingAuctions, false);
        expect(controller.accountStatus, isNull);
        expect(controller.auctions, isEmpty);
        expect(controller.errorMessage, isNull);
        expect(controller.statusEmail, isNull);
      });
    });

    group('setTabIndex', () {
      test('should update tab index and notify listeners', () {
        // Arrange
        var notified = false;
        controller.addListener(() => notified = true);

        // Act
        controller.setTabIndex(1);

        // Assert
        expect(controller.currentTabIndex, 1);
        expect(notified, true);
      });
    });

    group('checkAccountStatus', () {
      test('should check account status successfully', () async {
        // Arrange
        when(
          () => mockCheckAccountStatusUseCase(testEmail),
        ).thenAnswer((_) async => Right(testAccountStatus));

        // Act
        await controller.checkAccountStatus(testEmail);

        // Assert
        expect(controller.isLoadingStatus, false);
        expect(controller.accountStatus, testAccountStatus);
        expect(controller.errorMessage, isNull);
        expect(controller.statusEmail, testEmail);

        verify(() => mockCheckAccountStatusUseCase(testEmail)).called(1);
      });

      test('should handle null account status (not found)', () async {
        // Arrange
        when(
          () => mockCheckAccountStatusUseCase(testEmail),
        ).thenAnswer((_) async => const Right(null));

        // Act
        await controller.checkAccountStatus(testEmail);

        // Assert
        expect(controller.isLoadingStatus, false);
        expect(controller.accountStatus, isNull);
        expect(controller.errorMessage, isNull);
        expect(controller.statusEmail, testEmail);
      });

      test('should set loading state during check', () async {
        // Arrange
        when(() => mockCheckAccountStatusUseCase(testEmail)).thenAnswer((
          _,
        ) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return Right(testAccountStatus);
        });

        // Act
        final future = controller.checkAccountStatus(testEmail);
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert (during loading)
        expect(controller.isLoadingStatus, true);

        await future;

        // Assert (after loading)
        expect(controller.isLoadingStatus, false);
      });

      test('should handle failure when checking account status', () async {
        // Arrange
        when(
          () => mockCheckAccountStatusUseCase(testEmail),
        ).thenAnswer((_) async => Left(ServerFailure('Server error')));

        // Act
        await controller.checkAccountStatus(testEmail);

        // Assert
        expect(controller.isLoadingStatus, false);
        expect(controller.accountStatus, isNull);
        expect(controller.errorMessage, 'Server error');
      });

      test('should handle network failure', () async {
        // Arrange
        when(() => mockCheckAccountStatusUseCase(testEmail)).thenAnswer(
          (_) async => Left(NetworkFailure('No internet connection')),
        );

        // Act
        await controller.checkAccountStatus(testEmail);

        // Assert
        expect(controller.isLoadingStatus, false);
        expect(controller.errorMessage, 'No internet connection');
      });

      test('should clear previous error on new check', () async {
        // Arrange - First call fails
        when(
          () => mockCheckAccountStatusUseCase(testEmail),
        ).thenAnswer((_) async => Left(ServerFailure('Server error')));

        await controller.checkAccountStatus(testEmail);
        expect(controller.errorMessage, 'Server error');

        // Arrange - Second call succeeds
        when(
          () => mockCheckAccountStatusUseCase(testEmail),
        ).thenAnswer((_) async => Right(testAccountStatus));

        // Act
        await controller.checkAccountStatus(testEmail);

        // Assert
        expect(controller.errorMessage, isNull);
        expect(controller.accountStatus, testAccountStatus);
      });
    });

    group('loadGuestAuctions', () {
      test('should load guest auctions successfully', () async {
        // Arrange
        when(
          () => mockGetGuestAuctionListingsUseCase(),
        ).thenAnswer((_) async => Right(testAuctions));

        // Act
        await controller.loadGuestAuctions();

        // Assert
        expect(controller.isLoadingAuctions, false);
        expect(controller.auctions, testAuctions);
        expect(controller.auctions.length, 2);
        expect(controller.errorMessage, isNull);

        verify(() => mockGetGuestAuctionListingsUseCase()).called(1);
      });

      test('should handle empty auction list', () async {
        // Arrange
        when(
          () => mockGetGuestAuctionListingsUseCase(),
        ).thenAnswer((_) async => const Right([]));

        // Act
        await controller.loadGuestAuctions();

        // Assert
        expect(controller.isLoadingAuctions, false);
        expect(controller.auctions, isEmpty);
        expect(controller.errorMessage, isNull);
      });

      test('should set loading state during load', () async {
        // Arrange
        when(() => mockGetGuestAuctionListingsUseCase()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return Right(testAuctions);
        });

        // Act
        final future = controller.loadGuestAuctions();
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert (during loading)
        expect(controller.isLoadingAuctions, true);

        await future;

        // Assert (after loading)
        expect(controller.isLoadingAuctions, false);
      });

      test('should handle failure when loading auctions', () async {
        // Arrange
        when(() => mockGetGuestAuctionListingsUseCase()).thenAnswer(
          (_) async => Left(ServerFailure('Failed to fetch auctions')),
        );

        // Act
        await controller.loadGuestAuctions();

        // Assert
        expect(controller.isLoadingAuctions, false);
        expect(controller.auctions, isEmpty);
        expect(controller.errorMessage, 'Failed to fetch auctions');
      });

      test('should handle network failure', () async {
        // Arrange
        when(() => mockGetGuestAuctionListingsUseCase()).thenAnswer(
          (_) async => Left(NetworkFailure('No internet connection')),
        );

        // Act
        await controller.loadGuestAuctions();

        // Assert
        expect(controller.isLoadingAuctions, false);
        expect(controller.auctions, isEmpty);
        expect(controller.errorMessage, 'No internet connection');
      });

      test('should clear previous auctions on failure', () async {
        // Arrange - First call succeeds
        when(
          () => mockGetGuestAuctionListingsUseCase(),
        ).thenAnswer((_) async => Right(testAuctions));

        await controller.loadGuestAuctions();
        expect(controller.auctions.length, 2);

        // Arrange - Second call fails
        when(
          () => mockGetGuestAuctionListingsUseCase(),
        ).thenAnswer((_) async => Left(ServerFailure('Server error')));

        // Act
        await controller.loadGuestAuctions();

        // Assert
        expect(controller.auctions, isEmpty);
        expect(controller.errorMessage, 'Server error');
      });
    });

    group('clearError', () {
      test('should clear error message and notify listeners', () async {
        // Arrange - Set error
        when(
          () => mockCheckAccountStatusUseCase(testEmail),
        ).thenAnswer((_) async => Left(ServerFailure('Server error')));

        await controller.checkAccountStatus(testEmail);
        expect(controller.errorMessage, 'Server error');

        var notified = false;
        controller.addListener(() => notified = true);

        // Act
        controller.clearError();

        // Assert
        expect(controller.errorMessage, isNull);
        expect(notified, true);
      });
    });

    group('clearAccountStatus', () {
      test('should clear account status and email', () async {
        // Arrange - Set account status
        when(
          () => mockCheckAccountStatusUseCase(testEmail),
        ).thenAnswer((_) async => Right(testAccountStatus));

        await controller.checkAccountStatus(testEmail);
        expect(controller.accountStatus, testAccountStatus);
        expect(controller.statusEmail, testEmail);

        // Act
        controller.clearAccountStatus();

        // Assert
        expect(controller.accountStatus, isNull);
        expect(controller.statusEmail, isNull);
      });

      test('should notify listeners when clearing', () {
        // Arrange
        var notified = false;
        controller.addListener(() => notified = true);

        // Act
        controller.clearAccountStatus();

        // Assert
        expect(notified, true);
      });
    });
  });
}
