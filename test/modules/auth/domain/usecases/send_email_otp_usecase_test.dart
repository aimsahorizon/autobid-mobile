// ==============================================================================
// 🧪 CLEAN ARCHITECTURE TEST: SendEmailOtpUseCase
// 📍 LAYER: Domain (UseCase)
// 🎯 MODULE: auth
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/send_email_otp_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SendEmailOtpUseCase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = SendEmailOtpUseCase(mockRepository);
  });

  group('🔹 STANDARD BEHAVIOR - SendEmailOtpUseCase', () {
    const testEmail = 'test@example.com';

    test('✅ should return Right(void) when repository call is successful', () async {
      when(() => mockRepository.sendEmailOtp(testEmail)).thenAnswer((_) async => const Right(null));
      final result = await usecase.call(testEmail);
      expect(result, equals(const Right(null)));
      verify(() => mockRepository.sendEmailOtp(testEmail)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('❌ should return Left(Failure) when repository call fails', () async {
      const tFailure = ServerFailure('Server Error');
      when(() => mockRepository.sendEmailOtp(testEmail)).thenAnswer((_) async => const Left(tFailure));
      final result = await usecase.call(testEmail);
      expect(result, equals(const Left(tFailure)));
      verify(() => mockRepository.sendEmailOtp(testEmail)).called(1);
    });
  });

  group('🔴 REGRESSION FIXES', () {
    test('BUG-000: Placeholder for future regression tests', () {});
  });
}