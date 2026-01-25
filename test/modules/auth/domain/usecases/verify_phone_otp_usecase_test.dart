import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/verify_phone_otp_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';
import 'package:autobid_mobile/core/error/failures.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late VerifyPhoneOtpUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = VerifyPhoneOtpUseCase(mockRepository);
  });

  const testPhoneNumber = '+1234567890';
  const testOtp = '123456';

  group('VerifyPhoneOtpUseCase', () {
    test('should verify OTP successfully with correct code', () async {
      // Arrange
      when(
        () => mockRepository.verifyPhoneOtp(testPhoneNumber, testOtp),
      ).thenAnswer((_) async => const Right(true));

      // Act
      final result = await useCase(testPhoneNumber, testOtp);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return true'),
        (isVerified) => expect(isVerified, true),
      );

      verify(
        () => mockRepository.verifyPhoneOtp(testPhoneNumber, testOtp),
      ).called(1);
    });

    test('should return AuthFailure when OTP is incorrect', () async {
      // Arrange
      when(
        () => mockRepository.verifyPhoneOtp(testPhoneNumber, testOtp),
      ).thenAnswer((_) async => Left(AuthFailure('Invalid OTP')));

      // Act
      final result = await useCase(testPhoneNumber, testOtp);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<AuthFailure>());
        expect(failure.message, 'Invalid OTP');
      }, (_) => fail('Should return failure'));
    });

    test('should return AuthFailure when OTP has expired', () async {
      // Arrange
      when(
        () => mockRepository.verifyPhoneOtp(testPhoneNumber, testOtp),
      ).thenAnswer((_) async => Left(AuthFailure('OTP has expired')));

      // Act
      final result = await useCase(testPhoneNumber, testOtp);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<AuthFailure>());
        expect(failure.message, 'OTP has expired');
      }, (_) => fail('Should return failure'));
    });

    test('should return NetworkFailure when network is unavailable', () async {
      // Arrange
      when(
        () => mockRepository.verifyPhoneOtp(testPhoneNumber, testOtp),
      ).thenAnswer((_) async => Left(NetworkFailure('No internet connection')));

      // Act
      final result = await useCase(testPhoneNumber, testOtp);

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
        () => mockRepository.verifyPhoneOtp(testPhoneNumber, testOtp),
      ).thenAnswer((_) async => Left(ServerFailure('Server error')));

      // Act
      final result = await useCase(testPhoneNumber, testOtp);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Server error');
      }, (_) => fail('Should return failure'));
    });

    test('should handle empty OTP code', () async {
      // Arrange
      const emptyOtp = '';
      when(
        () => mockRepository.verifyPhoneOtp(testPhoneNumber, emptyOtp),
      ).thenAnswer((_) async => Left(AuthFailure('OTP code is required')));

      // Act
      final result = await useCase(testPhoneNumber, emptyOtp);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<AuthFailure>());
        expect(failure.message, 'OTP code is required');
      }, (_) => fail('Should return failure'));
    });
  });
}
