import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/reset_password_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';
import 'package:autobid_mobile/core/error/failures.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late ResetPasswordUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = ResetPasswordUseCase(mockRepository);
  });

  const testUsername = 'testuser';
  const testNewPassword = 'NewPassword123!';

  group('ResetPasswordUseCase', () {
    test('should reset password successfully', () async {
      // Arrange
      when(
        () => mockRepository.resetPassword(testUsername, testNewPassword),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final result = await useCase(testUsername, testNewPassword);

      // Assert
      expect(result.isRight(), true);
      verify(
        () => mockRepository.resetPassword(testUsername, testNewPassword),
      ).called(1);
    });

    test('should return AuthFailure when username not found', () async {
      // Arrange
      when(
        () => mockRepository.resetPassword(testUsername, testNewPassword),
      ).thenAnswer((_) async => Left(AuthFailure('User not found')));

      // Act
      final result = await useCase(testUsername, testNewPassword);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<AuthFailure>());
        expect(failure.message, 'User not found');
      }, (_) => fail('Should return failure'));
    });

    test('should return AuthFailure when password is too weak', () async {
      // Arrange
      const weakPassword = 'weak';
      when(
        () => mockRepository.resetPassword(testUsername, weakPassword),
      ).thenAnswer((_) async => Left(AuthFailure('Password too weak')));

      // Act
      final result = await useCase(testUsername, weakPassword);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<AuthFailure>());
        expect(failure.message, 'Password too weak');
      }, (_) => fail('Should return failure'));
    });

    test('should return AuthFailure when password is same as old', () async {
      // Arrange
      when(
        () => mockRepository.resetPassword(testUsername, testNewPassword),
      ).thenAnswer(
        (_) async => Left(
          AuthFailure('New password cannot be the same as old password'),
        ),
      );

      // Act
      final result = await useCase(testUsername, testNewPassword);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<AuthFailure>());
        expect(failure.message, contains('same as old password'));
      }, (_) => fail('Should return failure'));
    });

    test('should return NetworkFailure when network is unavailable', () async {
      // Arrange
      when(
        () => mockRepository.resetPassword(testUsername, testNewPassword),
      ).thenAnswer((_) async => Left(NetworkFailure('No internet connection')));

      // Act
      final result = await useCase(testUsername, testNewPassword);

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
        () => mockRepository.resetPassword(testUsername, testNewPassword),
      ).thenAnswer((_) async => Left(ServerFailure('Server error')));

      // Act
      final result = await useCase(testUsername, testNewPassword);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Server error');
      }, (_) => fail('Should return failure'));
    });
  });
}
