// ==============================================================================
// 🧪 CLEAN ARCHITECTURE TEST: SignInUseCase
// 📍 LAYER: Domain (UseCase)
// 🎯 MODULE: auth
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/auth/domain/entities/user_entity.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/sign_in_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignInUseCase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = SignInUseCase(mockRepository);
  });

  const testUser = UserEntity(
    id: 'test-123',
    email: 'test@example.com',
    username: 'testuser',
  );

  group('🔹 STANDARD BEHAVIOR - SignInUseCase', () {
    const testUsername = 'testuser';
    const testPassword = 'password123';

    test('✅ should return Right(UserEntity) when repository call is successful', () async {
      when(() => mockRepository.signInWithUsername(testUsername, testPassword)).thenAnswer((_) async => const Right(testUser));
      final result = await usecase.call(testUsername, testPassword);
      expect(result, equals(const Right(testUser)));
      verify(() => mockRepository.signInWithUsername(testUsername, testPassword)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('❌ should return Left(Failure) when repository call fails', () async {
      const tFailure = ServerFailure('Invalid credentials');
      when(() => mockRepository.signInWithUsername(testUsername, testPassword)).thenAnswer((_) async => const Left(tFailure));
      final result = await usecase.call(testUsername, testPassword);
      expect(result, equals(const Left(tFailure)));
      verify(() => mockRepository.signInWithUsername(testUsername, testPassword)).called(1);
    });
  });

  group('🔴 REGRESSION FIXES', () {
    test('BUG-000: Placeholder for future regression tests', () {});
  });
}