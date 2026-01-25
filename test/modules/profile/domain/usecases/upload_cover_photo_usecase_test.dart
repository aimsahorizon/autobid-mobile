import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/profile/domain/repositories/profile_repository.dart';
import 'package:autobid_mobile/modules/profile/domain/usecases/upload_cover_photo_usecase.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class FakeFile extends Fake implements File {}

void main() {
  late UploadCoverPhotoUseCase useCase;
  late MockProfileRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeFile());
  });

  setUp(() {
    mockRepository = MockProfileRepository();
    useCase = UploadCoverPhotoUseCase(mockRepository);
  });

  group('UploadCoverPhotoUseCase', () {
    const testUserId = 'test-user-id';
    final testFile = File('test/path/to/cover.jpg');
    const testPhotoUrl = 'https://storage.example.com/photos/cover.jpg';

    test('should return photo URL when upload succeeds', () async {
      // Arrange
      when(
        () => mockRepository.uploadCoverPhoto(any(), any()),
      ).thenAnswer((_) async => Right(testPhotoUrl));

      // Act
      final result = await useCase(userId: testUserId, imageFile: testFile);

      // Assert
      expect(result, equals(Right(testPhotoUrl)));
      verify(
        () => mockRepository.uploadCoverPhoto(testUserId, testFile),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ServerFailure when upload fails', () async {
      // Arrange
      const failure = ServerFailure('Network error');
      when(
        () => mockRepository.uploadCoverPhoto(any(), any()),
      ).thenAnswer((_) async => Left(failure));

      // Act
      final result = await useCase(userId: testUserId, imageFile: testFile);

      // Assert
      expect(result, equals(Left(failure)));
      verify(
        () => mockRepository.uploadCoverPhoto(testUserId, testFile),
      ).called(1);
    });

    test('should return StorageFailure when file too large', () async {
      // Arrange
      const failure = StorageFailure('File size exceeds limit');
      when(
        () => mockRepository.uploadCoverPhoto(any(), any()),
      ).thenAnswer((_) async => Left(failure));

      // Act
      final result = await useCase(userId: testUserId, imageFile: testFile);

      // Assert
      expect(result, equals(Left(failure)));
    });
  });
}
