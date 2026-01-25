import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/profile/domain/entities/user_profile_entity.dart';
import 'package:autobid_mobile/modules/profile/domain/repositories/profile_repository.dart';
import 'package:autobid_mobile/modules/profile/domain/usecases/update_profile_with_photo_usecase.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class FakeUserProfileEntity extends Fake implements UserProfileEntity {}

void main() {
  late UpdateProfileWithPhotoUseCase useCase;
  late MockProfileRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeUserProfileEntity());
  });

  setUp(() {
    mockRepository = MockProfileRepository();
    useCase = UpdateProfileWithPhotoUseCase(mockRepository);
  });

  group('UpdateProfileWithPhotoUseCase', () {
    const testUserId = 'test-user-id';
    const testProfileUrl = 'https://storage.example.com/profile.jpg';
    const testCoverUrl = 'https://storage.example.com/cover.jpg';

    const existingProfile = UserProfileEntity(
      id: testUserId,
      email: 'test@example.com',
      fullName: 'Test User',
      username: 'testuser',
      contactNumber: '+1234567890',
      profilePhotoUrl: 'old-profile.jpg',
      coverPhotoUrl: 'old-cover.jpg',
    );

    test('should update profile photo URL successfully', () async {
      // Arrange
      final updatedProfile = UserProfileEntity(
        id: testUserId,
        email: existingProfile.email,
        fullName: existingProfile.fullName,
        username: existingProfile.username,
        contactNumber: existingProfile.contactNumber,
        profilePhotoUrl: testProfileUrl,
        coverPhotoUrl: existingProfile.coverPhotoUrl,
      );

      when(
        () => mockRepository.updateProfile(any()),
      ).thenAnswer((_) async => Right(updatedProfile));

      // Act
      final result = await useCase(
        profile: existingProfile,
        profilePhotoUrl: testProfileUrl,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold((l) => fail('Should not return failure'), (r) {
        expect(r.profilePhotoUrl, equals(testProfileUrl));
        expect(r.coverPhotoUrl, equals(existingProfile.coverPhotoUrl));
      });
      verify(() => mockRepository.updateProfile(any())).called(1);
    });

    test('should update cover photo URL successfully', () async {
      // Arrange
      final updatedProfile = UserProfileEntity(
        id: testUserId,
        email: existingProfile.email,
        fullName: existingProfile.fullName,
        username: existingProfile.username,
        contactNumber: existingProfile.contactNumber,
        profilePhotoUrl: existingProfile.profilePhotoUrl,
        coverPhotoUrl: testCoverUrl,
      );

      when(
        () => mockRepository.updateProfile(any()),
      ).thenAnswer((_) async => Right(updatedProfile));

      // Act
      final result = await useCase(
        profile: existingProfile,
        coverPhotoUrl: testCoverUrl,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold((l) => fail('Should not return failure'), (r) {
        expect(r.coverPhotoUrl, equals(testCoverUrl));
        expect(r.profilePhotoUrl, equals(existingProfile.profilePhotoUrl));
      });
    });

    test('should update both photo URLs successfully', () async {
      // Arrange
      final updatedProfile = UserProfileEntity(
        id: testUserId,
        email: existingProfile.email,
        fullName: existingProfile.fullName,
        username: existingProfile.username,
        contactNumber: existingProfile.contactNumber,
        profilePhotoUrl: testProfileUrl,
        coverPhotoUrl: testCoverUrl,
      );

      when(
        () => mockRepository.updateProfile(any()),
      ).thenAnswer((_) async => Right(updatedProfile));

      // Act
      final result = await useCase(
        profile: existingProfile,
        profilePhotoUrl: testProfileUrl,
        coverPhotoUrl: testCoverUrl,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold((l) => fail('Should not return failure'), (r) {
        expect(r.profilePhotoUrl, equals(testProfileUrl));
        expect(r.coverPhotoUrl, equals(testCoverUrl));
      });
    });

    test('should return failure when updateProfile fails', () async {
      // Arrange
      const failure = ServerFailure('Update failed');
      when(
        () => mockRepository.updateProfile(any()),
      ).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(
        profile: existingProfile,
        profilePhotoUrl: testProfileUrl,
      );

      // Assert
      expect(result, equals(const Left(failure)));
    });

    test('should preserve existing URLs when new ones not provided', () async {
      // Arrange
      when(
        () => mockRepository.updateProfile(any()),
      ).thenAnswer((_) async => Right(existingProfile));

      // Act
      final result = await useCase(profile: existingProfile);

      // Assert
      expect(result.isRight(), true);
      result.fold((l) => fail('Should not return failure'), (r) {
        expect(r.profilePhotoUrl, equals(existingProfile.profilePhotoUrl));
        expect(r.coverPhotoUrl, equals(existingProfile.coverPhotoUrl));
      });
    });
  });
}
