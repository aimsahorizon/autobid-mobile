// ==============================================================================
// 🧪 CLEAN ARCHITECTURE TEST: LoginController
// 📍 LAYER: Presentation (Controller)
// 🎯 MODULE: auth
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/auth/presentation/controllers/login_controller.dart';
import 'package:autobid_mobile/modules/profile/domain/usecases/check_email_exists_usecase.dart';
import 'package:autobid_mobile/modules/profile/domain/usecases/get_user_profile_by_email_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/sign_in_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/manage_local_auth_usecase.dart';

// ------------------------------------------------------------------------------
// 🛠️ MOCK DEFINITIONS
// ------------------------------------------------------------------------------
class MockSignInUseCase extends Mock implements SignInUseCase {}
class MockSignInWithGoogleUseCase extends Mock implements SignInWithGoogleUseCase {}
class MockCheckEmailExistsUseCase extends Mock implements CheckEmailExistsUseCase {}
class MockGetUserProfileByEmailUseCase extends Mock implements GetUserProfileByEmailUseCase {}
class MockManageLocalAuthUseCase extends Mock implements ManageLocalAuthUseCase {}

void main() {
  late LoginController controller;
  late MockSignInUseCase mockSignInUseCase;
  late MockSignInWithGoogleUseCase mockSignInWithGoogleUseCase;
  late MockCheckEmailExistsUseCase mockCheckEmailExistsUseCase;
  late MockGetUserProfileByEmailUseCase mockGetUserProfileByEmailUseCase;
  late MockManageLocalAuthUseCase mockManageLocalAuthUseCase;

  setUp(() {
    mockSignInUseCase = MockSignInUseCase();
    mockSignInWithGoogleUseCase = MockSignInWithGoogleUseCase();
    mockCheckEmailExistsUseCase = MockCheckEmailExistsUseCase();
    mockGetUserProfileByEmailUseCase = MockGetUserProfileByEmailUseCase();
    mockManageLocalAuthUseCase = MockManageLocalAuthUseCase();

    // Controller calls these in constructor
    when(() => mockManageLocalAuthUseCase.getRememberMe()).thenAnswer((_) async => const Right(false));
    when(() => mockManageLocalAuthUseCase.getCachedUsername()).thenAnswer((_) async => const Right(null));

    controller = LoginController(
      signInUseCase: mockSignInUseCase,
      signInWithGoogleUseCase: mockSignInWithGoogleUseCase,
      checkEmailExistsUseCase: mockCheckEmailExistsUseCase,
      getUserProfileByEmailUseCase: mockGetUserProfileByEmailUseCase,
      manageLocalAuthUseCase: mockManageLocalAuthUseCase,
    );
  });

  // ============================================================================
  // 🔹 STANDARD BEHAVIOR TESTS
  // ============================================================================
  group('🔹 STANDARD BEHAVIOR - LoginController', () {
    
    test('✅ togglePasswordVisibility should flip obscurePassword state and notify listeners', () {
      // ARRANGE
      expect(controller.obscurePassword, true);
      bool didNotify = false;
      controller.addListener(() => didNotify = true);

      // ACT
      controller.togglePasswordVisibility();

      // ASSERT
      expect(controller.obscurePassword, false);
      expect(didNotify, true);
    });

  });

  // ============================================================================
  // 🔴 REGRESSION FIXES
  // ============================================================================
  group('🔴 REGRESSION FIXES', () {
    test('BUG-000: Placeholder for controller regression test', () {});
  });
}
