// ==============================================================================
// 🧪 CLEAN ARCHITECTURE TEST: ManageLocalAuthUseCase
// 📍 LAYER: Domain (UseCase)
// 🎯 MODULE: auth
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/manage_local_auth_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late ManageLocalAuthUseCase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = ManageLocalAuthUseCase(mockRepository);
  });

  group('🔹 STANDARD BEHAVIOR - ManageLocalAuthUseCase', () {
    test('✅ cacheRememberMe should call repository and return Right', () async {
      when(() => mockRepository.cacheRememberMe(true)).thenAnswer((_) async => const Right(null));
      final result = await usecase.cacheRememberMe(true);
      expect(result, equals(const Right(null)));
      verify(() => mockRepository.cacheRememberMe(true)).called(1);
    });

    test('✅ getRememberMe should return Right(bool)', () async {
      when(() => mockRepository.getRememberMe()).thenAnswer((_) async => const Right(true));
      final result = await usecase.getRememberMe();
      expect(result, equals(const Right(true)));
      verify(() => mockRepository.getRememberMe()).called(1);
    });

    test('✅ cacheUsername should call repository and return Right', () async {
      when(() => mockRepository.cacheUsername('testuser')).thenAnswer((_) async => const Right(null));
      final result = await usecase.cacheUsername('testuser');
      expect(result, equals(const Right(null)));
      verify(() => mockRepository.cacheUsername('testuser')).called(1);
    });

    test('✅ getCachedUsername should return Right(String?)', () async {
      when(() => mockRepository.getCachedUsername()).thenAnswer((_) async => const Right('testuser'));
      final result = await usecase.getCachedUsername();
      expect(result, equals(const Right('testuser')));
      verify(() => mockRepository.getCachedUsername()).called(1);
    });
    
    test('✅ clearCachedUsername should call repository and return Right', () async {
      when(() => mockRepository.clearCachedUsername()).thenAnswer((_) async => const Right(null));
      final result = await usecase.clearCachedUsername();
      expect(result, equals(const Right(null)));
      verify(() => mockRepository.clearCachedUsername()).called(1);
    });
    
    test('✅ cacheOnboardingCompleted should call repository and return Right', () async {
      when(() => mockRepository.cacheOnboardingCompleted()).thenAnswer((_) async => const Right(null));
      final result = await usecase.cacheOnboardingCompleted();
      expect(result, equals(const Right(null)));
      verify(() => mockRepository.cacheOnboardingCompleted()).called(1);
    });
    
    test('✅ getOnboardingCompleted should return Right(bool)', () async {
      when(() => mockRepository.getOnboardingCompleted()).thenAnswer((_) async => const Right(true));
      final result = await usecase.getOnboardingCompleted();
      expect(result, equals(const Right(true)));
      verify(() => mockRepository.getOnboardingCompleted()).called(1);
    });
  });

  group('🔴 REGRESSION FIXES', () {
    test('BUG-000: Placeholder for future regression tests', () {});
  });
}