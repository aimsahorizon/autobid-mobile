import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/send_phone_otp_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';
import 'package:autobid_mobile/core/error/failures.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SendPhoneOtpUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SendPhoneOtpUseCase(mockRepository);
  });

  const testPhoneNumber = '+1234567890';

  group('SendPhoneOtpUseCase', () {
    test('should send OTP successfully for valid phone number', () async {
      // Arrange
      when(
        () => mockRepository.sendPhoneOtp(testPhoneNumber),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final result = await useCase(testPhoneNumber);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.sendPhoneOtp(testPhoneNumber)).called(1);
    });

    test('should return AuthFailure for invalid phone number format', () async {
      // Arrange
      const invalidPhone = '123';
      when(() => mockRepository.sendPhoneOtp(invalidPhone)).thenAnswer(
        (_) async => Left(AuthFailure('Invalid phone number format')),
      );

      // Act
      final result = await useCase(invalidPhone);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<AuthFailure>());
        expect(failure.message, 'Invalid phone number format');
      }, (_) => fail('Should return failure'));
    });

    test('should return NetworkFailure when network is unavailable', () async {
      // Arrange
      when(
        () => mockRepository.sendPhoneOtp(testPhoneNumber),
      ).thenAnswer((_) async => Left(NetworkFailure('No internet connection')));

      // Act
      final result = await useCase(testPhoneNumber);

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
        () => mockRepository.sendPhoneOtp(testPhoneNumber),
      ).thenAnswer((_) async => Left(ServerFailure('Server error')));

      // Act
      final result = await useCase(testPhoneNumber);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Server error');
      }, (_) => fail('Should return failure'));
    });

    test('should handle rate limiting failure', () async {
      // Arrange
      when(() => mockRepository.sendPhoneOtp(testPhoneNumber)).thenAnswer(
        (_) async =>
            Left(AuthFailure('Too many SMS requests. Please try again later.')),
      );

      // Act
      final result = await useCase(testPhoneNumber);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<AuthFailure>());
        expect(failure.message, contains('Too many SMS requests'));
      }, (_) => fail('Should return failure'));
    });
  });
}
