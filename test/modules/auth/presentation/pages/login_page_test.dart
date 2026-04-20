// ==============================================================================
// 🧪 CLEAN ARCHITECTURE TEST: LoginPage
// 📍 LAYER: Presentation (Widget)
// 🎯 MODULE: auth
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:autobid_mobile/modules/auth/presentation/pages/login_page.dart';
import 'package:autobid_mobile/modules/auth/presentation/controllers/login_controller.dart';

import 'package:autobid_mobile/core/controllers/theme_controller.dart';
import 'package:autobid_mobile/modules/auth/presentation/controllers/login_otp_controller.dart';
import 'package:get_it/get_it.dart';

// ------------------------------------------------------------------------------
// 🛠️ MOCK DEFINITIONS
// ------------------------------------------------------------------------------
class MockLoginController extends Mock implements LoginController {}
class MockThemeController extends Mock implements ThemeController {}
class MockLoginOtpController extends Mock implements LoginOtpController {}

void main() {
  late MockLoginController mockController;
  late MockThemeController mockThemeController;
  late MockLoginOtpController mockOtpController;

  setUp(() {
    mockController = MockLoginController();
    mockThemeController = MockThemeController();
    mockOtpController = MockLoginOtpController();
    
    final sl = GetIt.instance;
    sl.allowReassignment = true;
    sl.registerFactory<LoginOtpController>(() => mockOtpController);

    // Provide default state for the view
    when(() => mockController.isLoading).thenReturn(false);
    when(() => mockController.obscurePassword).thenReturn(true);
    when(() => mockController.errorMessage).thenReturn(null);
    when(() => mockController.rememberMe).thenReturn(false);
    when(() => mockController.cachedUsername).thenReturn(null);
    when(() => mockController.isPendingVerification).thenReturn(false);
    when(() => mockController.currentStep).thenReturn(LoginStep.credentials);
    when(() => mockController.devModeBypassOtp).thenReturn(false);
    when(() => mockController.loadCachedCredentials()).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        body: LoginPage(
          controller: mockController,
          themeController: mockThemeController,
        ),
      ),
    );
  }

  // ============================================================================
  // 🔹 STANDARD BEHAVIOR TESTS
  // ============================================================================
  group('🔹 STANDARD BEHAVIOR - LoginPage', () {
    testWidgets('✅ renders login text fields successfully', (WidgetTester tester) async {
      // ACT
      await tester.pumpWidget(createWidgetUnderTest());
      
      // ASSERT
      expect(find.byType(TextField), findsWidgets); // Should find Username and Password fields
    });
  });

  // ============================================================================
  // 🔴 REGRESSION FIXES
  // ============================================================================
  group('🔴 REGRESSION FIXES', () {
    testWidgets('BUG-000: Placeholder for widget regression test', (WidgetTester tester) async {
      // Write failing visual test here
    });
  });
}
