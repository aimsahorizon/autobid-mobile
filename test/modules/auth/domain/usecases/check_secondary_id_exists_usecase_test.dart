// ==============================================================================
// 🧪 CLEAN ARCHITECTURE TEST: CheckSecondaryIdExistsUseCase
// 📍 LAYER: Domain (UseCase)
// 🎯 MODULE: auth
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/check_secondary_id_exists_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late CheckSecondaryIdExistsUseCase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = CheckSecondaryIdExistsUseCase(mockRepository);
  });

  group('🔹 STANDARD BEHAVIOR - CheckSecondaryIdExistsUseCase', () {
    const testId = 'S-123456';
    const testType = 'Drivers License';

    test('✅ should return Right(bool) when repository call is successful', () async {
      when(() => mockRepository.checkSecondaryIdExists(testId, testType)).thenAnswer((_) async => const Right(false));
      final result = await usecase.call(testId, testType);
      expect(result, equals(const Right(false)));
      verify(() => mockRepository.checkSecondaryIdExists(testId, testType)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('❌ should return Left(Failure) when repository call fails', () async {
      const tFailure = ServerFailure('Server Error');
      when(() => mockRepository.checkSecondaryIdExists(testId, testType)).thenAnswer((_) async => const Left(tFailure));
      final result = await usecase.call(testId, testType);
      expect(result, equals(const Left(tFailure)));
      verify(() => mockRepository.checkSecondaryIdExists(testId, testType)).called(1);
    });
  });

  group('🔴 REGRESSION FIXES', () {
    test('BUG-000: Placeholder for future regression tests', () {});
  });
}