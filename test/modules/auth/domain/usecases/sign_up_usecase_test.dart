// ==============================================================================
// 🧪 CLEAN ARCHITECTURE TEST: SignUpUseCase
// 📍 LAYER: Domain (UseCase)
// 🎯 MODULE: auth
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/auth/domain/entities/user_entity.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/sign_up_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignUpUseCase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = SignUpUseCase(mockRepository);
  });

  const testUser = UserEntity(
    id: 'test-123',
    email: 'test@example.com',
    username: 'testuser',
  );

  group('🔹 STANDARD BEHAVIOR - SignUpUseCase', () {
    const testEmail = 'test@example.com';
    const testPassword = 'password123';
    const testUsername = 'testuser';

    test('✅ should return Right(UserEntity) when repository call is successful', () async {
      when(() => mockRepository.signUp(testEmail, testPassword, username: testUsername)).thenAnswer((_) async => const Right(testUser));
      final result = await usecase.call(email: testEmail, password: testPassword, username: testUsername);
      expect(result, equals(const Right(testUser)));
      verify(() => mockRepository.signUp(testEmail, testPassword, username: testUsername)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('❌ should return Left(Failure) when repository call fails', () async {
      const tFailure = ServerFailure('Registration failed');
      when(() => mockRepository.signUp(testEmail, testPassword, username: testUsername)).thenAnswer((_) async => const Left(tFailure));
      final result = await usecase.call(email: testEmail, password: testPassword, username: testUsername);
      expect(result, equals(const Left(tFailure)));
      verify(() => mockRepository.signUp(testEmail, testPassword, username: testUsername)).called(1);
    });
  });

  group('🔴 REGRESSION FIXES', () {
    test('BUG-000: Placeholder for future regression tests', () {});
  });
}