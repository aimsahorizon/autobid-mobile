import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/auth/presentation/controllers/login_controller.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/sign_in_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:autobid_mobile/modules/profile/domain/usecases/check_email_exists_usecase.dart';
import 'package:autobid_mobile/modules/profile/domain/usecases/get_user_profile_by_email_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/entities/user_entity.dart';
import 'package:autobid_mobile/modules/profile/domain/entities/user_profile_entity.dart';
import 'package:autobid_mobile/core/error/failures.dart';

class MockSignInUseCase extends Mock implements SignInUseCase {}

class MockSignInWithGoogleUseCase extends Mock
    implements SignInWithGoogleUseCase {}

class MockCheckEmailExistsUseCase extends Mock
    implements CheckEmailExistsUseCase {}

class MockGetUserProfileByEmailUseCase extends Mock
    implements GetUserProfileByEmailUseCase {}

void main() {
  late LoginController controller;
  late MockSignInUseCase mockSignInUseCase;
  late MockSignInWithGoogleUseCase mockSignInWithGoogleUseCase;
  late MockCheckEmailExistsUseCase mockCheckEmailExistsUseCase;
  late MockGetUserProfileByEmailUseCase mockGetUserProfileByEmailUseCase;

  setUp(() {
    mockSignInUseCase = MockSignInUseCase();
    mockSignInWithGoogleUseCase = MockSignInWithGoogleUseCase();
    mockCheckEmailExistsUseCase = MockCheckEmailExistsUseCase();
    mockGetUserProfileByEmailUseCase = MockGetUserProfileByEmailUseCase();

    controller = LoginController(
      signInUseCase: mockSignInUseCase,
      signInWithGoogleUseCase: mockSignInWithGoogleUseCase,
      checkEmailExistsUseCase: mockCheckEmailExistsUseCase,
      getUserProfileByEmailUseCase: mockGetUserProfileByEmailUseCase,
    );
  });

  const testUser = UserEntity(
    id: 'user-123',
    email: 'test@example.com',
    phoneNumber: '+1234567890',
  );

  final testProfile = UserProfileEntity(
    id: 'user-123',
    email: 'test@example.com',
    contactNumber: '+1234567890',
    coverPhotoUrl: '',
    profilePhotoUrl: '',
    fullName: 'Test User',
    username: 'testuser',
  );

  group('Initial State', () {
    test('should have correct initial values', () {
      expect(controller.isLoading, false);
      expect(controller.obscurePassword, true);
      expect(controller.errorMessage, isNull);
      expect(controller.currentStep, LoginStep.credentials);
      expect(controller.userEmail, isNull);
      expect(controller.userPhoneNumber, isNull);
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
  });

  group('signIn', () {
    test('should sign in successfully and move to OTP step', () async {
      // Arrange
      when(
        () => mockSignInUseCase.call('testuser', 'password123'),
      ).thenAnswer((_) async => const Right(testUser));

      // Act
      final result = await controller.signIn('testuser', 'password123');

      // Assert
      expect(result, true);
      expect(controller.currentStep, LoginStep.otpVerification);
      expect(controller.userEmail, testUser.email);
      expect(controller.userPhoneNumber, testUser.phoneNumber);
      expect(controller.isLoading, false);
      expect(controller.errorMessage, isNull);

      verify(() => mockSignInUseCase.call('testuser', 'password123')).called(1);
    });

    test('should return false and set error when username is empty', () async {
      // Act
      final result = await controller.signIn('', 'password123');

      // Assert
      expect(result, false);
      expect(controller.errorMessage, 'Please fill in all fields');
      expect(controller.currentStep, LoginStep.credentials);

      verifyNever(() => mockSignInUseCase.call(any(), any()));
    });

    test('should return false and set error when password is empty', () async {
      // Act
      final result = await controller.signIn('testuser', '');

      // Assert
      expect(result, false);
      expect(controller.errorMessage, 'Please fill in all fields');
      expect(controller.currentStep, LoginStep.credentials);

      verifyNever(() => mockSignInUseCase.call(any(), any()));
    });

    test(
      'should return false and set error when both fields are empty',
      () async {
        // Act
        final result = await controller.signIn('', '');

        // Assert
        expect(result, false);
        expect(controller.errorMessage, 'Please fill in all fields');
        expect(controller.currentStep, LoginStep.credentials);
      },
    );

    test('should handle AuthFailure for invalid credentials', () async {
      // Arrange
      when(
        () => mockSignInUseCase.call(any(), any()),
      ).thenAnswer((_) async => Left(AuthFailure('Invalid credentials')));

      // Act
      final result = await controller.signIn('testuser', 'wrongpassword');

      // Assert
      expect(result, false);
      expect(controller.errorMessage, 'Invalid credentials');
      expect(controller.isLoading, false);
      expect(controller.currentStep, LoginStep.credentials);
    });

    test('should handle NetworkFailure when offline', () async {
      // Arrange
      when(
        () => mockSignInUseCase.call(any(), any()),
      ).thenAnswer((_) async => Left(NetworkFailure('No internet connection')));

      // Act
      final result = await controller.signIn('testuser', 'password123');

      // Assert
      expect(result, false);
      expect(controller.errorMessage, 'No internet connection');
      expect(controller.isLoading, false);
    });

    test('should clear error message when starting new sign in', () async {
      // Arrange - Set initial error
      when(
        () => mockSignInUseCase.call(any(), any()),
      ).thenAnswer((_) async => Left(AuthFailure('Invalid credentials')));
      await controller.signIn('testuser', 'wrongpassword');
      expect(controller.errorMessage, isNotNull);

      // Act - Try again
      when(
        () => mockSignInUseCase.call(any(), any()),
      ).thenAnswer((_) async => const Right(testUser));
      await controller.signIn('testuser', 'password123');

      // Assert
      expect(controller.errorMessage, isNull);
    });

    test('should set loading state during sign in', () async {
      // Arrange
      when(() => mockSignInUseCase.call(any(), any())).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return const Right(testUser);
      });

      // Act
      final future = controller.signIn('testuser', 'password123');
      await Future.delayed(const Duration(milliseconds: 5));

      // Assert - During loading
      expect(controller.isLoading, true);

      // Wait for completion
      await future;
      expect(controller.isLoading, false);
    });
  });

  group('signInWithGoogle', () {
    test('should sign in with Google successfully', () async {
      // Arrange
      when(
        () => mockSignInWithGoogleUseCase.call(),
      ).thenAnswer((_) async => const Right(testUser));
      when(
        () => mockCheckEmailExistsUseCase.call(testUser.email),
      ).thenAnswer((_) async => const Right(true));
      when(
        () => mockGetUserProfileByEmailUseCase.call(testUser.email),
      ).thenAnswer((_) async => Right(testProfile));

      // Act
      final result = await controller.signInWithGoogle();

      // Assert
      expect(result, true);
      expect(controller.currentStep, LoginStep.otpVerification);
      expect(controller.userEmail, testProfile.email);
      expect(controller.userPhoneNumber, testProfile.contactNumber);
      expect(controller.isLoading, false);
      expect(controller.errorMessage, isNull);

      verify(() => mockSignInWithGoogleUseCase.call()).called(1);
      verify(() => mockCheckEmailExistsUseCase.call(testUser.email)).called(1);
      verify(
        () => mockGetUserProfileByEmailUseCase.call(testUser.email),
      ).called(1);
    });

    test('should fail when Google sign in fails', () async {
      // Arrange
      when(
        () => mockSignInWithGoogleUseCase.call(),
      ).thenAnswer((_) async => Left(AuthFailure('Google sign in cancelled')));

      // Act
      final result = await controller.signInWithGoogle();

      // Assert
      expect(result, false);
      expect(controller.errorMessage, 'Google sign in cancelled');
      expect(controller.isLoading, false);
      expect(controller.currentStep, LoginStep.credentials);

      verifyNever(() => mockCheckEmailExistsUseCase.call(any()));
      verifyNever(() => mockGetUserProfileByEmailUseCase.call(any()));
    });

    test('should fail when email does not exist', () async {
      // Arrange
      when(
        () => mockSignInWithGoogleUseCase.call(),
      ).thenAnswer((_) async => const Right(testUser));
      when(
        () => mockCheckEmailExistsUseCase.call(testUser.email),
      ).thenAnswer((_) async => const Right(false));

      // Act
      final result = await controller.signInWithGoogle();

      // Assert
      expect(result, false);
      expect(
        controller.errorMessage,
        'Account not registered. Please sign up first.',
      );
      expect(controller.isLoading, false);
      expect(controller.currentStep, LoginStep.credentials);

      verifyNever(() => mockGetUserProfileByEmailUseCase.call(any()));
    });

    test('should fail when email check fails', () async {
      // Arrange
      when(
        () => mockSignInWithGoogleUseCase.call(),
      ).thenAnswer((_) async => const Right(testUser));
      when(
        () => mockCheckEmailExistsUseCase.call(testUser.email),
      ).thenAnswer((_) async => Left(ServerFailure('Failed to check email')));

      // Act
      final result = await controller.signInWithGoogle();

      // Assert
      expect(result, false);
      expect(controller.errorMessage, 'Failed to check email');
      expect(controller.isLoading, false);

      verifyNever(() => mockGetUserProfileByEmailUseCase.call(any()));
    });

    test('should fail when profile is null', () async {
      // Arrange
      when(
        () => mockSignInWithGoogleUseCase.call(),
      ).thenAnswer((_) async => const Right(testUser));
      when(
        () => mockCheckEmailExistsUseCase.call(testUser.email),
      ).thenAnswer((_) async => const Right(true));
      when(
        () => mockGetUserProfileByEmailUseCase.call(testUser.email),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final result = await controller.signInWithGoogle();

      // Assert
      expect(result, false);
      expect(
        controller.errorMessage,
        'User profile not found. Please register.',
      );
      expect(controller.isLoading, false);
      expect(controller.currentStep, LoginStep.credentials);
    });

    test('should fail when profile fetch fails', () async {
      // Arrange
      when(
        () => mockSignInWithGoogleUseCase.call(),
      ).thenAnswer((_) async => const Right(testUser));
      when(
        () => mockCheckEmailExistsUseCase.call(testUser.email),
      ).thenAnswer((_) async => const Right(true));
      when(
        () => mockGetUserProfileByEmailUseCase.call(testUser.email),
      ).thenAnswer((_) async => Left(ServerFailure('Failed to fetch profile')));

      // Act
      final result = await controller.signInWithGoogle();

      // Assert
      expect(result, false);
      expect(controller.errorMessage, 'Failed to fetch profile');
      expect(controller.isLoading, false);
    });

    test('should set loading state during Google sign in', () async {
      // Arrange
      when(() => mockSignInWithGoogleUseCase.call()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return const Right(testUser);
      });
      when(
        () => mockCheckEmailExistsUseCase.call(testUser.email),
      ).thenAnswer((_) async => const Right(true));
      when(
        () => mockGetUserProfileByEmailUseCase.call(testUser.email),
      ).thenAnswer((_) async => Right(testProfile));

      // Act
      final future = controller.signInWithGoogle();
      await Future.delayed(const Duration(milliseconds: 5));

      // Assert - During loading
      expect(controller.isLoading, true);

      // Wait for completion
      await future;
      expect(controller.isLoading, false);
    });
  });

  group('completeLogin', () {
    test('should move to completed step', () {
      // Act
      controller.completeLogin();

      // Assert
      expect(controller.currentStep, LoginStep.completed);
    });

    test('should notify listeners when completing login', () {
      // Arrange
      var notified = false;
      controller.addListener(() => notified = true);

      // Act
      controller.completeLogin();

      // Assert
      expect(notified, true);
    });
  });

  group('reset', () {
    test('should reset all state to initial values', () async {
      // Arrange - Set some state
      when(
        () => mockSignInUseCase.call(any(), any()),
      ).thenAnswer((_) async => const Right(testUser));
      await controller.signIn('testuser', 'password123');
      controller.completeLogin();

      expect(controller.currentStep, LoginStep.completed);
      expect(controller.userEmail, isNotNull);
      expect(controller.userPhoneNumber, isNotNull);

      // Act
      controller.reset();

      // Assert
      expect(controller.currentStep, LoginStep.credentials);
      expect(controller.userEmail, isNull);
      expect(controller.userPhoneNumber, isNull);
      expect(controller.errorMessage, isNull);
    });
  });

  group('clearError', () {
    test('should clear error message', () async {
      // Arrange - Set error
      when(
        () => mockSignInUseCase.call(any(), any()),
      ).thenAnswer((_) async => Left(AuthFailure('Invalid credentials')));
      await controller.signIn('testuser', 'wrongpassword');
      expect(controller.errorMessage, isNotNull);

      // Act
      controller.clearError();

      // Assert
      expect(controller.errorMessage, isNull);
    });
  });
}
