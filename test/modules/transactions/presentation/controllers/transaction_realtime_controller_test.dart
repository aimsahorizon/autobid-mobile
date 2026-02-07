import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:autobid_mobile/modules/transactions/presentation/controllers/transaction_realtime_controller.dart';
import 'package:autobid_mobile/modules/transactions/data/datasources/transaction_realtime_datasource.dart';
import 'package:autobid_mobile/modules/transactions/domain/entities/transaction_entity.dart';
import 'package:autobid_mobile/modules/transactions/domain/entities/transaction_review_entity.dart';

// Generate mocks
@GenerateMocks([TransactionRealtimeDataSource])
import 'transaction_realtime_controller_test.mocks.dart';

void main() {
  late TransactionRealtimeController controller;
  late MockTransactionRealtimeDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockTransactionRealtimeDataSource();
    controller = TransactionRealtimeController(mockDataSource);
  });

  group('TransactionRealtimeController - Review & Realtime', () {
    const testTransactionId = 'txn_123';
    const testUserId = 'user_123';
    const testSellerId = 'seller_123';
    
    final testTransaction = TransactionEntity(
      id: testTransactionId,
      listingId: 'auction_123',
      sellerId: testSellerId,
      buyerId: testUserId,
      carName: 'Test Car',
      carImageUrl: 'http://example.com/car.jpg',
      agreedPrice: 500000,
      status: TransactionStatus.discussion,
      createdAt: DateTime.now(),
      sellerFormSubmitted: false,
      buyerFormSubmitted: false,
      sellerConfirmed: false,
      buyerConfirmed: false,
      adminApproved: false,
      deliveryStatus: DeliveryStatus.pending,
      buyerAcceptanceStatus: BuyerAcceptanceStatus.pending,
    );

    test('submitReview calls datasource with multi-category ratings', () async {
      // Arrange
      // 1. Mock getTransaction to return a valid transaction so the controller has context
      when(mockDataSource.getTransaction(testTransactionId))
          .thenAnswer((_) async => testTransaction);
      
      // 2. Mock auxiliary loads to prevent crashes
      when(mockDataSource.getChatMessages(any)).thenAnswer((_) async => []);
      when(mockDataSource.getTransactionForm(any, any)).thenAnswer((_) async => null);
      when(mockDataSource.getTimeline(any)).thenAnswer((_) async => []);
      when(mockDataSource.getReview(any, any)).thenAnswer((_) async => null);
      
      // 3. Mock subscription calls
      when(mockDataSource.chatStream).thenAnswer((_) => const Stream.empty());
      when(mockDataSource.transactionUpdateStream).thenAnswer((_) => const Stream.empty());

      // 4. Mock submitReview success
      final expectedReview = TransactionReviewEntity(
        id: 'review_123',
        transactionId: testTransactionId,
        reviewerId: testUserId,
        revieweeId: testSellerId,
        rating: 5,
        ratingCommunication: 4,
        ratingReliability: 5,
        comment: 'Great!',
        createdAt: DateTime.now(),
      );

      when(mockDataSource.submitReview(
        transactionId: anyNamed('transactionId'),
        reviewerId: anyNamed('reviewerId'),
        revieweeId: anyNamed('revieweeId'),
        rating: anyNamed('rating'),
        ratingCommunication: anyNamed('ratingCommunication'),
        ratingReliability: anyNamed('ratingReliability'),
        comment: anyNamed('comment'),
      )).thenAnswer((_) async => expectedReview);

      // Act
      // First load transaction to set up state
      await controller.loadTransaction(testTransactionId, testUserId);
      
      // Then submit review
      final result = await controller.submitReview(
        rating: 5,
        ratingCommunication: 4,
        ratingReliability: 5,
        comment: 'Great!',
      );

      // Assert
      expect(result, true);
      expect(controller.myReview, equals(expectedReview));
      
      verify(mockDataSource.submitReview(
        transactionId: testTransactionId,
        reviewerId: testUserId,
        revieweeId: testSellerId,
        rating: 5,
        ratingCommunication: 4,
        ratingReliability: 5,
        comment: 'Great!',
      )).called(1);
    });

    test('Realtime transaction update triggers reload', () async {
      // Arrange
      final updateController = StreamController<Map<String, dynamic>>();
      
      when(mockDataSource.getTransaction(testTransactionId))
          .thenAnswer((_) async => testTransaction);
      when(mockDataSource.getChatMessages(any)).thenAnswer((_) async => []);
      when(mockDataSource.getTransactionForm(any, any)).thenAnswer((_) async => null);
      when(mockDataSource.getTimeline(any)).thenAnswer((_) async => []);
      when(mockDataSource.getReview(any, any)).thenAnswer((_) async => null);
      
      when(mockDataSource.chatStream).thenAnswer((_) => const Stream.empty());
      
      // Critical: Return our controllable stream
      when(mockDataSource.transactionUpdateStream).thenAnswer((_) => updateController.stream);

      // Act
      await controller.loadTransaction(testTransactionId, testUserId);
      
      // Reset mocks to verify reload calls
      clearInteractions(mockDataSource);
      // Re-stub essential calls for the reload
      when(mockDataSource.getTransaction(testTransactionId))
          .thenAnswer((_) async => testTransaction);
      when(mockDataSource.getChatMessages(any)).thenAnswer((_) async => []);
      when(mockDataSource.getTransactionForm(any, any)).thenAnswer((_) async => null);
      when(mockDataSource.getTimeline(any)).thenAnswer((_) async => []);
      when(mockDataSource.getReview(any, any)).thenAnswer((_) async => null);

      // Simulate realtime update
      updateController.add({'id': testTransactionId, 'status': 'completed'});
      
      // Allow async processing
      await Future.delayed(Duration.zero);

      // Assert
      // Verify loadTransaction logic was triggered (e.g. fetching transaction again)
      verify(mockDataSource.getTransaction(testTransactionId)).called(1);
      
      updateController.close();
    });
  });
}
