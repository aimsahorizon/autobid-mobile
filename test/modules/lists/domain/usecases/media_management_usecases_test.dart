import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/lists/domain/usecases/media_management_usecases.dart';
import 'package:autobid_mobile/modules/lists/domain/repositories/seller_repository.dart';
import 'package:autobid_mobile/core/error/failures.dart';

class MockSellerRepository extends Mock implements SellerRepository {}

class MockFile extends Mock implements File {}

void main() {
  late UploadListingPhotoUseCase uploadListingPhotoUseCase;
  late UploadDeedOfSaleUseCase uploadDeedOfSaleUseCase;
  late DeleteDeedOfSaleUseCase deleteDeedOfSaleUseCase;
  late MockSellerRepository mockRepository;
  late MockFile mockFile;

  const testUserId = 'user-123';
  const testListingId = 'listing-123';
  const testCategory = 'exterior';
  const testPhotoUrl = 'https://storage.example.com/listings/photo.jpg';
  const testDocumentUrl = 'https://storage.example.com/listings/deed.pdf';

  setUpAll(() {
    // Register fallback for File type
    registerFallbackValue(MockFile());
  });

  setUp(() {
    mockRepository = MockSellerRepository();
    mockFile = MockFile();
    uploadListingPhotoUseCase = UploadListingPhotoUseCase(mockRepository);
    uploadDeedOfSaleUseCase = UploadDeedOfSaleUseCase(mockRepository);
    deleteDeedOfSaleUseCase = DeleteDeedOfSaleUseCase(mockRepository);
  });

  group('UploadListingPhotoUseCase', () {
    test('should upload listing photo successfully', () async {
      // Arrange
      when(
        () => mockRepository.uploadPhoto(
          userId: testUserId,
          listingId: testListingId,
          category: testCategory,
          imageFile: any(named: 'imageFile'),
        ),
      ).thenAnswer((_) async => const Right(testPhotoUrl));

      // Act
      final result = await uploadListingPhotoUseCase(
        userId: testUserId,
        listingId: testListingId,
        category: testCategory,
        imageFile: mockFile,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return photo URL'),
        (url) => expect(url, testPhotoUrl),
      );

      verify(
        () => mockRepository.uploadPhoto(
          userId: testUserId,
          listingId: testListingId,
          category: testCategory,
          imageFile: any(named: 'imageFile'),
        ),
      ).called(1);
    });

    test('should return StorageFailure when upload fails', () async {
      // Arrange
      when(
        () => mockRepository.uploadPhoto(
          userId: any(named: 'userId'),
          listingId: any(named: 'listingId'),
          category: any(named: 'category'),
          imageFile: any(named: 'imageFile'),
        ),
      ).thenAnswer((_) async => Left(StorageFailure('Upload failed')));

      // Act
      final result = await uploadListingPhotoUseCase(
        userId: testUserId,
        listingId: testListingId,
        category: testCategory,
        imageFile: mockFile,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<StorageFailure>());
        expect(failure.message, 'Upload failed');
      }, (_) => fail('Should return failure'));
    });

    test('should return StorageFailure when file size exceeds limit', () async {
      // Arrange
      when(
        () => mockRepository.uploadPhoto(
          userId: any(named: 'userId'),
          listingId: any(named: 'listingId'),
          category: any(named: 'category'),
          imageFile: any(named: 'imageFile'),
        ),
      ).thenAnswer(
        (_) async => Left(StorageFailure('File size exceeds 10MB limit')),
      );

      // Act
      final result = await uploadListingPhotoUseCase(
        userId: testUserId,
        listingId: testListingId,
        category: testCategory,
        imageFile: mockFile,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<StorageFailure>());
        expect(failure.message, contains('exceeds'));
      }, (_) => fail('Should return failure'));
    });

    test('should return AuthFailure when user unauthorized', () async {
      // Arrange
      when(
        () => mockRepository.uploadPhoto(
          userId: any(named: 'userId'),
          listingId: any(named: 'listingId'),
          category: any(named: 'category'),
          imageFile: any(named: 'imageFile'),
        ),
      ).thenAnswer((_) async => Left(AuthFailure('Unauthorized')));

      // Act
      final result = await uploadListingPhotoUseCase(
        userId: 'wrong-user',
        listingId: testListingId,
        category: testCategory,
        imageFile: mockFile,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<AuthFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('should handle different photo categories', () async {
      // Arrange
      const categories = ['exterior', 'interior', 'engine', 'documents'];

      for (final category in categories) {
        when(
          () => mockRepository.uploadPhoto(
            userId: testUserId,
            listingId: testListingId,
            category: category,
            imageFile: any(named: 'imageFile'),
          ),
        ).thenAnswer(
          (_) async => Right('https://storage.example.com/$category.jpg'),
        );

        // Act
        final result = await uploadListingPhotoUseCase(
          userId: testUserId,
          listingId: testListingId,
          category: category,
          imageFile: mockFile,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should upload photo for category $category'),
          (url) => expect(url, contains(category)),
        );
      }
    });
  });

  group('UploadDeedOfSaleUseCase', () {
    test('should upload deed of sale successfully', () async {
      // Arrange
      when(
        () => mockRepository.uploadDeedOfSale(
          userId: testUserId,
          listingId: testListingId,
          documentFile: any(named: 'documentFile'),
        ),
      ).thenAnswer((_) async => const Right(testDocumentUrl));

      // Act
      final result = await uploadDeedOfSaleUseCase(
        userId: testUserId,
        listingId: testListingId,
        documentFile: mockFile,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return document URL'),
        (url) => expect(url, testDocumentUrl),
      );

      verify(
        () => mockRepository.uploadDeedOfSale(
          userId: testUserId,
          listingId: testListingId,
          documentFile: any(named: 'documentFile'),
        ),
      ).called(1);
    });

    test('should return StorageFailure when upload fails', () async {
      // Arrange
      when(
        () => mockRepository.uploadDeedOfSale(
          userId: any(named: 'userId'),
          listingId: any(named: 'listingId'),
          documentFile: any(named: 'documentFile'),
        ),
      ).thenAnswer((_) async => Left(StorageFailure('Document upload failed')));

      // Act
      final result = await uploadDeedOfSaleUseCase(
        userId: testUserId,
        listingId: testListingId,
        documentFile: mockFile,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<StorageFailure>());
        expect(failure.message, contains('Document upload failed'));
      }, (_) => fail('Should return failure'));
    });

    test('should return StorageFailure when file format invalid', () async {
      // Arrange
      when(
        () => mockRepository.uploadDeedOfSale(
          userId: any(named: 'userId'),
          listingId: any(named: 'listingId'),
          documentFile: any(named: 'documentFile'),
        ),
      ).thenAnswer(
        (_) async => Left(StorageFailure('Only PDF files are allowed')),
      );

      // Act
      final result = await uploadDeedOfSaleUseCase(
        userId: testUserId,
        listingId: testListingId,
        documentFile: mockFile,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<StorageFailure>());
        expect(failure.message, contains('PDF'));
      }, (_) => fail('Should return failure'));
    });

    test('should return AuthFailure when user unauthorized', () async {
      // Arrange
      when(
        () => mockRepository.uploadDeedOfSale(
          userId: any(named: 'userId'),
          listingId: any(named: 'listingId'),
          documentFile: any(named: 'documentFile'),
        ),
      ).thenAnswer((_) async => Left(AuthFailure('Not listing owner')));

      // Act
      final result = await uploadDeedOfSaleUseCase(
        userId: 'wrong-user',
        listingId: testListingId,
        documentFile: mockFile,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<AuthFailure>());
        expect(failure.message, contains('owner'));
      }, (_) => fail('Should return failure'));
    });
  });

  group('DeleteDeedOfSaleUseCase', () {
    test('should delete deed of sale successfully', () async {
      // Arrange
      when(
        () => mockRepository.deleteDeedOfSale(testDocumentUrl),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final result = await deleteDeedOfSaleUseCase(testDocumentUrl);

      // Assert
      expect(result.isRight(), true);

      verify(() => mockRepository.deleteDeedOfSale(testDocumentUrl)).called(1);
    });

    test('should return StorageFailure when deletion fails', () async {
      // Arrange
      when(
        () => mockRepository.deleteDeedOfSale(any()),
      ).thenAnswer((_) async => Left(StorageFailure('Deletion failed')));

      // Act
      final result = await deleteDeedOfSaleUseCase(testDocumentUrl);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<StorageFailure>());
        expect(failure.message, 'Deletion failed');
      }, (_) => fail('Should return failure'));
    });

    test('should return NotFoundFailure when document not found', () async {
      // Arrange
      when(
        () => mockRepository.deleteDeedOfSale(any()),
      ).thenAnswer((_) async => Left(NotFoundFailure('Document not found')));

      // Act
      final result = await deleteDeedOfSaleUseCase('non-existent-url');

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<NotFoundFailure>());
        expect(failure.message, contains('not found'));
      }, (_) => fail('Should return failure'));
    });

    test('should return AuthFailure when user unauthorized', () async {
      // Arrange
      when(() => mockRepository.deleteDeedOfSale(any())).thenAnswer(
        (_) async =>
            Left(AuthFailure('Cannot delete document from another listing')),
      );

      // Act
      final result = await deleteDeedOfSaleUseCase(testDocumentUrl);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<AuthFailure>());
        expect(failure.message, contains('Cannot delete'));
      }, (_) => fail('Should return failure'));
    });
  });
}
