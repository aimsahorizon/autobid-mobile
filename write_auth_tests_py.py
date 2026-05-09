import os

test_dir = 'test/modules/auth/domain/usecases'
os.makedirs(test_dir, exist_ok=True)

test_entity = """
const testUser = UserEntity(
  id: 'test-123',
  email: 'test@example.com',
  username: 'testuser',
);
"""

files = {
    'check_national_id_exists_usecase_test.dart': """
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
""",
    'check_secondary_id_exists_usecase_test.dart': """
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
""",
    'reset_password_usecase_test.dart': """
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
""",
    'send_email_otp_usecase_test.dart': """
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
""",
    'send_password_reset_usecase_test.dart': """
// ==============================================================================
// 🧪 CLEAN ARCHITECTURE TEST: SendPasswordResetUseCase
// 📍 LAYER: Domain (UseCase)
// 🎯 MODULE: auth
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/send_password_reset_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SendPasswordResetUseCase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = SendPasswordResetUseCase(mockRepository);
  });

  group('🔹 STANDARD BEHAVIOR - SendPasswordResetUseCase', () {
    const testUsername = 'testuser';

    test('✅ should return Right(void) when repository call is successful', () async {
      when(() => mockRepository.sendPasswordResetRequest(testUsername)).thenAnswer((_) async => const Right(null));
      final result = await usecase.call(testUsername);
      expect(result, equals(const Right(null)));
      verify(() => mockRepository.sendPasswordResetRequest(testUsername)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('❌ should return Left(Failure) when repository call fails', () async {
      const tFailure = ServerFailure('Server Error');
      when(() => mockRepository.sendPasswordResetRequest(testUsername)).thenAnswer((_) async => const Left(tFailure));
      final result = await usecase.call(testUsername);
      expect(result, equals(const Left(tFailure)));
      verify(() => mockRepository.sendPasswordResetRequest(testUsername)).called(1);
    });
  });

  group('🔴 REGRESSION FIXES', () {
    test('BUG-000: Placeholder for future regression tests', () {});
  });
}
""",
    'send_phone_otp_usecase_test.dart': """
// ==============================================================================
// 🧪 CLEAN ARCHITECTURE TEST: SendPhoneOtpUseCase
// 📍 LAYER: Domain (UseCase)
// 🎯 MODULE: auth
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/send_phone_otp_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SendPhoneOtpUseCase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = SendPhoneOtpUseCase(mockRepository);
  });

  group('🔹 STANDARD BEHAVIOR - SendPhoneOtpUseCase', () {
    const testPhone = '+639123456789';

    test('✅ should return Right(void) when repository call is successful', () async {
      when(() => mockRepository.sendPhoneOtp(testPhone)).thenAnswer((_) async => const Right(null));
      final result = await usecase.call(testPhone);
      expect(result, equals(const Right(null)));
      verify(() => mockRepository.sendPhoneOtp(testPhone)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('❌ should return Left(Failure) when repository call fails', () async {
      const tFailure = ServerFailure('Server Error');
      when(() => mockRepository.sendPhoneOtp(testPhone)).thenAnswer((_) async => const Left(tFailure));
      final result = await usecase.call(testPhone);
      expect(result, equals(const Left(tFailure)));
      verify(() => mockRepository.sendPhoneOtp(testPhone)).called(1);
    });
  });

  group('🔴 REGRESSION FIXES', () {
    test('BUG-000: Placeholder for future regression tests', () {});
  });
}
""",
    'sign_in_usecase_test.dart': f"""
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

class MockAuthRepository extends Mock implements AuthRepository {{}}

void main() {{
  late SignInUseCase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {{
    mockRepository = MockAuthRepository();
    usecase = SignInUseCase(mockRepository);
  }});

  {test_entity}

  group('🔹 STANDARD BEHAVIOR - SignInUseCase', () {{
    const testUsername = 'testuser';
    const testPassword = 'password123';

    test('✅ should return Right(UserEntity) when repository call is successful', () async {{
      when(() => mockRepository.signInWithUsername(testUsername, testPassword)).thenAnswer((_) async => const Right(testUser));
      final result = await usecase.call(testUsername, testPassword);
      expect(result, equals(const Right(testUser)));
      verify(() => mockRepository.signInWithUsername(testUsername, testPassword)).called(1);
      verifyNoMoreInteractions(mockRepository);
    }});

    test('❌ should return Left(Failure) when repository call fails', () async {{
      const tFailure = ServerFailure('Invalid credentials');
      when(() => mockRepository.signInWithUsername(testUsername, testPassword)).thenAnswer((_) async => const Left(tFailure));
      final result = await usecase.call(testUsername, testPassword);
      expect(result, equals(const Left(tFailure)));
      verify(() => mockRepository.signInWithUsername(testUsername, testPassword)).called(1);
    }});
  }});

  group('🔴 REGRESSION FIXES', () {{
    test('BUG-000: Placeholder for future regression tests', () {{}});
  }});
}}
""",
    'sign_in_with_google_usecase_test.dart': f"""
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

class MockAuthRepository extends Mock implements AuthRepository {{}}

void main() {{
  late SignInWithGoogleUseCase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {{
    mockRepository = MockAuthRepository();
    usecase = SignInWithGoogleUseCase(mockRepository);
  }});

  {test_entity}

  group('🔹 STANDARD BEHAVIOR - SignInWithGoogleUseCase', () {{
    
    test('✅ should return Right(UserEntity) when repository call is successful', () async {{
      when(() => mockRepository.signInWithGoogle()).thenAnswer((_) async => const Right(testUser));
      final result = await usecase.call();
      expect(result, equals(const Right(testUser)));
      verify(() => mockRepository.signInWithGoogle()).called(1);
      verifyNoMoreInteractions(mockRepository);
    }});

    test('❌ should return Left(Failure) when repository call fails', () async {{
      const tFailure = ServerFailure('Google Sign-In failed');
      when(() => mockRepository.signInWithGoogle()).thenAnswer((_) async => const Left(tFailure));
      final result = await usecase.call();
      expect(result, equals(const Left(tFailure)));
      verify(() => mockRepository.signInWithGoogle()).called(1);
    }});
  }});

  group('🔴 REGRESSION FIXES', () {{
    test('BUG-000: Placeholder for future regression tests', () {{}});
  }});
}}
""",
    'sign_up_usecase_test.dart': f"""
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

class MockAuthRepository extends Mock implements AuthRepository {{}}

void main() {{
  late SignUpUseCase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {{
    mockRepository = MockAuthRepository();
    usecase = SignUpUseCase(mockRepository);
  }});

  {test_entity}

  group('🔹 STANDARD BEHAVIOR - SignUpUseCase', () {{
    const testEmail = 'test@example.com';
    const testPassword = 'password123';
    const testUsername = 'testuser';

    test('✅ should return Right(UserEntity) when repository call is successful', () async {{
      when(() => mockRepository.signUp(testEmail, testPassword, username: testUsername)).thenAnswer((_) async => const Right(testUser));
      final result = await usecase.call(testEmail, testPassword, username: testUsername);
      expect(result, equals(const Right(testUser)));
      verify(() => mockRepository.signUp(testEmail, testPassword, username: testUsername)).called(1);
      verifyNoMoreInteractions(mockRepository);
    }});

    test('❌ should return Left(Failure) when repository call fails', () async {{
      const tFailure = ServerFailure('Registration failed');
      when(() => mockRepository.signUp(testEmail, testPassword, username: testUsername)).thenAnswer((_) async => const Left(tFailure));
      final result = await usecase.call(testEmail, testPassword, username: testUsername);
      expect(result, equals(const Left(tFailure)));
      verify(() => mockRepository.signUp(testEmail, testPassword, username: testUsername)).called(1);
    }});
  }});

  group('🔴 REGRESSION FIXES', () {{
    test('BUG-000: Placeholder for future regression tests', () {{}});
  }});
}}
""",
    'verify_email_otp_usecase_test.dart': """
// ==============================================================================
// 🧪 CLEAN ARCHITECTURE TEST: VerifyEmailOtpUseCase
// 📍 LAYER: Domain (UseCase)
// 🎯 MODULE: auth
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/verify_email_otp_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late VerifyEmailOtpUseCase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = VerifyEmailOtpUseCase(mockRepository);
  });

  group('🔹 STANDARD BEHAVIOR - VerifyEmailOtpUseCase', () {
    const testEmail = 'test@example.com';
    const testOtp = '123456';

    test('✅ should return Right(bool) when repository call is successful', () async {
      when(() => mockRepository.verifyEmailOtp(testEmail, testOtp)).thenAnswer((_) async => const Right(true));
      final result = await usecase.call(testEmail, testOtp);
      expect(result, equals(const Right(true)));
      verify(() => mockRepository.verifyEmailOtp(testEmail, testOtp)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('❌ should return Left(Failure) when repository call fails', () async {
      const tFailure = ServerFailure('Invalid OTP');
      when(() => mockRepository.verifyEmailOtp(testEmail, testOtp)).thenAnswer((_) async => const Left(tFailure));
      final result = await usecase.call(testEmail, testOtp);
      expect(result, equals(const Left(tFailure)));
      verify(() => mockRepository.verifyEmailOtp(testEmail, testOtp)).called(1);
    });
  });

  group('🔴 REGRESSION FIXES', () {
    test('BUG-000: Placeholder for future regression tests', () {});
  });
}
""",
    'verify_otp_usecase_test.dart': """
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
""",
    'verify_phone_otp_usecase_test.dart': """
// ==============================================================================
// 🧪 CLEAN ARCHITECTURE TEST: VerifyPhoneOtpUseCase
// 📍 LAYER: Domain (UseCase)
// 🎯 MODULE: auth
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/verify_phone_otp_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late VerifyPhoneOtpUseCase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = VerifyPhoneOtpUseCase(mockRepository);
  });

  group('🔹 STANDARD BEHAVIOR - VerifyPhoneOtpUseCase', () {
    const testPhone = '+639123456789';
    const testOtp = '123456';

    test('✅ should return Right(bool) when repository call is successful', () async {
      when(() => mockRepository.verifyPhoneOtp(testPhone, testOtp)).thenAnswer((_) async => const Right(true));
      final result = await usecase.call(testPhone, testOtp);
      expect(result, equals(const Right(true)));
      verify(() => mockRepository.verifyPhoneOtp(testPhone, testOtp)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('❌ should return Left(Failure) when repository call fails', () async {
      const tFailure = ServerFailure('Invalid OTP');
      when(() => mockRepository.verifyPhoneOtp(testPhone, testOtp)).thenAnswer((_) async => const Left(tFailure));
      final result = await usecase.call(testPhone, testOtp);
      expect(result, equals(const Left(tFailure)));
      verify(() => mockRepository.verifyPhoneOtp(testPhone, testOtp)).called(1);
    });
  });

  group('🔴 REGRESSION FIXES', () {
    test('BUG-000: Placeholder for future regression tests', () {});
  });
}
""",
    'manage_local_auth_usecase_test.dart': """
// ==============================================================================
// 🧪 CLEAN ARCHITECTURE TEST: ManageLocalAuthUseCase
// 📍 LAYER: Domain (UseCase)
// 🎯 MODULE: auth
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
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
"""
}

for name, content in files.items():
    path = os.path.join(test_dir, name)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content.strip() + '\n')

print(f"Successfully wrote {len(files)} Auth UseCase test files.")
