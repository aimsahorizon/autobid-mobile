// ==============================================================================
// 🧪 CLEAN ARCHITECTURE TEST: VerifyOtpUseCase
// 📍 LAYER: Domain (UseCase)
// 🎯 MODULE: auth
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late VerifyOtpUseCase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = VerifyOtpUseCase(mockRepository);
  });

  group('🔹 STANDARD BEHAVIOR - VerifyOtpUseCase', () {
    const testUsername = 'testuser';
    const testOtp = '123456';

    test('✅ should return Right(bool) when repository call is successful', () async {
      when(() => mockRepository.verifyOtp(testUsername, testOtp)).thenAnswer((_) async => const Right(true));
      final result = await usecase.call(testUsername, testOtp);
      expect(result, equals(const Right(true)));
      verify(() => mockRepository.verifyOtp(testUsername, testOtp)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('❌ should return Left(Failure) when repository call fails', () async {
      const tFailure = ServerFailure('Invalid OTP');
      when(() => mockRepository.verifyOtp(testUsername, testOtp)).thenAnswer((_) async => const Left(tFailure));
      final result = await usecase.call(testUsername, testOtp);
      expect(result, equals(const Left(tFailure)));
      verify(() => mockRepository.verifyOtp(testUsername, testOtp)).called(1);
    });
  });

  group('🔴 REGRESSION FIXES', () {
    test('BUG-000: Placeholder for future regression tests', () {});
  });
}