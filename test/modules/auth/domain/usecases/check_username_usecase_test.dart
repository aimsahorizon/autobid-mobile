import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/check_username_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';
import 'package:autobid_mobile/core/error/failures.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late CheckUsernameUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = CheckUsernameUseCase(mockRepository);
  });

  const testUsername = 'testuser';

  group('CheckUsernameUseCase', () {
    test('should return true when username is available', () async {
      // Arrange
      when(
        () => mockRepository.checkUsernameAvailable(testUsername),
      ).thenAnswer((_) async => const Right(true));

      // Act
      final result = await useCase(testUsername);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return true'),
        (isAvailable) => expect(isAvailable, true),
      );

      verify(
        () => mockRepository.checkUsernameAvailable(testUsername),
      ).called(1);
    });

    test('should return false when username is already taken', () async {
      // Arrange
      when(
        () => mockRepository.checkUsernameAvailable(testUsername),
      ).thenAnswer((_) async => const Right(false));

      // Act
      final result = await useCase(testUsername);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return false'),
        (isAvailable) => expect(isAvailable, false),
      );
    });

    test('should return NetworkFailure when network is unavailable', () async {
      // Arrange
      when(
        () => mockRepository.checkUsernameAvailable(testUsername),
      ).thenAnswer((_) async => Left(NetworkFailure('No internet connection')));

      // Act
      final result = await useCase(testUsername);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<NetworkFailure>());
        expect(failure.message, 'No internet connection');
      }, (_) => fail('Should return failure'));
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      when(
        () => mockRepository.checkUsernameAvailable(testUsername),
      ).thenAnswer((_) async => Left(ServerFailure('Server error')));

      // Act
      final result = await useCase(testUsername);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Server error');
      }, (_) => fail('Should return failure'));
    });

    test('should return AuthFailure for invalid username format', () async {
      // Arrange
      const invalidUsername = 'a'; // Too short
      when(
        () => mockRepository.checkUsernameAvailable(invalidUsername),
      ).thenAnswer(
        (_) async =>
            Left(AuthFailure('Username must be at least 3 characters')),
      );

      // Act
      final result = await useCase(invalidUsername);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<AuthFailure>());
        expect(failure.message, contains('at least 3 characters'));
      }, (_) => fail('Should return failure'));
    });

    test('should handle username with special characters', () async {
      // Arrange
      const specialUsername = 'test@user#';
      when(
        () => mockRepository.checkUsernameAvailable(specialUsername),
      ).thenAnswer(
        (_) async => Left(
          AuthFailure(
            'Username can only contain letters, numbers, and underscores',
          ),
        ),
      );

      // Act
      final result = await useCase(specialUsername);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<AuthFailure>());
        expect(failure.message, contains('letters, numbers, and underscores'));
      }, (_) => fail('Should return failure'));
    });
  });
}
