import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/auth/presentation/controllers/registration_controller.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/sign_up_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/entities/user_entity.dart';
import 'package:autobid_mobile/core/error/failures.dart';

class MockSignUpUseCase extends Mock implements SignUpUseCase {}

void main() {
  late RegistrationController controller;
  late MockSignUpUseCase mockSignUpUseCase;

  setUp(() {
    mockSignUpUseCase = MockSignUpUseCase();
    controller = RegistrationController(signUpUseCase: mockSignUpUseCase);
  });

  const testUser = UserEntity(
    id: 'user-123',
    email: 'test@example.com',
    phoneNumber: '+1234567890',
  );

  group('Initial State', () {
    test('should have correct initial values', () {
      expect(controller.isLoading, false);
      expect(controller.obscurePassword, true);
      expect(controller.obscureConfirmPassword, true);
      expect(controller.errorMessage, isNull);
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

    test('should notify listeners when toggled', () {
      var notified = false;
      controller.addListener(() => notified = true);

      controller.toggleConfirmPasswordVisibility();
      expect(notified, true);
    });
  });

  group('signUp', () {
    test('should sign up successfully', () async {
      // Arrange
      when(
        () => mockSignUpUseCase.call(
          email: 'test@example.com',
          username: 'testuser',
          password: 'password123',
        ),
      ).thenAnswer((_) async => const Right(testUser));

      // Act
      final result = await controller.signUp(
        email: 'test@example.com',
        username: 'testuser',
        password: 'password123',
        confirmPassword: 'password123',
      );

      // Assert
      expect(result, true);
      expect(controller.isLoading, false);
      expect(controller.errorMessage, isNull);

      verify(
        () => mockSignUpUseCase.call(
          email: 'test@example.com',
          username: 'testuser',
          password: 'password123',
        ),
      ).called(1);
    });

    test('should return false when email is empty', () async {
      // Act
      final result = await controller.signUp(
        email: '',
        username: 'testuser',
        password: 'password123',
        confirmPassword: 'password123',
      );

      // Assert
      expect(result, false);
      expect(controller.errorMessage, 'Please fill in all fields');
      expect(controller.isLoading, false);

      verifyNever(
        () => mockSignUpUseCase.call(
          email: any(named: 'email'),
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      );
    });

    test('should return false when username is empty', () async {
      // Act
      final result = await controller.signUp(
        email: 'test@example.com',
        username: '',
        password: 'password123',
        confirmPassword: 'password123',
      );

      // Assert
      expect(result, false);
      expect(controller.errorMessage, 'Please fill in all fields');
      expect(controller.isLoading, false);
    });

    test('should return false when password is empty', () async {
      // Act
      final result = await controller.signUp(
        email: 'test@example.com',
        username: 'testuser',
        password: '',
        confirmPassword: 'password123',
      );

      // Assert
      expect(result, false);
      expect(controller.errorMessage, 'Please fill in all fields');
      expect(controller.isLoading, false);
    });

    test('should return false when confirm password is empty', () async {
      // Act
      final result = await controller.signUp(
        email: 'test@example.com',
        username: 'testuser',
        password: 'password123',
        confirmPassword: '',
      );

      // Assert
      expect(result, false);
      expect(controller.errorMessage, 'Please fill in all fields');
      expect(controller.isLoading, false);
    });

    test('should return false when passwords do not match', () async {
      // Act
      final result = await controller.signUp(
        email: 'test@example.com',
        username: 'testuser',
        password: 'password123',
        confirmPassword: 'differentpassword',
      );

      // Assert
      expect(result, false);
      expect(controller.errorMessage, 'Passwords do not match');
      expect(controller.isLoading, false);

      verifyNever(
        () => mockSignUpUseCase.call(
          email: any(named: 'email'),
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      );
    });

    test(
      'should return false when password is less than 8 characters',
      () async {
        // Act
        final result = await controller.signUp(
          email: 'test@example.com',
          username: 'testuser',
          password: 'pass123',
          confirmPassword: 'pass123',
        );

        // Assert
        expect(result, false);
        expect(
          controller.errorMessage,
          'Password must be at least 8 characters',
        );
        expect(controller.isLoading, false);

        verifyNever(
          () => mockSignUpUseCase.call(
            email: any(named: 'email'),
            username: any(named: 'username'),
            password: any(named: 'password'),
          ),
        );
      },
    );

    test('should handle AuthFailure when email already exists', () async {
      // Arrange
      when(
        () => mockSignUpUseCase.call(
          email: any(named: 'email'),
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => Left(AuthFailure('Email already registered')));

      // Act
      final result = await controller.signUp(
        email: 'existing@example.com',
        username: 'testuser',
        password: 'password123',
        confirmPassword: 'password123',
      );

      // Assert
      expect(result, false);
      expect(controller.errorMessage, 'Email already registered');
      expect(controller.isLoading, false);
    });

    test('should handle ServerFailure when sign up fails', () async {
      // Arrange
      when(
        () => mockSignUpUseCase.call(
          email: any(named: 'email'),
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => Left(ServerFailure('Registration failed')));

      // Act
      final result = await controller.signUp(
        email: 'test@example.com',
        username: 'testuser',
        password: 'password123',
        confirmPassword: 'password123',
      );

      // Assert
      expect(result, false);
      expect(controller.errorMessage, 'Registration failed');
      expect(controller.isLoading, false);
    });

    test('should handle NetworkFailure when offline', () async {
      // Arrange
      when(
        () => mockSignUpUseCase.call(
          email: any(named: 'email'),
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => Left(NetworkFailure('No internet connection')));

      // Act
      final result = await controller.signUp(
        email: 'test@example.com',
        username: 'testuser',
        password: 'password123',
        confirmPassword: 'password123',
      );

      // Assert
      expect(result, false);
      expect(controller.errorMessage, 'No internet connection');
      expect(controller.isLoading, false);
    });

    test('should clear error message when starting new sign up', () async {
      // Arrange - Set initial error
      await controller.signUp(
        email: '',
        username: 'testuser',
        password: 'password123',
        confirmPassword: 'password123',
      );
      expect(controller.errorMessage, isNotNull);

      // Act - Try again
      when(
        () => mockSignUpUseCase.call(
          email: any(named: 'email'),
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Right(testUser));

      await controller.signUp(
        email: 'test@example.com',
        username: 'testuser',
        password: 'password123',
        confirmPassword: 'password123',
      );

      // Assert
      expect(controller.errorMessage, isNull);
    });

    test('should set loading state during sign up', () async {
      // Arrange
      when(
        () => mockSignUpUseCase.call(
          email: any(named: 'email'),
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return const Right(testUser);
      });

      // Act
      final future = controller.signUp(
        email: 'test@example.com',
        username: 'testuser',
        password: 'password123',
        confirmPassword: 'password123',
      );
      await Future.delayed(const Duration(milliseconds: 5));

      // Assert - During loading
      expect(controller.isLoading, true);

      // Wait for completion
      await future;
      expect(controller.isLoading, false);
    });

    test('should notify listeners during sign up process', () async {
      // Arrange
      when(
        () => mockSignUpUseCase.call(
          email: any(named: 'email'),
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Right(testUser));

      var notificationCount = 0;
      controller.addListener(() => notificationCount++);

      // Act
      await controller.signUp(
        email: 'test@example.com',
        username: 'testuser',
        password: 'password123',
        confirmPassword: 'password123',
      );

      // Assert - Should notify at least twice (loading start + completion)
      expect(notificationCount, greaterThanOrEqualTo(2));
    });
  });

  group('clearError', () {
    test('should clear error message', () async {
      // Arrange - Set error
      await controller.signUp(
        email: '',
        username: 'testuser',
        password: 'password123',
        confirmPassword: 'password123',
      );
      expect(controller.errorMessage, isNotNull);

      // Act
      controller.clearError();

      // Assert
      expect(controller.errorMessage, isNull);
    });

    test('should notify listeners when clearing error', () {
      // Arrange - Set error
      controller.signUp(
        email: '',
        username: 'testuser',
        password: 'password123',
        confirmPassword: 'password123',
      );

      var notified = false;
      controller.addListener(() => notified = true);

      // Act
      controller.clearError();

      // Assert
      expect(notified, true);
    });
  });
}
