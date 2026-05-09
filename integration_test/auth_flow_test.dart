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
      
      // Create a dummy file for image uploads safely on the emulator's storage
      // Using a real minimal 1x1 white pixel JPEG byte array to prevent codec errors
      final tempDir = await getTemporaryDirectory();
      final dummyFile = File('${tempDir.path}/test_dummy_image.jpg');
      if (!dummyFile.existsSync()) {
        final List<int> jpegData = [
          0xFF, 0xD8, 0xFF, 0xDB, 0x00, 0x43, 0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 
          0x07, 0x09, 0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12, 0x13, 0x0F, 
          0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20, 0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 
          0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29, 0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 
          0x38, 0x32, 0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01, 0x00, 0x01, 
          0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x14, 0x10, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
          0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 
          0x00, 0x3F, 0x00, 0x37, 0xFF, 0xD9
        ];
        dummyFile.writeAsBytesSync(jpegData);
      }

      // Helper to find the "Next" or "Submit" button
      Finder nextButton() => find.byType(FilledButton);

      // ---------------------------------------------------------
      // STEP 1: Account Setup
      // ---------------------------------------------------------
      print('▶ Testing Step 1: Account Setup');
      expect(find.text('Account Setup'), findsWidgets);
      
      await tester.enterText(find.byType(TextFormField).at(0), 'devrobot_88'); 
      await tester.enterText(find.byType(TextFormField).at(1), 'devrobot88@example.com'); 
      await tester.enterText(find.byType(TextFormField).at(2), 'SecurePass123!'); 
      await tester.enterText(find.byType(TextFormField).at(3), 'SecurePass123!'); 
      
      // Trigger async availability checks
      await kycController.checkUsernameAvailability('devrobot_88');
      await kycController.checkEmailAvailability('devrobot88@example.com');
      
      // Give the system a moment to process the async availability results
      await tester.pumpAndSettle(const Duration(seconds: 1));

      final checkbox0 = find.byType(Checkbox).at(0);
      final checkbox1 = find.byType(Checkbox).at(1);
      await tester.ensureVisible(checkbox0);
      await tester.tap(checkbox0, warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.ensureVisible(checkbox1);
      await tester.tap(checkbox1, warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.tap(nextButton());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ---------------------------------------------------------
      // STEP 2: Verification (OTP)
      // ---------------------------------------------------------
      print('▶ Testing Step 2: OTP Verification');
      expect(find.text('Verification'), findsWidgets);
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
      // Use 16 digits to pass PhilippineIdValidator.validateNationalId
      await tester.enterText(find.byType(TextFormField).first, '1234567890123456');
      kycController.setNationalIdFront(dummyFile);
      kycController.setNationalIdBack(dummyFile);
      await tester.pumpAndSettle();
      await tester.tap(nextButton());
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // ---------------------------------------------------------
      // STEP 4: Selfie Verification
      // ---------------------------------------------------------
      print('▶ Testing Step 4: Selfie');
      expect(find.textContaining('Selfie'), findsWidgets);
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
      await tester.enterText(find.byType(TextFormField).at(0), 'John');
      await tester.enterText(find.byType(TextFormField).at(2), 'Doe');
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
      await tester.tap(nextButton());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // CLEANUP
      if (dummyFile.existsSync()) dummyFile.deleteSync();
      print('✅ KYC Integration Test Completed Successfully!');
    });
  });
}
