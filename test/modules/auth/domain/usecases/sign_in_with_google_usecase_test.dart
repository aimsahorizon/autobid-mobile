// ==============================================================================
// 🧪 CLEAN ARCHITECTURE TEST: SignInWithGoogleUseCase
// 📍 LAYER: Domain (UseCase)
// 🎯 MODULE: auth
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/auth/domain/entities/user_entity.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignInWithGoogleUseCase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = SignInWithGoogleUseCase(mockRepository);
  });

  const testUser = UserEntity(
    id: 'test-123',
    email: 'test@example.com',
    username: 'testuser',
  );

  group('🔹 STANDARD BEHAVIOR - SignInWithGoogleUseCase', () {
    
    test('✅ should return Right(UserEntity) when repository call is successful', () async {
      when(() => mockRepository.signInWithGoogle()).thenAnswer((_) async => const Right(testUser));
      final result = await usecase.call();
      expect(result, equals(const Right(testUser)));
      verify(() => mockRepository.signInWithGoogle()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('❌ should return Left(Failure) when repository call fails', () async {
      const tFailure = ServerFailure('Google Sign-In failed');
      when(() => mockRepository.signInWithGoogle()).thenAnswer((_) async => const Left(tFailure));
      final result = await usecase.call();
      expect(result, equals(const Left(tFailure)));
      verify(() => mockRepository.signInWithGoogle()).called(1);
    });
  });

  group('🔴 REGRESSION FIXES', () {
    test('BUG-000: Placeholder for future regression tests', () {});
  });
}