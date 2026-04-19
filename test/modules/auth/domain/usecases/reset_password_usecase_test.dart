// ==============================================================================
// 🧪 CLEAN ARCHITECTURE TEST: ResetPasswordUseCase
// 📍 LAYER: Domain (UseCase)
// 🎯 MODULE: auth
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/reset_password_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late ResetPasswordUseCase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = ResetPasswordUseCase(mockRepository);
  });

  group('🔹 STANDARD BEHAVIOR - ResetPasswordUseCase', () {
    const testUsername = 'testuser';
    const testPassword = 'newPassword123!';

    test('✅ should return Right(void) when repository call is successful', () async {
      when(() => mockRepository.resetPassword(testUsername, testPassword)).thenAnswer((_) async => const Right(null));
      final result = await usecase.call(testUsername, testPassword);
      expect(result, equals(const Right(null)));
      verify(() => mockRepository.resetPassword(testUsername, testPassword)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('❌ should return Left(Failure) when repository call fails', () async {
      const tFailure = ServerFailure('Server Error');
      when(() => mockRepository.resetPassword(testUsername, testPassword)).thenAnswer((_) async => const Left(tFailure));
      final result = await usecase.call(testUsername, testPassword);
      expect(result, equals(const Left(tFailure)));
      verify(() => mockRepository.resetPassword(testUsername, testPassword)).called(1);
    });
  });

  group('🔴 REGRESSION FIXES', () {
    test('BUG-000: Placeholder for future regression tests', () {});
  });
}