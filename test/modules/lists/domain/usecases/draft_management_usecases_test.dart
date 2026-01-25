import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/lists/domain/usecases/draft_management_usecases.dart';
import 'package:autobid_mobile/modules/lists/domain/repositories/seller_repository.dart';
import 'package:autobid_mobile/modules/lists/domain/entities/listing_draft_entity.dart';
import 'package:autobid_mobile/core/error/failures.dart';

class MockSellerRepository extends Mock implements SellerRepository {}

void main() {
  late GetSellerDraftsUseCase getSellerDraftsUseCase;
  late GetDraftUseCase getDraftUseCase;
  late CreateDraftUseCase createDraftUseCase;
  late MockSellerRepository mockRepository;

  setUp(() {
    mockRepository = MockSellerRepository();
    getSellerDraftsUseCase = GetSellerDraftsUseCase(mockRepository);
    getDraftUseCase = GetDraftUseCase(mockRepository);
    createDraftUseCase = CreateDraftUseCase(mockRepository);
  });

  const testSellerId = 'seller-123';
  const testDraftId = 'draft-123';

  final testDraft = ListingDraftEntity(
    id: testDraftId,
    sellerId: testSellerId,
    currentStep: 3,
    lastSaved: DateTime(2024, 1, 1),
    isComplete: false,
    brand: 'Toyota',
    model: 'Camry',
    variant: 'XLE',
    year: 2020,
    engineType: 'Inline-4',
    engineDisplacement: 2.5,
    transmission: 'Automatic',
    fuelType: 'Gasoline',
    driveType: 'FWD',
  );

  final testDrafts = [
    testDraft,
    ListingDraftEntity(
      id: 'draft-456',
      sellerId: testSellerId,
      currentStep: 1,
      lastSaved: DateTime(2024, 1, 2),
      isComplete: false,
      brand: 'Honda',
      model: 'Civic',
    ),
  ];

  group('GetSellerDraftsUseCase', () {
    test('should get all seller drafts', () async {
      // Arrange
      when(
        () => mockRepository.getSellerDrafts(testSellerId),
      ).thenAnswer((_) async => Right(testDrafts));

      // Act
      final result = await getSellerDraftsUseCase(testSellerId);

      // Assert
      expect(result.isRight(), true);
      result.fold((failure) => fail('Should return drafts'), (drafts) {
        expect(drafts.length, 2);
        expect(drafts.first.id, testDraftId);
        expect(drafts.first.brand, 'Toyota');
      });

      verify(() => mockRepository.getSellerDrafts(testSellerId)).called(1);
    });

    test('should handle empty drafts list', () async {
      // Arrange
      when(
        () => mockRepository.getSellerDrafts(testSellerId),
      ).thenAnswer((_) async => const Right([]));

      // Act
      final result = await getSellerDraftsUseCase(testSellerId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return empty list'),
        (drafts) => expect(drafts, isEmpty),
      );
    });

    test('should return ServerFailure on error', () async {
      // Arrange
      when(
        () => mockRepository.getSellerDrafts(testSellerId),
      ).thenAnswer((_) async => Left(ServerFailure('Database error')));

      // Act
      final result = await getSellerDraftsUseCase(testSellerId);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Database error');
      }, (_) => fail('Should return failure'));
    });
  });

  group('GetDraftUseCase', () {
    test('should get draft by id', () async {
      // Arrange
      when(
        () => mockRepository.getDraft(testDraftId),
      ).thenAnswer((_) async => Right(testDraft));

      // Act
      final result = await getDraftUseCase(testDraftId);

      // Assert
      expect(result.isRight(), true);
      result.fold((failure) => fail('Should return draft'), (draft) {
        expect(draft, isNotNull);
        expect(draft!.id, testDraftId);
        expect(draft.brand, 'Toyota');
        expect(draft.currentStep, 3);
      });

      verify(() => mockRepository.getDraft(testDraftId)).called(1);
    });

    test('should return null when draft not found', () async {
      // Arrange
      when(
        () => mockRepository.getDraft(testDraftId),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final result = await getDraftUseCase(testDraftId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return null'),
        (draft) => expect(draft, isNull),
      );
    });

    test('should return NotFoundFailure on error', () async {
      // Arrange
      when(
        () => mockRepository.getDraft(testDraftId),
      ).thenAnswer((_) async => Left(NotFoundFailure('Draft not found')));

      // Act
      final result = await getDraftUseCase(testDraftId);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<NotFoundFailure>());
        expect(failure.message, 'Draft not found');
      }, (_) => fail('Should return failure'));
    });
  });

  group('CreateDraftUseCase', () {
    test('should create new draft for seller', () async {
      // Arrange
      final newDraft = ListingDraftEntity(
        id: 'draft-new',
        sellerId: testSellerId,
        currentStep: 1,
        lastSaved: DateTime(2024, 1, 3),
        isComplete: false,
      );

      when(
        () => mockRepository.createDraft(testSellerId),
      ).thenAnswer((_) async => Right(newDraft));

      // Act
      final result = await createDraftUseCase(testSellerId);

      // Assert
      expect(result.isRight(), true);
      result.fold((failure) => fail('Should return new draft'), (draft) {
        expect(draft.id, 'draft-new');
        expect(draft.sellerId, testSellerId);
        expect(draft.currentStep, 1);
        expect(draft.isComplete, false);
      });

      verify(() => mockRepository.createDraft(testSellerId)).called(1);
    });

    test('should return AuthFailure when seller not authenticated', () async {
      // Arrange
      when(
        () => mockRepository.createDraft(testSellerId),
      ).thenAnswer((_) async => Left(AuthFailure('User not authenticated')));

      // Act
      final result = await createDraftUseCase(testSellerId);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<AuthFailure>());
        expect(failure.message, 'User not authenticated');
      }, (_) => fail('Should return failure'));
    });

    test('should return ServerFailure on database error', () async {
      // Arrange
      when(
        () => mockRepository.createDraft(testSellerId),
      ).thenAnswer((_) async => Left(ServerFailure('Failed to create draft')));

      // Act
      final result = await createDraftUseCase(testSellerId);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Failed to create draft');
      }, (_) => fail('Should return failure'));
    });
  });
}
