// ==============================================================================
// 🧪 CLEAN ARCHITECTURE TEST: AuthFlow
// 📍 LAYER: End-to-End (Integration)
// 🎯 MODULE: auth
// ==============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:autobid_mobile/main.dart' as app;
import 'package:autobid_mobile/app/di/app_module.dart';
import 'package:autobid_mobile/modules/auth/presentation/controllers/kyc_registration_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('🔹 E2E - Auth Module Flow', () {
    
    testWidgets('✅ User can complete entire KYC Registration flow step-by-step', (WidgetTester tester) async {
      // 1. ARRANGE -> Boot the full application
      await GetIt.instance.reset();
      app.main(); 
      
      // Wait for splash screen (1s delay) + rendering
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Tap 'Skip' on the Onboarding Page if it appears
      final skipButton = find.text('Skip');
      if (skipButton.evaluate().isNotEmpty) {
        await tester.tap(skipButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // 2. ACT -> Tap 'Sign Up' on the Login Page
      final signUpButton = find.text('Sign Up');
      expect(signUpButton, findsOneWidget);
      await tester.tap(signUpButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Grab Controller to assist with non-interactable native parts (Files/OTP)
      final kycController = sl<KYCRegistrationController>();
      final tempDir = await getTemporaryDirectory();
      final dummyFile = File('${tempDir.path}/test_dummy_image.jpg');
      if (!dummyFile.existsSync()) {
        dummyFile.writeAsBytesSync([0, 1, 2, 3]);
      }

      // Helper to find the "Next" or "Submit" button
      Finder nextButton() => find.byType(FilledButton);

      // ---------------------------------------------------------
      // STEP 1: Account Setup
      // ---------------------------------------------------------
      print('▶ Testing Step 1: Account Setup');
      expect(find.text('Account Setup'), findsWidgets);
      
      // TextFormField indexing based on the UI layout:
      // index 0: Username
      // index 1: Email
      // index 2: Password
      // index 3: Confirm Password
      await tester.enterText(find.byType(TextFormField).at(0), 'devrobot_88'); // No 'test' keyword
      await tester.enterText(find.byType(TextFormField).at(1), 'devrobot88@example.com'); 
      await tester.enterText(find.byType(TextFormField).at(2), 'SecurePass123!'); 
      await tester.enterText(find.byType(TextFormField).at(3), 'SecurePass123!'); 
      
      // Inject availability status directly since remote check is reserved/blocked for 'test'
      kycController.setUsername('devrobot_88');
      kycController.setEmail('devrobot88@example.com');
      
      // Manual internal state override (using reflection or setters if available)
      // Since _isUsernameAvailable is private, we must rely on the controller logic.
      // But we can trigger a re-render
      await tester.pumpAndSettle();

      // Toggle checkboxes for Terms with visibility insurance
      final checkbox0 = find.byType(Checkbox).at(0);
      final checkbox1 = find.byType(Checkbox).at(1);

      await tester.ensureVisible(checkbox0);
      await tester.tap(checkbox0, warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.ensureVisible(checkbox1);
      await tester.tap(checkbox1, warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.tap(nextButton());
      // Explicitly wait for the animation to transition to the next step
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ---------------------------------------------------------
      // STEP 2: Verification (OTP)
      // ---------------------------------------------------------
      print('▶ Testing Step 2: OTP Verification');
      expect(find.text('Verification'), findsWidgets);
      
      // Bypass OTP via Controller (since we can't check real email/sms)
      kycController.setEmailOtpVerified(true);
      kycController.setPhoneOtpVerified(true);
      await tester.pumpAndSettle();

      await tester.tap(nextButton());
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // ---------------------------------------------------------
      // STEP 3: National ID
      // ---------------------------------------------------------
      print('▶ Testing Step 3: National ID');
      expect(find.text('National ID'), findsWidgets);
      await tester.enterText(find.byType(TextFormField).first, 'N-123456789');
      
      // Inject images (bypassing native camera picker)
      kycController.setNationalIdFront(dummyFile);
      kycController.setNationalIdBack(dummyFile);
      await tester.pumpAndSettle();

      await tester.tap(nextButton());
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // ---------------------------------------------------------
      // STEP 4: Selfie Verification
      // ---------------------------------------------------------
      print('▶ Testing Step 4: Selfie');
      expect(find.text('Selfie Verification'), findsWidgets);
      kycController.setSelfieWithId(dummyFile);
      await tester.pumpAndSettle();

      await tester.tap(nextButton());
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // ---------------------------------------------------------
      // STEP 5: Secondary ID
      // ---------------------------------------------------------
      print('▶ Testing Step 5: Secondary ID');
      expect(find.text('Secondary ID'), findsWidgets);
      await tester.enterText(find.byType(TextFormField).first, 'D-987654321');
      kycController.setSecondaryIdType('Drivers License');
      kycController.setSecondaryIdFront(dummyFile);
      kycController.setSecondaryIdBack(dummyFile);
      await tester.pumpAndSettle();

      await tester.tap(nextButton());
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // ---------------------------------------------------------
      // STEP 6: Personal Information
      // ---------------------------------------------------------
      print('▶ Testing Step 6: Personal Info');
      expect(find.text('Personal Information'), findsWidgets);
      await tester.enterText(find.byType(TextFormField).at(0), 'John'); // First Name
      await tester.enterText(find.byType(TextFormField).at(2), 'Doe');  // Last Name
      kycController.setSex('Male');
      kycController.setDateOfBirth(DateTime(1990, 1, 1));
      await tester.pumpAndSettle();

      await tester.tap(nextButton());
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // ---------------------------------------------------------
      // STEP 7: Address Details
      // ---------------------------------------------------------
      print('▶ Testing Step 7: Address');
      expect(find.text('Address Details'), findsWidgets);
      kycController.setRegion('NCR');
      kycController.setProvince('Metro Manila');
      kycController.setCity('Makati');
      kycController.setBarangay('Poblacion');
      await tester.enterText(find.byType(TextFormField).at(0), '123 Test Street');
      await tester.enterText(find.byType(TextFormField).at(1), '1210');
      await tester.pumpAndSettle();

      await tester.tap(nextButton());
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // ---------------------------------------------------------
      // STEP 8: Proof of Address
      // ---------------------------------------------------------
      print('▶ Testing Step 8: Proof of Address');
      expect(find.text('Proof of Address'), findsWidgets);
      kycController.setProofOfAddress(dummyFile);
      await tester.pumpAndSettle();

      await tester.tap(nextButton());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ---------------------------------------------------------
      // STEP 9: Review & Submit
      // ---------------------------------------------------------
      print('▶ Testing Step 9: Review & Submit');
      expect(find.text('Review Your Information'), findsWidgets);
      
      await tester.tap(nextButton()); // Taps 'Submit'
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // CLEANUP
      if (dummyFile.existsSync()) dummyFile.deleteSync();
      print('✅ KYC Integration Test Completed Successfully!');
    });
  });
}
