import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:autobid_mobile/modules/profile/domain/usecases/get_token_balance_usecase.dart';
import 'package:autobid_mobile/modules/profile/domain/usecases/get_token_packages_usecase.dart';
import 'package:autobid_mobile/modules/profile/domain/usecases/purchase_token_package_usecase.dart';
import 'package:autobid_mobile/modules/profile/domain/usecases/consume_listing_token_usecase.dart';
import 'package:autobid_mobile/modules/profile/domain/usecases/consume_bidding_token_usecase.dart';
import 'package:autobid_mobile/modules/profile/domain/repositories/pricing_repository.dart';
import 'package:autobid_mobile/modules/profile/domain/entities/pricing_entity.dart';

class MockPricingRepository extends Mock implements PricingRepository {}

void main() {
  late GetTokenBalanceUsecase getTokenBalanceUseCase;
  late GetTokenPackagesUsecase getTokenPackagesUseCase;
  late PurchaseTokenPackageUsecase purchaseTokenPackageUseCase;
  late ConsumeListingTokenUsecase consumeListingTokenUseCase;
  late ConsumeBiddingTokenUsecase consumeBiddingTokenUseCase;
  late MockPricingRepository mockRepository;

  setUp(() {
    mockRepository = MockPricingRepository();
    getTokenBalanceUseCase = GetTokenBalanceUsecase(repository: mockRepository);
    getTokenPackagesUseCase = GetTokenPackagesUsecase(
      repository: mockRepository,
    );
    purchaseTokenPackageUseCase = PurchaseTokenPackageUsecase(
      repository: mockRepository,
    );
    consumeListingTokenUseCase = ConsumeListingTokenUsecase(
      repository: mockRepository,
    );
    consumeBiddingTokenUseCase = ConsumeBiddingTokenUsecase(
      repository: mockRepository,
    );
  });

  const testUserId = 'user-123';
  const testPackageId = 'pkg-starter';
  const testReferenceId = 'ref-listing-123';

  final testBalance = TokenBalanceEntity(
    userId: testUserId,
    listingTokens: 5,
    biddingTokens: 10,
    updatedAt: DateTime(2024, 1, 1),
  );

  final testPackages = [
    TokenPackageEntity(
      id: 'pkg-starter',
      type: TokenType.listing,
      tokens: 5,
      bonusTokens: 0,
      price: 99.99,
      description: '5 listing tokens',
    ),
    TokenPackageEntity(
      id: 'pkg-pro',
      type: TokenType.bidding,
      tokens: 30,
      bonusTokens: 10,
      price: 249.99,
      description: '30 bidding tokens + 10 bonus',
    ),
  ];

  group('GetTokenBalanceUsecase', () {
    test('should get token balance successfully', () async {
      // Arrange
      when(
        () => mockRepository.getTokenBalance(testUserId),
      ).thenAnswer((_) async => testBalance);

      // Act
      final result = await getTokenBalanceUseCase(testUserId);

      // Assert
      expect(result.userId, testUserId);
      expect(result.listingTokens, 5);
      expect(result.biddingTokens, 10);
      expect(result.updatedAt, isA<DateTime>());

      verify(() => mockRepository.getTokenBalance(testUserId)).called(1);
    });

    test('should get balance with zero tokens', () async {
      // Arrange
      final zeroBalance = TokenBalanceEntity(
        userId: testUserId,
        listingTokens: 0,
        biddingTokens: 0,
        updatedAt: DateTime(2024, 1, 1),
      );
      when(
        () => mockRepository.getTokenBalance(testUserId),
      ).thenAnswer((_) async => zeroBalance);

      // Act
      final result = await getTokenBalanceUseCase(testUserId);

      // Assert
      expect(result.listingTokens, 0);
      expect(result.biddingTokens, 0);
    });

    test('should throw exception when user not found', () async {
      // Arrange
      when(
        () => mockRepository.getTokenBalance(any()),
      ).thenThrow(Exception('User not found'));

      // Act & Assert
      expect(() => getTokenBalanceUseCase('non-existent'), throwsException);
    });

    test('should get updated balance after purchase', () async {
      // Arrange
      final updatedBalance = TokenBalanceEntity(
        userId: testUserId,
        listingTokens: 20,
        biddingTokens: 40,
        updatedAt: DateTime(2024, 1, 5),
      );
      when(
        () => mockRepository.getTokenBalance(testUserId),
      ).thenAnswer((_) async => updatedBalance);

      // Act
      final result = await getTokenBalanceUseCase(testUserId);

      // Assert
      expect(result.listingTokens, 20);
      expect(result.biddingTokens, 40);
      expect(result.updatedAt.isAfter(DateTime(2024, 1, 1)), true);
    });
  });

  group('GetTokenPackagesUsecase', () {
    test('should get all token packages', () async {
      // Arrange
      when(
        () => mockRepository.getTokenPackages(),
      ).thenAnswer((_) async => testPackages);

      // Act
      final result = await getTokenPackagesUseCase();

      // Assert
      expect(result.length, 2);
      expect(result.first.description, contains('5 listing'));
      expect(result.last.description, contains('30 bidding'));
      expect(result.last.bonusTokens, 10);

      verify(() => mockRepository.getTokenPackages()).called(1);
    });

    test('should get packages with bonus tokens', () async {
      // Arrange
      when(
        () => mockRepository.getTokenPackages(),
      ).thenAnswer((_) async => testPackages);

      // Act
      final result = await getTokenPackagesUseCase();

      // Assert
      final packagesWithBonus = result
          .where((pkg) => pkg.bonusTokens > 0)
          .toList();
      expect(packagesWithBonus.length, 1);
      expect(packagesWithBonus.first.bonusTokens, 10);
    });

    test('should return empty list when no packages available', () async {
      // Arrange
      when(() => mockRepository.getTokenPackages()).thenAnswer((_) async => []);

      // Act
      final result = await getTokenPackagesUseCase();

      // Assert
      expect(result, isEmpty);
    });

    test('should handle packages with different price tiers', () async {
      // Arrange
      when(
        () => mockRepository.getTokenPackages(),
      ).thenAnswer((_) async => testPackages);

      // Act
      final result = await getTokenPackagesUseCase();

      // Assert
      expect(result.first.price, 99.99);
      expect(result.last.price, 249.99);
      expect(result.last.price > result.first.price, true);
    });
  });

  group('PurchaseTokenPackageUsecase', () {
    test('should purchase token package successfully', () async {
      // Arrange
      final updatedBalance = TokenBalanceEntity(
        userId: testUserId,
        listingTokens: 20,
        biddingTokens: 40,
        updatedAt: DateTime(2024, 1, 2),
      );

      when(
        () => mockRepository.purchaseTokenPackage(
          userId: testUserId,
          packageId: testPackageId,
          amount: 249.99,
        ),
      ).thenAnswer((_) async => updatedBalance);

      // Act
      final result = await purchaseTokenPackageUseCase(
        userId: testUserId,
        packageId: testPackageId,
        amount: 249.99,
      );

      // Assert
      expect(result.listingTokens, 20);
      expect(result.biddingTokens, 40);

      verify(
        () => mockRepository.purchaseTokenPackage(
          userId: testUserId,
          packageId: testPackageId,
          amount: 249.99,
        ),
      ).called(1);
    });

    test('should throw exception when payment fails', () async {
      // Arrange
      when(
        () => mockRepository.purchaseTokenPackage(
          userId: any(named: 'userId'),
          packageId: any(named: 'packageId'),
          amount: any(named: 'amount'),
        ),
      ).thenThrow(Exception('Payment failed'));

      // Act & Assert
      expect(
        () => purchaseTokenPackageUseCase(
          userId: testUserId,
          packageId: testPackageId,
          amount: 249.99,
        ),
        throwsException,
      );
    });

    test('should throw exception when package not found', () async {
      // Arrange
      when(
        () => mockRepository.purchaseTokenPackage(
          userId: any(named: 'userId'),
          packageId: any(named: 'packageId'),
          amount: any(named: 'amount'),
        ),
      ).thenThrow(Exception('Package not found'));

      // Act & Assert
      expect(
        () => purchaseTokenPackageUseCase(
          userId: testUserId,
          packageId: 'invalid-pkg',
          amount: 99.99,
        ),
        throwsException,
      );
    });

    test('should purchase and increment existing balance', () async {
      // Arrange
      final newBalance = TokenBalanceEntity(
        userId: testUserId,
        listingTokens: testBalance.listingTokens + 15,
        biddingTokens: testBalance.biddingTokens + 30,
        updatedAt: DateTime(2024, 1, 3),
      );

      when(
        () => mockRepository.purchaseTokenPackage(
          userId: testUserId,
          packageId: 'pkg-pro',
          amount: 249.99,
        ),
      ).thenAnswer((_) async => newBalance);

      // Act
      final result = await purchaseTokenPackageUseCase(
        userId: testUserId,
        packageId: 'pkg-pro',
        amount: 249.99,
      );

      // Assert
      expect(result.listingTokens, testBalance.listingTokens + 15);
      expect(result.biddingTokens, testBalance.biddingTokens + 30);
    });
  });

  group('ConsumeListingTokenUsecase', () {
    test('should consume listing token successfully', () async {
      // Arrange
      when(
        () => mockRepository.consumeListingToken(
          userId: testUserId,
          referenceId: testReferenceId,
        ),
      ).thenAnswer((_) async => true);

      // Act
      final result = await consumeListingTokenUseCase(
        userId: testUserId,
        referenceId: testReferenceId,
      );

      // Assert
      expect(result, true);

      verify(
        () => mockRepository.consumeListingToken(
          userId: testUserId,
          referenceId: testReferenceId,
        ),
      ).called(1);
    });

    test('should return false when insufficient tokens', () async {
      // Arrange
      when(
        () => mockRepository.consumeListingToken(
          userId: any(named: 'userId'),
          referenceId: any(named: 'referenceId'),
        ),
      ).thenAnswer((_) async => false);

      // Act
      final result = await consumeListingTokenUseCase(
        userId: testUserId,
        referenceId: testReferenceId,
      );

      // Assert
      expect(result, false);
    });

    test('should throw exception when consumption fails', () async {
      // Arrange
      when(
        () => mockRepository.consumeListingToken(
          userId: any(named: 'userId'),
          referenceId: any(named: 'referenceId'),
        ),
      ).thenThrow(Exception('Failed to consume token'));

      // Act & Assert
      expect(
        () => consumeListingTokenUseCase(
          userId: testUserId,
          referenceId: testReferenceId,
        ),
        throwsException,
      );
    });

    test('should pass correct reference id for listing', () async {
      // Arrange
      const listingId = 'listing-456';
      when(
        () => mockRepository.consumeListingToken(
          userId: testUserId,
          referenceId: listingId,
        ),
      ).thenAnswer((_) async => true);

      // Act
      await consumeListingTokenUseCase(
        userId: testUserId,
        referenceId: listingId,
      );

      // Assert
      verify(
        () => mockRepository.consumeListingToken(
          userId: testUserId,
          referenceId: listingId,
        ),
      ).called(1);
    });
  });

  group('ConsumeBiddingTokenUsecase', () {
    test('should consume bidding token successfully', () async {
      // Arrange
      when(
        () => mockRepository.consumeBiddingToken(
          userId: testUserId,
          referenceId: 'auction-123',
        ),
      ).thenAnswer((_) async => true);

      // Act
      final result = await consumeBiddingTokenUseCase(
        userId: testUserId,
        referenceId: 'auction-123',
      );

      // Assert
      expect(result, true);

      verify(
        () => mockRepository.consumeBiddingToken(
          userId: testUserId,
          referenceId: 'auction-123',
        ),
      ).called(1);
    });

    test('should return false when insufficient bidding tokens', () async {
      // Arrange
      when(
        () => mockRepository.consumeBiddingToken(
          userId: any(named: 'userId'),
          referenceId: any(named: 'referenceId'),
        ),
      ).thenAnswer((_) async => false);

      // Act
      final result = await consumeBiddingTokenUseCase(
        userId: testUserId,
        referenceId: 'auction-123',
      );

      // Assert
      expect(result, false);
    });

    test('should throw exception when consumption fails', () async {
      // Arrange
      when(
        () => mockRepository.consumeBiddingToken(
          userId: any(named: 'userId'),
          referenceId: any(named: 'referenceId'),
        ),
      ).thenThrow(Exception('Failed to consume bidding token'));

      // Act & Assert
      expect(
        () => consumeBiddingTokenUseCase(
          userId: testUserId,
          referenceId: 'auction-123',
        ),
        throwsException,
      );
    });

    test('should pass correct reference id for auction', () async {
      // Arrange
      const auctionId = 'auction-789';
      when(
        () => mockRepository.consumeBiddingToken(
          userId: testUserId,
          referenceId: auctionId,
        ),
      ).thenAnswer((_) async => true);

      // Act
      await consumeBiddingTokenUseCase(
        userId: testUserId,
        referenceId: auctionId,
      );

      // Assert
      verify(
        () => mockRepository.consumeBiddingToken(
          userId: testUserId,
          referenceId: auctionId,
        ),
      ).called(1);
    });
  });
}
