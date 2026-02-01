// ignore_for_file: void_checks

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/profile/domain/entities/user_profile_entity.dart';
import 'package:autobid_mobile/modules/profile/domain/repositories/profile_repository.dart';
import 'package:autobid_mobile/modules/profile/domain/usecases/upload_profile_photo_usecase.dart';
import 'package:autobid_mobile/modules/profile/domain/usecases/upload_cover_photo_usecase.dart';
import 'package:autobid_mobile/modules/profile/domain/usecases/update_profile_with_photo_usecase.dart';
import 'package:autobid_mobile/modules/profile/presentation/controllers/profile_controller.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockUploadProfilePhotoUseCase extends Mock
    implements UploadProfilePhotoUseCase {}

class MockUploadCoverPhotoUseCase extends Mock
    implements UploadCoverPhotoUseCase {}

class MockUpdateProfileWithPhotoUseCase extends Mock
    implements UpdateProfileWithPhotoUseCase {}

void main() {
  late ProfileController controller;
  late MockProfileRepository mockRepository;
  late MockUploadProfilePhotoUseCase mockUploadProfilePhoto;
  late MockUploadCoverPhotoUseCase mockUploadCoverPhoto;
  late MockUpdateProfileWithPhotoUseCase mockUpdateProfileWithPhoto;

  setUp(() {
    mockRepository = MockProfileRepository();
    mockUploadProfilePhoto = MockUploadProfilePhotoUseCase();
    mockUploadCoverPhoto = MockUploadCoverPhotoUseCase();
    mockUpdateProfileWithPhoto = MockUpdateProfileWithPhotoUseCase();

    controller = ProfileController(
      repository: mockRepository,
      uploadProfilePhotoUseCase: mockUploadProfilePhoto,
      uploadCoverPhotoUseCase: mockUploadCoverPhoto,
      updateProfileWithPhotoUseCase: mockUpdateProfileWithPhoto,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  group('ProfileController', () {
    const testProfile = UserProfileEntity(
      id: 'user-123',
      email: 'test@example.com',
      fullName: 'Test User',
      username: 'testuser',
      contactNumber: '+1234567890',
      profilePhotoUrl: 'https://example.com/profile.jpg',
      coverPhotoUrl: 'https://example.com/cover.jpg',
    );

    group('Initial State', () {
      test('should have correct initial state', () {
        expect(controller.profile, isNull);
        expect(controller.isLoading, false);
        expect(controller.errorMessage, isNull);
        expect(controller.hasError, false);
      });
    });

    group('loadProfile', () {
      test('should update loading state during profile load', () async {
        // Arrange
        when(
          () => mockRepository.getUserProfile(),
        ).thenAnswer((_) async => const Right(testProfile));

        // Act
        final future = controller.loadProfile();

        // Assert - should be loading
        expect(controller.isLoading, true);
        expect(controller.errorMessage, isNull);

        await future;

        // Assert - should finish loading
        expect(controller.isLoading, false);
      });

      test('should load profile successfully', () async {
        // Arrange
        when(
          () => mockRepository.getUserProfile(),
        ).thenAnswer((_) async => const Right(testProfile));

        // Act
        await controller.loadProfile();

        // Assert
        expect(controller.profile, equals(testProfile));
        expect(controller.errorMessage, isNull);
        expect(controller.hasError, false);
        expect(controller.isLoading, false);
        verify(() => mockRepository.getUserProfile()).called(1);
      });

      test('should handle failure when loading profile', () async {
        // Arrange
        const failure = ServerFailure('Failed to load profile');
        when(
          () => mockRepository.getUserProfile(),
        ).thenAnswer((_) async => const Left(failure));

        // Act
        await controller.loadProfile();

        // Assert
        expect(controller.profile, isNull);
        expect(controller.errorMessage, contains('Failed to load profile'));
        expect(controller.hasError, true);
        expect(controller.isLoading, false);
      });

      test('should clear previous error on new load attempt', () async {
        // Arrange - first load fails
        const failure = ServerFailure('Network error');
        when(
          () => mockRepository.getUserProfile(),
        ).thenAnswer((_) async => const Left(failure));
        await controller.loadProfile();
        expect(controller.hasError, true);

        // Act - second load succeeds
        when(
          () => mockRepository.getUserProfile(),
        ).thenAnswer((_) async => const Right(testProfile));
        await controller.loadProfile();

        // Assert
        expect(controller.errorMessage, isNull);
        expect(controller.hasError, false);
        expect(controller.profile, equals(testProfile));
      });

      test('should notify listeners on state change', () async {
        // Arrange
        when(
          () => mockRepository.getUserProfile(),
        ).thenAnswer((_) async => const Right(testProfile));

        var notificationCount = 0;
        controller.addListener(() => notificationCount++);

        // Act
        await controller.loadProfile();

        // Assert - should notify at least twice (loading start, loading end)
        expect(notificationCount, greaterThanOrEqualTo(2));
      });
    });

    group('signOut', () {
      test('should sign out successfully', () async {
        // Arrange - load profile first
        when(
          () => mockRepository.getUserProfile(),
        ).thenAnswer((_) async => const Right(testProfile));
        await controller.loadProfile();
        expect(controller.profile, equals(testProfile));
        when(
          () => mockRepository.signOut(),
        ).thenAnswer((_) async => const Right(unit));

        // Act
        await controller.signOut();

        // Assert
        expect(controller.profile, isNull);
        expect(controller.errorMessage, isNull);
        expect(controller.isLoading, false);
        verify(() => mockRepository.signOut()).called(1);
      });

      test('should handle sign out failure', () async {
        // Arrange
        const failure = ServerFailure('Failed to sign out');
        when(
          () => mockRepository.signOut(),
        ).thenAnswer((_) async => const Left(failure));

        // Act
        await controller.signOut();

        // Assert
        expect(controller.errorMessage, contains('Failed to sign out'));
        expect(controller.hasError, true);
        expect(controller.isLoading, false);
      });

      test('should update loading state during sign out', () async {
        // Arrange
        when(
          () => mockRepository.signOut(),
        ).thenAnswer((_) async => const Right(unit));

        // Act
        final future = controller.signOut();

        // Assert - should be loading
        expect(controller.isLoading, true);

        await future;

        // Assert - should finish loading
        expect(controller.isLoading, false);
      });

      test('should notify listeners on sign out', () async {
        // Arrange
        when(
          () => mockRepository.signOut(),
        ).thenAnswer((_) async => const Right(unit));

        var notificationCount = 0;
        controller.addListener(() => notificationCount++);

        // Act
        await controller.signOut();

        // Assert
        expect(notificationCount, greaterThanOrEqualTo(2));
      });
    });

    group('clearError', () {
      test('should clear error message', () async {
        // Arrange
        const failure = ServerFailure('Some error');
        when(
          () => mockRepository.getUserProfile(),
        ).thenAnswer((_) async => const Left(failure));
        await controller.loadProfile();
        expect(controller.hasError, true);

        // Act
        controller.clearError();

        // Assert
        expect(controller.errorMessage, isNull);
        expect(controller.hasError, false);
      });

      test('should notify listeners when clearing error', () {
        // Arrange
        var notificationCount = 0;
        controller.addListener(() => notificationCount++);

        // Act
        controller.clearError();

        // Assert
        expect(notificationCount, equals(1));
      });
    });

    group('Edge Cases', () {
      test('should handle multiple rapid load calls', () async {
        // Arrange
        when(
          () => mockRepository.getUserProfile(),
        ).thenAnswer((_) async => const Right(testProfile));

        // Act - call loadProfile multiple times rapidly
        await Future.wait([
          controller.loadProfile(),
          controller.loadProfile(),
          controller.loadProfile(),
        ]);

        // Assert - should complete without errors
        expect(controller.profile, equals(testProfile));
        expect(controller.hasError, false);
      });

      test('should handle null profile gracefully', () async {
        // Arrange - profile is null initially
        expect(controller.profile, isNull);

        // Act - sign out when profile is already null
        when(
          () => mockRepository.signOut(),
        ).thenAnswer((_) async => const Right(unit));
        await controller.signOut();

        // Assert - should still be null
        expect(controller.profile, isNull);
        expect(controller.hasError, false);
      });
    });
  });
}
