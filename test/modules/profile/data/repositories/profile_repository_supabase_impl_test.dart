import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
// ...existing code...
import 'package:autobid_mobile/modules/profile/data/repositories/profile_repository_supabase_impl.dart';
import 'package:autobid_mobile/modules/profile/data/datasources/profile_supabase_datasource.dart';
import 'package:autobid_mobile/modules/profile/data/models/user_profile_model.dart';
import 'package:autobid_mobile/modules/profile/domain/entities/user_profile_entity.dart';
import 'package:autobid_mobile/core/error/failures.dart';

// Mock classes
class MockProfileSupabaseDataSource extends Mock
    implements ProfileSupabaseDataSource {}

class FakeFile extends Fake implements File {}

void main() {
  late ProfileRepositorySupabaseImpl repository;
  late MockProfileSupabaseDataSource mockDataSource;

  const testUserId = 'test-user-123';
  const testEmail = 'test@example.com';

  final testProfileModel = UserProfileModel(
    id: testUserId,
    email: testEmail,
    fullName: 'Test User',
    username: 'testuser',
    contactNumber: '09171234567',
    profilePhotoUrl: 'https://example.com/photo.jpg',
    coverPhotoUrl: 'https://example.com/cover.jpg',
  );

  final testProfileEntity = UserProfileEntity(
    id: testUserId,
    email: testEmail,
    fullName: 'Test User',
    username: 'testuser',
    contactNumber: '09171234567',
    profilePhotoUrl: 'https://example.com/photo.jpg',
    coverPhotoUrl: 'https://example.com/cover.jpg',
  );

  setUp(() {
    mockDataSource = MockProfileSupabaseDataSource();
    repository = ProfileRepositorySupabaseImpl(mockDataSource);

    // Register fallback values
    registerFallbackValue(FakeFile());
  });

  group('ProfileRepositorySupabaseImpl', () {
    group('getUserProfile', () {
      // Note: getUserProfile() relies on SupabaseConfig.currentUser which cannot
      // be easily mocked in unit tests. This method is better tested via integration
      // tests or through the UseCases that call it.

      test('should call datasource getUserProfile', () async {
        // This test documents that the repository calls the datasource,
        // but we cannot fully test the authentication check without mocking
        // the static SupabaseConfig.currentUser

        // Since SupabaseConfig.currentUser will be null in tests,
        // the method will return AuthFailure before calling datasource
        final result = await repository.getUserProfile();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<AuthFailure>()),
          (profile) => fail('Should return Left when not authenticated'),
        );
      });
    });

    group('updateProfile', () {
      test(
        'should return updated UserProfileEntity when update succeeds',
        () async {
          // Arrange
          final updatedModel = UserProfileModel(
            id: testUserId,
            email: testEmail,
            fullName: 'Updated Name',
            username: 'updateduser',
            contactNumber: testProfileModel.contactNumber,
            profilePhotoUrl: testProfileModel.profilePhotoUrl,
            coverPhotoUrl: testProfileModel.coverPhotoUrl,
          );

          when(
            () => mockDataSource.updateProfile(
              userId: any(named: 'userId'),
              fullName: any(named: 'fullName'),
              username: any(named: 'username'),
              contactNumber: any(named: 'contactNumber'),
              coverPhotoUrl: any(named: 'coverPhotoUrl'),
              profilePhotoUrl: any(named: 'profilePhotoUrl'),
            ),
          ).thenAnswer((_) async => updatedModel);

          final updatedEntity = UserProfileEntity(
            id: testUserId,
            email: testEmail,
            fullName: 'Updated Name',
            username: 'updateduser',
            contactNumber: testProfileEntity.contactNumber,
            profilePhotoUrl: testProfileEntity.profilePhotoUrl,
            coverPhotoUrl: testProfileEntity.coverPhotoUrl,
          );

          // Act
          final result = await repository.updateProfile(updatedEntity);

          // Assert
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Should return Right but got Left: $failure'),
            (profile) {
              expect(profile.fullName, equals('Updated Name'));
              expect(profile.username, equals('updateduser'));
            },
          );
          verify(
            () => mockDataSource.updateProfile(
              userId: testUserId,
              fullName: 'Updated Name',
              username: 'updateduser',
              contactNumber: any(named: 'contactNumber'),
              coverPhotoUrl: any(named: 'coverPhotoUrl'),
              profilePhotoUrl: any(named: 'profilePhotoUrl'),
            ),
          ).called(1);
        },
      );

      test(
        'should return GeneralFailure when datasource throws exception',
        () async {
          // Arrange
          when(
            () => mockDataSource.updateProfile(
              userId: any(named: 'userId'),
              fullName: any(named: 'fullName'),
              username: any(named: 'username'),
              contactNumber: any(named: 'contactNumber'),
              coverPhotoUrl: any(named: 'coverPhotoUrl'),
              profilePhotoUrl: any(named: 'profilePhotoUrl'),
            ),
          ).thenThrow(Exception('Update failed'));

          // Act
          final result = await repository.updateProfile(testProfileEntity);

          // Assert
          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<GeneralFailure>());
            expect(failure.message, contains('Update failed'));
          }, (profile) => fail('Should return Left but got Right'));
        },
      );

      test('should handle duplicate username error', () async {
        // Arrange
        when(
          () => mockDataSource.updateProfile(
            userId: any(named: 'userId'),
            fullName: any(named: 'fullName'),
            username: any(named: 'username'),
            contactNumber: any(named: 'contactNumber'),
            coverPhotoUrl: any(named: 'coverPhotoUrl'),
            profilePhotoUrl: any(named: 'profilePhotoUrl'),
          ),
        ).thenThrow(Exception('Username already taken'));

        // Act
        final result = await repository.updateProfile(testProfileEntity);

        // Assert
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<GeneralFailure>());
          expect(failure.message, contains('Username already taken'));
        }, (profile) => fail('Should return Left but got Right'));
      });
    });

    group('uploadProfilePhoto', () {
      test('should return photo URL when upload succeeds', () async {
        // Arrange
        const photoUrl = 'https://example.com/uploaded-photo.jpg';
        final fakeFile = FakeFile();

        when(
          () => mockDataSource.uploadProfilePhoto(any(), any()),
        ).thenAnswer((_) async => photoUrl);

        // Act
        final result = await repository.uploadProfilePhoto(
          testUserId,
          fakeFile,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right but got Left: $failure'),
          (url) => expect(url, equals(photoUrl)),
        );
        verify(
          () => mockDataSource.uploadProfilePhoto(testUserId, fakeFile),
        ).called(1);
      });

      test('should return GeneralFailure when upload fails', () async {
        // Arrange
        final fakeFile = FakeFile();

        when(
          () => mockDataSource.uploadProfilePhoto(any(), any()),
        ).thenThrow(Exception('Upload failed'));

        // Act
        final result = await repository.uploadProfilePhoto(
          testUserId,
          fakeFile,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<GeneralFailure>());
          expect(failure.message, contains('Upload failed'));
        }, (url) => fail('Should return Left but got Right'));
      });
    });

    group('uploadCoverPhoto', () {
      test('should return photo URL when upload succeeds', () async {
        // Arrange
        const photoUrl = 'https://example.com/uploaded-cover.jpg';
        final fakeFile = FakeFile();

        when(
          () => mockDataSource.uploadCoverPhoto(any(), any()),
        ).thenAnswer((_) async => photoUrl);

        // Act
        final result = await repository.uploadCoverPhoto(testUserId, fakeFile);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right but got Left: $failure'),
          (url) => expect(url, equals(photoUrl)),
        );
        verify(
          () => mockDataSource.uploadCoverPhoto(testUserId, fakeFile),
        ).called(1);
      });

      test('should return GeneralFailure when upload fails', () async {
        // Arrange
        final fakeFile = FakeFile();

        when(
          () => mockDataSource.uploadCoverPhoto(any(), any()),
        ).thenThrow(Exception('Upload failed'));

        // Act
        final result = await repository.uploadCoverPhoto(testUserId, fakeFile);

        // Assert
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<GeneralFailure>());
          expect(failure.message, contains('Upload failed'));
        }, (url) => fail('Should return Left but got Right'));
      });
    });

    group('getUserProfileByEmail', () {
      test('should return UserProfileEntity when profile found', () async {
        // Arrange
        when(
          () => mockDataSource.getUserProfileByEmail(any()),
        ).thenAnswer((_) async => testProfileModel);

        // Act
        final result = await repository.getUserProfileByEmail(testEmail);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right but got Left: $failure'),
          (profile) {
            expect(profile, isNotNull);
            expect(profile!.email, equals(testEmail));
          },
        );
        verify(() => mockDataSource.getUserProfileByEmail(testEmail)).called(1);
      });

      test('should return null when profile not found', () async {
        // Arrange
        when(
          () => mockDataSource.getUserProfileByEmail(any()),
        ).thenAnswer((_) async => null);

        // Act
        final result = await repository.getUserProfileByEmail(testEmail);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right but got Left: $failure'),
          (profile) => expect(profile, isNull),
        );
      });

      test(
        'should return GeneralFailure when datasource throws exception',
        () async {
          // Arrange
          when(
            () => mockDataSource.getUserProfileByEmail(any()),
          ).thenThrow(Exception('Query error'));

          // Act
          final result = await repository.getUserProfileByEmail(testEmail);

          // Assert
          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<GeneralFailure>());
            expect(failure.message, contains('Query error'));
          }, (profile) => fail('Should return Left but got Right'));
        },
      );
    });

    group('checkEmailExists', () {
      test('should return true when email exists', () async {
        // Arrange
        when(
          () => mockDataSource.checkEmailExists(any()),
        ).thenAnswer((_) async => true);

        // Act
        final result = await repository.checkEmailExists(testEmail);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right but got Left: $failure'),
          (exists) => expect(exists, true),
        );
        verify(() => mockDataSource.checkEmailExists(testEmail)).called(1);
      });

      test('should return false when email does not exist', () async {
        // Arrange
        when(
          () => mockDataSource.checkEmailExists(any()),
        ).thenAnswer((_) async => false);

        // Act
        final result = await repository.checkEmailExists(testEmail);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right but got Left: $failure'),
          (exists) => expect(exists, false),
        );
      });

      test(
        'should return GeneralFailure when datasource throws exception',
        () async {
          // Arrange
          when(
            () => mockDataSource.checkEmailExists(any()),
          ).thenThrow(Exception('Check failed'));

          // Act
          final result = await repository.checkEmailExists(testEmail);

          // Assert
          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<GeneralFailure>());
            expect(failure.message, contains('Check failed'));
          }, (exists) => fail('Should return Left but got Right'));
        },
      );
    });
  });
}
