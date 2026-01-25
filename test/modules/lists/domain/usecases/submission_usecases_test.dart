import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/lists/domain/usecases/submission_usecases.dart';
import 'package:autobid_mobile/modules/lists/domain/repositories/seller_repository.dart';
import 'package:autobid_mobile/modules/lists/domain/entities/listing_draft_entity.dart';
import 'package:autobid_mobile/core/error/failures.dart';

class MockSellerRepository extends Mock implements SellerRepository {}

void main() {
  late SaveDraftUseCase saveDraftUseCase;
  late DeleteDraftUseCase deleteDraftUseCase;
  late SubmitListingUseCase submitListingUseCase;
  late CancelListingUseCase cancelListingUseCase;
  late MockSellerRepository mockRepository;

  setUp(() {
    mockRepository = MockSellerRepository();
    saveDraftUseCase = SaveDraftUseCase(mockRepository);
    deleteDraftUseCase = DeleteDraftUseCase(mockRepository);
    submitListingUseCase = SubmitListingUseCase(mockRepository);
    cancelListingUseCase = CancelListingUseCase(mockRepository);
  });

  const testDraftId = 'draft-123';
  const testAuctionId = 'auction-123';

  final testDraft = ListingDraftEntity(
    id: testDraftId,
    sellerId: 'seller-123',
    currentStep: 5,
    lastSaved: DateTime(2024, 1, 1),
    isComplete: false,
    brand: 'Toyota',
    model: 'Camry',
    year: 2020,
  );

  setUpAll(() {
    registerFallbackValue(testDraft);
  });

  group('SaveDraftUseCase', () {
    test('should save draft successfully', () async {
      // Arrange
      when(
        () => mockRepository.saveDraft(any()),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final result = await saveDraftUseCase(testDraft);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.saveDraft(any())).called(1);
    });

    test('should return ServerFailure on save error', () async {
      // Arrange
      when(
        () => mockRepository.saveDraft(any()),
      ).thenAnswer((_) async => Left(ServerFailure('Failed to save draft')));

      // Act
      final result = await saveDraftUseCase(testDraft);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Failed to save draft');
      }, (_) => fail('Should return failure'));
    });

    test('should return NetworkFailure when offline', () async {
      // Arrange
      when(
        () => mockRepository.saveDraft(any()),
      ).thenAnswer((_) async => Left(NetworkFailure('No internet connection')));

      // Act
      final result = await saveDraftUseCase(testDraft);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<NetworkFailure>());
        expect(failure.message, 'No internet connection');
      }, (_) => fail('Should return failure'));
    });
  });

  group('DeleteDraftUseCase', () {
    test('should delete draft successfully', () async {
      // Arrange
      when(
        () => mockRepository.deleteDraft(testDraftId),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final result = await deleteDraftUseCase(testDraftId);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.deleteDraft(testDraftId)).called(1);
    });

    test('should return NotFoundFailure when draft does not exist', () async {
      // Arrange
      when(
        () => mockRepository.deleteDraft(testDraftId),
      ).thenAnswer((_) async => Left(NotFoundFailure('Draft not found')));

      // Act
      final result = await deleteDraftUseCase(testDraftId);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<NotFoundFailure>());
        expect(failure.message, 'Draft not found');
      }, (_) => fail('Should return failure'));
    });

    test('should return ServerFailure on deletion error', () async {
      // Arrange
      when(
        () => mockRepository.deleteDraft(testDraftId),
      ).thenAnswer((_) async => Left(ServerFailure('Failed to delete draft')));

      // Act
      final result = await deleteDraftUseCase(testDraftId);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Failed to delete draft');
      }, (_) => fail('Should return failure'));
    });
  });

  group('SubmitListingUseCase', () {
    test('should submit listing successfully', () async {
      // Arrange
      when(
        () => mockRepository.submitListing(testDraftId),
      ).thenAnswer((_) async => const Right('auction-new-123'));

      // Act
      final result = await submitListingUseCase(testDraftId);

      // Assert
      expect(result.isRight(), true);
      result.fold((failure) => fail('Should return auction id'), (auctionId) {
        expect(auctionId, 'auction-new-123');
      });

      verify(() => mockRepository.submitListing(testDraftId)).called(1);
    });

    test('should return GeneralFailure when draft is incomplete', () async {
      // Arrange
      when(
        () => mockRepository.submitListing(testDraftId),
      ).thenAnswer((_) async => Left(GeneralFailure('Draft is incomplete')));

      // Act
      final result = await submitListingUseCase(testDraftId);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<GeneralFailure>());
        expect(failure.message, 'Draft is incomplete');
      }, (_) => fail('Should return failure'));
    });

    test('should return NotFoundFailure when draft not found', () async {
      // Arrange
      when(
        () => mockRepository.submitListing(testDraftId),
      ).thenAnswer((_) async => Left(NotFoundFailure('Draft not found')));

      // Act
      final result = await submitListingUseCase(testDraftId);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<NotFoundFailure>());
        expect(failure.message, 'Draft not found');
      }, (_) => fail('Should return failure'));
    });

    test('should return ServerFailure on submission error', () async {
      // Arrange
      when(() => mockRepository.submitListing(testDraftId)).thenAnswer(
        (_) async => Left(ServerFailure('Failed to submit listing')),
      );

      // Act
      final result = await submitListingUseCase(testDraftId);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Failed to submit listing');
      }, (_) => fail('Should return failure'));
    });
  });

  group('CancelListingUseCase', () {
    test('should cancel listing successfully', () async {
      // Arrange
      when(
        () => mockRepository.cancelListing(testAuctionId),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final result = await cancelListingUseCase(testAuctionId);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.cancelListing(testAuctionId)).called(1);
    });

    test('should return NotFoundFailure when listing not found', () async {
      // Arrange
      when(
        () => mockRepository.cancelListing(testAuctionId),
      ).thenAnswer((_) async => Left(NotFoundFailure('Listing not found')));

      // Act
      final result = await cancelListingUseCase(testAuctionId);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<NotFoundFailure>());
        expect(failure.message, 'Listing not found');
      }, (_) => fail('Should return failure'));
    });

    test(
      'should return GeneralFailure when listing cannot be cancelled',
      () async {
        // Arrange
        when(() => mockRepository.cancelListing(testAuctionId)).thenAnswer(
          (_) async =>
              Left(GeneralFailure('Cannot cancel active auction with bids')),
        );

        // Act
        final result = await cancelListingUseCase(testAuctionId);

        // Assert
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<GeneralFailure>());
          expect(failure.message, contains('Cannot cancel'));
        }, (_) => fail('Should return failure'));
      },
    );

    test('should return ServerFailure on cancellation error', () async {
      // Arrange
      when(() => mockRepository.cancelListing(testAuctionId)).thenAnswer(
        (_) async => Left(ServerFailure('Failed to cancel listing')),
      );

      // Act
      final result = await cancelListingUseCase(testAuctionId);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Failed to cancel listing');
      }, (_) => fail('Should return failure'));
    });
  });
}
