import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/send_password_reset_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';
import 'package:autobid_mobile/core/error/failures.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SendPasswordResetUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SendPasswordResetUseCase(mockRepository);
  });

  const testUsername = 'testuser';

  group('SendPasswordResetUseCase', () {
    test('should send password reset request successfully', () async {
      // Arrange
      when(
        () => mockRepository.sendPasswordResetRequest(testUsername),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final result = await useCase(testUsername);

      // Assert
      expect(result.isRight(), true);
      verify(
        () => mockRepository.sendPasswordResetRequest(testUsername),
      ).called(1);
    });

    test('should return AuthFailure when username not found', () async {
      // Arrange
      when(
        () => mockRepository.sendPasswordResetRequest(testUsername),
      ).thenAnswer((_) async => Left(AuthFailure('User not found')));

      // Act
      final result = await useCase(testUsername);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<AuthFailure>());
        expect(failure.message, 'User not found');
      }, (_) => fail('Should return failure'));
    });

    test('should return AuthFailure when account is locked', () async {
      // Arrange
      when(
        () => mockRepository.sendPasswordResetRequest(testUsername),
      ).thenAnswer((_) async => Left(AuthFailure('Account is locked')));

      // Act
      final result = await useCase(testUsername);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<AuthFailure>());
        expect(failure.message, 'Account is locked');
      }, (_) => fail('Should return failure'));
    });

    test('should return NetworkFailure when network is unavailable', () async {
      // Arrange
      when(
        () => mockRepository.sendPasswordResetRequest(testUsername),
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
        () => mockRepository.sendPasswordResetRequest(testUsername),
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

    test('should handle rate limiting', () async {
      // Arrange
      when(
        () => mockRepository.sendPasswordResetRequest(testUsername),
      ).thenAnswer(
        (_) async => Left(
          AuthFailure('Too many reset attempts. Please try again later.'),
        ),
      );

      // Act
      final result = await useCase(testUsername);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<AuthFailure>());
        expect(failure.message, contains('Too many reset attempts'));
      }, (_) => fail('Should return failure'));
    });
  });
}
