import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/browse/domain/entities/auction_detail_entity.dart';
import 'package:autobid_mobile/modules/browse/domain/entities/bid_history_entity.dart';
import 'package:autobid_mobile/modules/browse/domain/entities/qa_entity.dart';
import 'package:autobid_mobile/modules/browse/domain/usecases/get_auction_detail_usecase.dart';
import 'package:autobid_mobile/modules/browse/domain/usecases/get_bid_history_usecase.dart';
import 'package:autobid_mobile/modules/browse/domain/usecases/place_bid_usecase.dart';
import 'package:autobid_mobile/modules/browse/domain/usecases/get_questions_usecase.dart';
import 'package:autobid_mobile/modules/browse/domain/usecases/post_question_usecase.dart';
import 'package:autobid_mobile/modules/browse/domain/usecases/like_question_usecase.dart';
import 'package:autobid_mobile/modules/browse/domain/usecases/unlike_question_usecase.dart';
import 'package:autobid_mobile/modules/browse/domain/usecases/get_bid_increment_usecase.dart';
import 'package:autobid_mobile/modules/browse/domain/usecases/upsert_bid_increment_usecase.dart';
import 'package:autobid_mobile/modules/browse/domain/usecases/process_deposit_usecase.dart';
import 'package:autobid_mobile/modules/browse/presentation/controllers/auction_detail_controller.dart';
import 'package:autobid_mobile/modules/profile/domain/usecases/consume_bidding_token_usecase.dart';
import 'package:autobid_mobile/core/error/failures.dart';

// Mock UseCases
class MockGetAuctionDetailUseCase extends Mock
    implements GetAuctionDetailUseCase {}

class MockGetBidHistoryUseCase extends Mock implements GetBidHistoryUseCase {}

class MockPlaceBidUseCase extends Mock implements PlaceBidUseCase {}

class MockGetQuestionsUseCase extends Mock implements GetQuestionsUseCase {}

class MockPostQuestionUseCase extends Mock implements PostQuestionUseCase {}

class MockLikeQuestionUseCase extends Mock implements LikeQuestionUseCase {}

class MockUnlikeQuestionUseCase extends Mock implements UnlikeQuestionUseCase {}

class MockGetBidIncrementUseCase extends Mock
    implements GetBidIncrementUseCase {}

class MockUpsertBidIncrementUseCase extends Mock
    implements UpsertBidIncrementUseCase {}

class MockProcessDepositUseCase extends Mock implements ProcessDepositUseCase {}

class MockConsumeBiddingTokenUsecase extends Mock
    implements ConsumeBiddingTokenUsecase {}

void main() {
  late AuctionDetailController controller;
  late MockGetAuctionDetailUseCase mockGetAuctionDetail;
  late MockGetBidHistoryUseCase mockGetBidHistory;
  late MockPlaceBidUseCase mockPlaceBid;
  late MockGetQuestionsUseCase mockGetQuestions;
  late MockPostQuestionUseCase mockPostQuestion;
  late MockLikeQuestionUseCase mockLikeQuestion;
  late MockUnlikeQuestionUseCase mockUnlikeQuestion;
  late MockGetBidIncrementUseCase mockGetBidIncrement;
  late MockUpsertBidIncrementUseCase mockUpsertBidIncrement;
  late MockProcessDepositUseCase mockProcessDeposit;
  late MockConsumeBiddingTokenUsecase mockConsumeBiddingToken;

  const testUserId = 'test-user-123';
  const testAuctionId = 'auction-123';

  // Test data
  final testAuction = AuctionDetailEntity(
    id: testAuctionId,
    carImageUrl: 'https://example.com/car.jpg',
    currentBid: 50000.0,
    minimumBid: 40000.0,
    minBidIncrement: 1000.0,
    enableIncrementalBidding: true,
    isReserveMet: false,
    showReservePrice: false,
    reservePrice: 55000.0,
    watchersCount: 10,
    biddersCount: 5,
    totalBids: 8,
    endTime: DateTime.now().add(const Duration(days: 1)),
    status: 'active',
    photos: const CarPhotosEntity(
      exterior: [],
      interior: [],
      engine: [],
      details: [],
      documents: [],
    ),
    hasUserDeposited: false,
    snipeGuardEnabled: true,
    snipeGuardThresholdSeconds: 300,
    snipeGuardExtendSeconds: 300,
    brand: 'Toyota',
    model: 'Camry',
    year: 2020,
  );

  final testBidHistory = [
    BidHistoryEntity(
      id: 'bid-1',
      auctionId: testAuctionId,
      amount: 45000.0,
      bidderName: 'User A',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isCurrentUser: false,
      isWinning: false,
    ),
    BidHistoryEntity(
      id: 'bid-2',
      auctionId: testAuctionId,
      amount: 50000.0,
      bidderName: 'User B',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      isCurrentUser: false,
      isWinning: true,
    ),
  ];

  final testQuestions = <QAEntity>[
    QAEntity(
      id: 'qa-1',
      auctionId: testAuctionId,
      question: 'What is the mileage?',
      category: 'general',
      askedBy: 'user-1',
      askedAt: DateTime.now().subtract(const Duration(days: 1)),
      answers: const [],
      likesCount: 5,
      isLikedByUser: false,
    ),
  ];

  setUp(() {
    mockGetAuctionDetail = MockGetAuctionDetailUseCase();
    mockGetBidHistory = MockGetBidHistoryUseCase();
    mockPlaceBid = MockPlaceBidUseCase();
    mockGetQuestions = MockGetQuestionsUseCase();
    mockPostQuestion = MockPostQuestionUseCase();
    mockLikeQuestion = MockLikeQuestionUseCase();
    mockUnlikeQuestion = MockUnlikeQuestionUseCase();
    mockGetBidIncrement = MockGetBidIncrementUseCase();
    mockUpsertBidIncrement = MockUpsertBidIncrementUseCase();
    mockProcessDeposit = MockProcessDepositUseCase();
    mockConsumeBiddingToken = MockConsumeBiddingTokenUsecase();

    controller = AuctionDetailController(
      getAuctionDetailUseCase: mockGetAuctionDetail,
      getBidHistoryUseCase: mockGetBidHistory,
      placeBidUseCase: mockPlaceBid,
      getQuestionsUseCase: mockGetQuestions,
      postQuestionUseCase: mockPostQuestion,
      likeQuestionUseCase: mockLikeQuestion,
      unlikeQuestionUseCase: mockUnlikeQuestion,
      getBidIncrementUseCase: mockGetBidIncrement,
      upsertBidIncrementUseCase: mockUpsertBidIncrement,
      processDepositUseCase: mockProcessDeposit,
      consumeBiddingTokenUsecase: mockConsumeBiddingToken,
      userId: testUserId,
    );

    // Register fallback values
    registerFallbackValue(testAuction);
  });

  tearDown(() {
    controller.dispose();
  });

  group('AuctionDetailController', () {
    group('Initial State', () {
      test('should have correct initial state', () {
        expect(controller.auction, isNull);
        expect(controller.bidHistory, isEmpty);
        expect(controller.questions, isEmpty);
        expect(controller.isLoading, false);
        expect(controller.isLoadingBidHistory, false);
        expect(controller.isLoadingQA, false);
        expect(controller.isProcessing, false);
        expect(controller.errorMessage, isNull);
        expect(controller.hasError, false);
        expect(controller.isAutoBidActive, false);
        expect(controller.maxAutoBid, isNull);
      });
    });

    group('loadAuctionDetail', () {
      test('should load auction detail successfully', () async {
        // Arrange
        when(
          () => mockGetAuctionDetail(
            auctionId: any(named: 'auctionId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => Right(testAuction));
        when(
          () => mockGetBidIncrement(
            auctionId: any(named: 'auctionId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGetBidHistory(auctionId: any(named: 'auctionId')),
        ).thenAnswer((_) async => Right(testBidHistory));
        when(
          () => mockGetQuestions(
            auctionId: any(named: 'auctionId'),
            currentUserId: any(named: 'currentUserId'),
          ),
        ).thenAnswer((_) async => Right(testQuestions));

        // Act
        await controller.loadAuctionDetail(testAuctionId);

        // Assert
        expect(controller.auction, equals(testAuction));
        expect(controller.bidHistory, hasLength(2));
        expect(controller.questions, hasLength(1));
        expect(controller.isLoading, false);
        expect(controller.errorMessage, isNull);
      });

      test('should update loading state during load', () async {
        // Arrange
        when(
          () => mockGetAuctionDetail(
            auctionId: any(named: 'auctionId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return Right(testAuction);
        });
        when(
          () => mockGetBidIncrement(
            auctionId: any(named: 'auctionId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGetBidHistory(auctionId: any(named: 'auctionId')),
        ).thenAnswer((_) async => Right(testBidHistory));
        when(
          () => mockGetQuestions(
            auctionId: any(named: 'auctionId'),
            currentUserId: any(named: 'currentUserId'),
          ),
        ).thenAnswer((_) async => Right(testQuestions));

        // Act
        final loadFuture = controller.loadAuctionDetail(testAuctionId);
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert - loading state should be true during load
        expect(controller.isLoading, true);

        await loadFuture;
        expect(controller.isLoading, false);
      });

      test('should handle failure when loading auction detail', () async {
        // Arrange
        const failure = ServerFailure('Failed to load auction');
        when(
          () => mockGetAuctionDetail(
            auctionId: any(named: 'auctionId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => const Left(failure));

        // Act
        await controller.loadAuctionDetail(testAuctionId);

        // Assert
        expect(
          controller.errorMessage,
          equals('Failed to load auction details'),
        );
        expect(controller.hasError, true);
        expect(controller.isLoading, false);
      });

      test('should handle empty bid history', () async {
        // Arrange
        when(
          () => mockGetAuctionDetail(
            auctionId: any(named: 'auctionId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => Right(testAuction));
        when(
          () => mockGetBidIncrement(
            auctionId: any(named: 'auctionId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGetBidHistory(auctionId: any(named: 'auctionId')),
        ).thenAnswer((_) async => const Right([]));
        when(
          () => mockGetQuestions(
            auctionId: any(named: 'auctionId'),
            currentUserId: any(named: 'currentUserId'),
          ),
        ).thenAnswer((_) async => Right(testQuestions));

        // Act
        await controller.loadAuctionDetail(testAuctionId);

        // Assert
        expect(controller.bidHistory, isEmpty);
        expect(controller.errorMessage, isNull);
      });

      test('should handle empty questions', () async {
        // Arrange
        when(
          () => mockGetAuctionDetail(
            auctionId: any(named: 'auctionId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => Right(testAuction));
        when(
          () => mockGetBidIncrement(
            auctionId: any(named: 'auctionId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGetBidHistory(auctionId: any(named: 'auctionId')),
        ).thenAnswer((_) async => Right(testBidHistory));
        when(
          () => mockGetQuestions(
            auctionId: any(named: 'auctionId'),
            currentUserId: any(named: 'currentUserId'),
          ),
        ).thenAnswer((_) async => const Right([]));

        // Act
        await controller.loadAuctionDetail(testAuctionId);

        // Assert
        expect(controller.questions, isEmpty);
        expect(controller.errorMessage, isNull);
      });

      test('should clear previous error on new load attempt', () async {
        // Arrange - First load fails
        const failure = ServerFailure('Failed to load auction');
        when(
          () => mockGetAuctionDetail(
            auctionId: any(named: 'auctionId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => const Left(failure));
        await controller.loadAuctionDetail(testAuctionId);
        expect(controller.hasError, true);

        // Arrange - Second load succeeds
        when(
          () => mockGetAuctionDetail(
            auctionId: any(named: 'auctionId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => Right(testAuction));
        when(
          () => mockGetBidIncrement(
            auctionId: any(named: 'auctionId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGetBidHistory(auctionId: any(named: 'auctionId')),
        ).thenAnswer((_) async => Right(testBidHistory));
        when(
          () => mockGetQuestions(
            auctionId: any(named: 'auctionId'),
            currentUserId: any(named: 'currentUserId'),
          ),
        ).thenAnswer((_) async => Right(testQuestions));

        // Act
        await controller.loadAuctionDetail(testAuctionId);

        // Assert
        expect(controller.errorMessage, isNull);
        expect(controller.hasError, false);
      });

      test('should notify listeners on state change', () async {
        // Arrange
        when(
          () => mockGetAuctionDetail(
            auctionId: any(named: 'auctionId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => Right(testAuction));
        when(
          () => mockGetBidIncrement(
            auctionId: any(named: 'auctionId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGetBidHistory(auctionId: any(named: 'auctionId')),
        ).thenAnswer((_) async => Right(testBidHistory));
        when(
          () => mockGetQuestions(
            auctionId: any(named: 'auctionId'),
            currentUserId: any(named: 'currentUserId'),
          ),
        ).thenAnswer((_) async => Right(testQuestions));

        var notificationCount = 0;
        controller.addListener(() => notificationCount++);

        // Act
        await controller.loadAuctionDetail(testAuctionId);

        // Assert - should notify at least twice (loading start and end)
        expect(notificationCount, greaterThanOrEqualTo(2));
      });
    });

    group('clearError', () {
      test('should clear error message', () async {
        // Arrange - Set an error first
        const failure = ServerFailure('Failed to load auction');
        when(
          () => mockGetAuctionDetail(
            auctionId: any(named: 'auctionId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => const Left(failure));
        await controller.loadAuctionDetail(testAuctionId);
        expect(controller.hasError, true);

        // Act
        controller.clearError();

        // Assert
        expect(controller.errorMessage, isNull);
        expect(controller.hasError, false);
      });

      test('should notify listeners when clearing error', () {
        // Arrange - Manually set error
        controller.loadAuctionDetail(testAuctionId);

        var notificationCount = 0;
        controller.addListener(() => notificationCount++);

        // Act
        controller.clearError();

        // Assert
        expect(notificationCount, equals(1));
      });
    });

    group('Edge Cases', () {
      test('should handle null userId gracefully', () async {
        // Arrange - Create controller without userId
        final controllerWithoutUser = AuctionDetailController(
          getAuctionDetailUseCase: mockGetAuctionDetail,
          getBidHistoryUseCase: mockGetBidHistory,
          placeBidUseCase: mockPlaceBid,
          getQuestionsUseCase: mockGetQuestions,
          postQuestionUseCase: mockPostQuestion,
          likeQuestionUseCase: mockLikeQuestion,
          unlikeQuestionUseCase: mockUnlikeQuestion,
          getBidIncrementUseCase: mockGetBidIncrement,
          upsertBidIncrementUseCase: mockUpsertBidIncrement,
          processDepositUseCase: mockProcessDeposit,
          consumeBiddingTokenUsecase: mockConsumeBiddingToken,
          userId: null,
        );

        when(
          () => mockGetAuctionDetail(
            auctionId: any(named: 'auctionId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => Right(testAuction));
        when(
          () => mockGetBidHistory(auctionId: any(named: 'auctionId')),
        ).thenAnswer((_) async => Right(testBidHistory));
        when(
          () => mockGetQuestions(
            auctionId: any(named: 'auctionId'),
            currentUserId: any(named: 'currentUserId'),
          ),
        ).thenAnswer((_) async => Right(testQuestions));

        // Act
        await controllerWithoutUser.loadAuctionDetail(testAuctionId);

        // Assert - Should not call getBidIncrement without userId
        verifyNever(
          () => mockGetBidIncrement(
            auctionId: any(named: 'auctionId'),
            userId: any(named: 'userId'),
          ),
        );
        expect(controllerWithoutUser.auction, equals(testAuction));

        controllerWithoutUser.dispose();
      });

      test('should handle background refresh without loading state', () async {
        // Arrange
        when(
          () => mockGetAuctionDetail(
            auctionId: any(named: 'auctionId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => Right(testAuction));
        when(
          () => mockGetBidIncrement(
            auctionId: any(named: 'auctionId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGetBidHistory(auctionId: any(named: 'auctionId')),
        ).thenAnswer((_) async => Right(testBidHistory));
        when(
          () => mockGetQuestions(
            auctionId: any(named: 'auctionId'),
            currentUserId: any(named: 'currentUserId'),
          ),
        ).thenAnswer((_) async => Right(testQuestions));

        // Act - Load with isBackground = true
        await controller.loadAuctionDetail(testAuctionId, isBackground: true);

        // Assert - Loading state should remain false
        expect(controller.isLoading, false);
        expect(controller.auction, equals(testAuction));
      });
    });
  });
}
