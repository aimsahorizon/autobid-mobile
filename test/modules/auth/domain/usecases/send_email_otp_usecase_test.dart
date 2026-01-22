import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/send_email_otp_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';
import 'package:autobid_mobile/core/error/failures.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SendEmailOtpUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SendEmailOtpUseCase(mockRepository);
  });

  const testEmail = 'test@example.com';

  group('SendEmailOtpUseCase', () {
    test('should send OTP successfully for valid email', () async {
      // Arrange
      when(
        () => mockRepository.sendEmailOtp(testEmail),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final result = await useCase(testEmail);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.sendEmailOtp(testEmail)).called(1);
    });

    test('should return AuthFailure for invalid email format', () async {
      // Arrange
      const invalidEmail = 'invalid-email';
      when(
        () => mockRepository.sendEmailOtp(invalidEmail),
      ).thenAnswer((_) async => Left(AuthFailure('Invalid email format')));

      // Act
      final result = await useCase(invalidEmail);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<AuthFailure>());
        expect(failure.message, 'Invalid email format');
      }, (_) => fail('Should return failure'));
    });

    test('should return NetworkFailure when network is unavailable', () async {
      // Arrange
      when(
        () => mockRepository.sendEmailOtp(testEmail),
      ).thenAnswer((_) async => Left(NetworkFailure('No internet connection')));

      // Act
      final result = await useCase(testEmail);

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
        () => mockRepository.sendEmailOtp(testEmail),
      ).thenAnswer((_) async => Left(ServerFailure('Server error')));

      // Act
      final result = await useCase(testEmail);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Server error');
      }, (_) => fail('Should return failure'));
    });

    test('should handle rate limiting failure', () async {
      // Arrange
      when(() => mockRepository.sendEmailOtp(testEmail)).thenAnswer(
        (_) async =>
            Left(AuthFailure('Too many OTP requests. Please try again later.')),
      );

      // Act
      final result = await useCase(testEmail);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<AuthFailure>());
        expect(failure.message, contains('Too many OTP requests'));
      }, (_) => fail('Should return failure'));
    });
  });
}
