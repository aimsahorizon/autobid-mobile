// ==============================================================================
// 🧪 CLEAN ARCHITECTURE TEST: CheckNationalIdExistsUseCase
// 📍 LAYER: Domain (UseCase)
// 🎯 MODULE: auth
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/check_national_id_exists_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late CheckNationalIdExistsUseCase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = CheckNationalIdExistsUseCase(mockRepository);
  });

  group('🔹 STANDARD BEHAVIOR - CheckNationalIdExistsUseCase', () {
    const testId = 'N-123456';

    test('✅ should return Right(bool) when repository call is successful', () async {
      when(() => mockRepository.checkNationalIdExists(testId)).thenAnswer((_) async => const Right(true));
      final result = await usecase.call(testId);
      expect(result, equals(const Right(true)));
      verify(() => mockRepository.checkNationalIdExists(testId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('❌ should return Left(Failure) when repository call fails', () async {
      const tFailure = ServerFailure('Server Error');
      when(() => mockRepository.checkNationalIdExists(testId)).thenAnswer((_) async => const Left(tFailure));
      final result = await usecase.call(testId);
      expect(result, equals(const Left(tFailure)));
      verify(() => mockRepository.checkNationalIdExists(testId)).called(1);
    });
  });

  group('🔴 REGRESSION FIXES', () {
    test('BUG-000: Placeholder for future regression tests', () {});
  });
}