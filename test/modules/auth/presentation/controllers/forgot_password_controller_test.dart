import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/send_password_reset_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/reset_password_usecase.dart';
import 'package:autobid_mobile/core/error/failures.dart';

class MockSendPasswordResetUseCase extends Mock
    implements SendPasswordResetUseCase {}

class MockVerifyOtpUseCase extends Mock implements VerifyOtpUseCase {}

class MockResetPasswordUseCase extends Mock implements ResetPasswordUseCase {}

void main() {
  late ForgotPasswordController controller;
  late MockSendPasswordResetUseCase mockSendPasswordResetUseCase;
  late MockVerifyOtpUseCase mockVerifyOtpUseCase;
  late MockResetPasswordUseCase mockResetPasswordUseCase;

  setUp(() {
    mockSendPasswordResetUseCase = MockSendPasswordResetUseCase();
    mockVerifyOtpUseCase = MockVerifyOtpUseCase();
    mockResetPasswordUseCase = MockResetPasswordUseCase();

    controller = ForgotPasswordController(
      sendPasswordResetUseCase: mockSendPasswordResetUseCase,
      verifyOtpUseCase: mockVerifyOtpUseCase,
      resetPasswordUseCase: mockResetPasswordUseCase,
    );
  });

  group('Initial State', () {
    test('should have correct initial values', () {
      expect(controller.currentStep, ForgotPasswordStep.enterUsername);
      expect(controller.isLoading, false);
      expect(controller.errorMessage, isNull);
      expect(controller.username, '');
      expect(controller.obscurePassword, true);
      expect(controller.obscureConfirmPassword, true);
    });
  });

  group('togglePasswordVisibility', () {
    test('should toggle password visibility', () {
      expect(controller.obscurePassword, true);

      controller.togglePasswordVisibility();
      expect(controller.obscurePassword, false);

      controller.togglePasswordVisibility();
      expect(controller.obscurePassword, true);
    });

    test('should notify listeners when toggled', () {
      var notified = false;
      controller.addListener(() => notified = true);

      controller.togglePasswordVisibility();
      expect(notified, true);
    });
  });

  group('toggleConfirmPasswordVisibility', () {
    test('should toggle confirm password visibility', () {
      expect(controller.obscureConfirmPassword, true);

      controller.toggleConfirmPasswordVisibility();
      expect(controller.obscureConfirmPassword, false);

      controller.toggleConfirmPasswordVisibility();
      expect(controller.obscureConfirmPassword, true);
    });
  });

  group('sendResetRequest', () {
    test('should send reset request successfully', () async {
      // Arrange
      when(
        () => mockSendPasswordResetUseCase.call('testuser'),
      ).thenAnswer((_) async => const Right(null));

      // Act
      await controller.sendResetRequest('testuser');

      // Assert
      expect(controller.currentStep, ForgotPasswordStep.verifyOtp);
      expect(controller.username, 'testuser');
      expect(controller.isLoading, false);
      expect(controller.errorMessage, isNull);

      verify(() => mockSendPasswordResetUseCase.call('testuser')).called(1);
    });

    test('should not send request when username is empty', () async {
      // Act
      await controller.sendResetRequest('');

      // Assert
      expect(controller.errorMessage, 'Please enter your username');
      expect(controller.currentStep, ForgotPasswordStep.enterUsername);

      verifyNever(() => mockSendPasswordResetUseCase.call(any()));
    });

    test('should handle ServerFailure when request fails', () async {
      // Arrange
      when(() => mockSendPasswordResetUseCase.call(any())).thenAnswer(
        (_) async => Left(ServerFailure('Failed to send reset request')),
      );

      // Act
      await controller.sendResetRequest('testuser');

      // Assert
      expect(controller.errorMessage, 'Failed to send reset request');
      expect(controller.isLoading, false);
      expect(controller.currentStep, ForgotPasswordStep.enterUsername);
    });

    test('should handle NotFoundFailure when user does not exist', () async {
      // Arrange
      when(
        () => mockSendPasswordResetUseCase.call(any()),
      ).thenAnswer((_) async => Left(NotFoundFailure('User not found')));

      // Act
      await controller.sendResetRequest('nonexistent');

      // Assert
      expect(controller.errorMessage, 'User not found');
      expect(controller.isLoading, false);
      expect(controller.currentStep, ForgotPasswordStep.enterUsername);
    });

    test('should clear error message when starting new request', () async {
      // Arrange - Set initial error
      await controller.sendResetRequest('');
      expect(controller.errorMessage, isNotNull);

      // Act - Try again
      when(
        () => mockSendPasswordResetUseCase.call(any()),
      ).thenAnswer((_) async => const Right(null));
      await controller.sendResetRequest('testuser');

      // Assert
      expect(controller.errorMessage, isNull);
    });

    test('should set loading state during request', () async {
      // Arrange
      when(() => mockSendPasswordResetUseCase.call(any())).thenAnswer((
        _,
      ) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return const Right(null);
      });

      // Act
      final future = controller.sendResetRequest('testuser');
      await Future.delayed(const Duration(milliseconds: 5));

      // Assert - During loading
      expect(controller.isLoading, true);

      // Wait for completion
      await future;
      expect(controller.isLoading, false);
    });
  });

  group('verifyOtp', () {
    setUp(() async {
      // Set username first
      when(
        () => mockSendPasswordResetUseCase.call(any()),
      ).thenAnswer((_) async => const Right(null));
      await controller.sendResetRequest('testuser');
    });

    test('should verify OTP successfully', () async {
      // Arrange
      when(
        () => mockVerifyOtpUseCase.call('testuser', '123456'),
      ).thenAnswer((_) async => const Right(true));

      // Act
      await controller.verifyOtp('123456');

      // Assert
      expect(controller.currentStep, ForgotPasswordStep.setNewPassword);
      expect(controller.isLoading, false);
      expect(controller.errorMessage, isNull);

      verify(() => mockVerifyOtpUseCase.call('testuser', '123456')).called(1);
    });

    test('should not verify when OTP is less than 6 digits', () async {
      // Act
      await controller.verifyOtp('12345');

      // Assert
      expect(controller.errorMessage, 'Please enter a valid 6-digit code');
      expect(controller.currentStep, ForgotPasswordStep.verifyOtp);

      verifyNever(() => mockVerifyOtpUseCase.call(any(), any()));
    });

    test('should not verify when OTP is more than 6 digits', () async {
      // Act
      await controller.verifyOtp('1234567');

      // Assert
      expect(controller.errorMessage, 'Please enter a valid 6-digit code');
      expect(controller.currentStep, ForgotPasswordStep.verifyOtp);
    });

    test('should handle invalid OTP', () async {
      // Arrange
      when(
        () => mockVerifyOtpUseCase.call(any(), any()),
      ).thenAnswer((_) async => const Right(false));

      // Act
      await controller.verifyOtp('123456');

      // Assert
      expect(controller.errorMessage, 'Invalid code. Please try again.');
      expect(controller.currentStep, ForgotPasswordStep.verifyOtp);
      expect(controller.isLoading, false);
    });

    test('should handle ServerFailure when verification fails', () async {
      // Arrange
      when(
        () => mockVerifyOtpUseCase.call(any(), any()),
      ).thenAnswer((_) async => Left(ServerFailure('Verification failed')));

      // Act
      await controller.verifyOtp('123456');

      // Assert
      expect(controller.errorMessage, 'Verification failed');
      expect(controller.isLoading, false);
      expect(controller.currentStep, ForgotPasswordStep.verifyOtp);
    });

    test('should clear error message when starting verification', () async {
      // Arrange - Set initial error
      await controller.verifyOtp('12345');
      expect(controller.errorMessage, isNotNull);

      // Act - Try again
      when(
        () => mockVerifyOtpUseCase.call(any(), any()),
      ).thenAnswer((_) async => const Right(true));
      await controller.verifyOtp('123456');

      // Assert
      expect(controller.errorMessage, isNull);
    });
  });

  group('resetPassword', () {
    setUp(() async {
      // Set username and verify OTP first
      when(
        () => mockSendPasswordResetUseCase.call(any()),
      ).thenAnswer((_) async => const Right(null));
      await controller.sendResetRequest('testuser');

      when(
        () => mockVerifyOtpUseCase.call(any(), any()),
      ).thenAnswer((_) async => const Right(true));
      await controller.verifyOtp('123456');
    });

    test('should reset password successfully', () async {
      // Arrange
      when(
        () => mockResetPasswordUseCase.call('testuser', 'newpassword123'),
      ).thenAnswer((_) async => const Right(null));

      // Act
      await controller.resetPassword('newpassword123', 'newpassword123');

      // Assert
      expect(controller.currentStep, ForgotPasswordStep.success);
      expect(controller.isLoading, false);
      expect(controller.errorMessage, isNull);

      verify(
        () => mockResetPasswordUseCase.call('testuser', 'newpassword123'),
      ).called(1);
    });

    test('should not reset when password is empty', () async {
      // Act
      await controller.resetPassword('', 'newpassword123');

      // Assert
      expect(controller.errorMessage, 'Please fill in all fields');
      expect(controller.currentStep, ForgotPasswordStep.setNewPassword);

      verifyNever(() => mockResetPasswordUseCase.call(any(), any()));
    });

    test('should not reset when confirm password is empty', () async {
      // Act
      await controller.resetPassword('newpassword123', '');

      // Assert
      expect(controller.errorMessage, 'Please fill in all fields');
      expect(controller.currentStep, ForgotPasswordStep.setNewPassword);
    });

    test('should not reset when password is less than 8 characters', () async {
      // Act
      await controller.resetPassword('pass123', 'pass123');

      // Assert
      expect(controller.errorMessage, 'Password must be at least 8 characters');
      expect(controller.currentStep, ForgotPasswordStep.setNewPassword);

      verifyNever(() => mockResetPasswordUseCase.call(any(), any()));
    });

    test('should not reset when passwords do not match', () async {
      // Act
      await controller.resetPassword('newpassword123', 'differentpassword');

      // Assert
      expect(controller.errorMessage, 'Passwords do not match');
      expect(controller.currentStep, ForgotPasswordStep.setNewPassword);

      verifyNever(() => mockResetPasswordUseCase.call(any(), any()));
    });

    test('should handle ServerFailure when reset fails', () async {
      // Arrange
      when(() => mockResetPasswordUseCase.call(any(), any())).thenAnswer(
        (_) async => Left(ServerFailure('Failed to reset password')),
      );

      // Act
      await controller.resetPassword('newpassword123', 'newpassword123');

      // Assert
      expect(controller.errorMessage, 'Failed to reset password');
      expect(controller.isLoading, false);
      expect(controller.currentStep, ForgotPasswordStep.setNewPassword);
    });

    test('should clear error message when starting reset', () async {
      // Arrange - Set initial error
      await controller.resetPassword('', 'newpassword123');
      expect(controller.errorMessage, isNotNull);

      // Act - Try again
      when(
        () => mockResetPasswordUseCase.call(any(), any()),
      ).thenAnswer((_) async => const Right(null));
      await controller.resetPassword('newpassword123', 'newpassword123');

      // Assert
      expect(controller.errorMessage, isNull);
    });
  });

  group('resendOtp', () {
    setUp(() async {
      // Set username first
      when(
        () => mockSendPasswordResetUseCase.call(any()),
      ).thenAnswer((_) async => const Right(null));
      await controller.sendResetRequest('testuser');
    });

    test('should resend OTP successfully', () async {
      // Arrange
      when(
        () => mockSendPasswordResetUseCase.call('testuser'),
      ).thenAnswer((_) async => const Right(null));

      // Act
      controller.resendOtp();
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert
      expect(controller.isLoading, false);
      expect(controller.errorMessage, isNull);

      // Called 2 times: once in setUp, once in resendOtp
      verify(() => mockSendPasswordResetUseCase.call('testuser')).called(2);
    });

    test('should handle failure when resend fails', () async {
      // Arrange
      when(
        () => mockSendPasswordResetUseCase.call(any()),
      ).thenAnswer((_) async => Left(ServerFailure('Failed to resend OTP')));

      // Act
      controller.resendOtp();
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert
      expect(controller.errorMessage, 'Failed to resend OTP');
      expect(controller.isLoading, false);
    });
  });

  group('clearError', () {
    test('should clear error message', () async {
      // Arrange - Set error
      await controller.sendResetRequest('');
      expect(controller.errorMessage, isNotNull);

      // Act
      controller.clearError();

      // Assert
      expect(controller.errorMessage, isNull);
    });

    test('should notify listeners when clearing error', () {
      // Arrange
      controller.sendResetRequest('');

      var notified = false;
      controller.addListener(() => notified = true);

      // Act
      controller.clearError();

      // Assert
      expect(notified, true);
    });
  });

  group('reset', () {
    test('should reset all state to initial values', () async {
      // Arrange - Go through the flow
      when(
        () => mockSendPasswordResetUseCase.call(any()),
      ).thenAnswer((_) async => const Right(null));
      await controller.sendResetRequest('testuser');

      when(
        () => mockVerifyOtpUseCase.call(any(), any()),
      ).thenAnswer((_) async => const Right(true));
      await controller.verifyOtp('123456');

      expect(controller.currentStep, ForgotPasswordStep.setNewPassword);
      expect(controller.username, 'testuser');

      // Act
      controller.reset();

      // Assert
      expect(controller.currentStep, ForgotPasswordStep.enterUsername);
      expect(controller.username, '');
      expect(controller.errorMessage, isNull);
      expect(controller.isLoading, false);
    });

    test('should notify listeners when reset', () {
      var notified = false;
      controller.addListener(() => notified = true);

      controller.reset();
      expect(notified, true);
    });
  });
}
