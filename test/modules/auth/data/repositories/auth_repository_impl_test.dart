import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/auth/data/repositories/auth_repository_impl.dart';
import 'package:autobid_mobile/modules/auth/data/datasources/auth_remote_datasource.dart';
import 'package:autobid_mobile/modules/auth/data/models/user_model.dart';
import 'package:autobid_mobile/modules/auth/data/models/kyc_registration_model.dart';
import 'package:autobid_mobile/modules/auth/domain/entities/user_entity.dart';
import 'package:autobid_mobile/modules/auth/domain/entities/kyc_registration_entity.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/core/error/exceptions.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class FakeKycRegistrationModel extends Fake implements KycRegistrationModel {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;

  setUpAll(() {
    registerFallbackValue(FakeKycRegistrationModel());
  });

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(mockRemoteDataSource);
  });

  final testUser = UserModel(
    id: 'user-123',
    email: 'test@example.com',
    username: 'testuser',
  );

  final testKycData = KycRegistrationModel(
    id: 'kyc-123',
    email: 'test@example.com',
    phoneNumber: '+1234567890',
    username: 'testuser',
    firstName: 'John',
    lastName: 'Doe',
    dateOfBirth: DateTime(1990, 1, 1),
    sex: 'Male',
    region: 'NCR',
    province: 'Metro Manila',
    city: 'Manila',
    barangay: 'Barangay 1',
    streetAddress: '123 Main St',
    zipcode: '1000',
    nationalIdNumber: 'ID123456',
    nationalIdFrontUrl: 'https://example.com/front.jpg',
    nationalIdBackUrl: 'https://example.com/back.jpg',
    secondaryGovIdType: 'driver_license',
    secondaryGovIdNumber: 'DL123456',
    secondaryGovIdFrontUrl: 'https://example.com/dl-front.jpg',
    secondaryGovIdBackUrl: 'https://example.com/dl-back.jpg',
    proofOfAddressType: 'utility_bill',
    proofOfAddressUrl: 'https://example.com/proof.jpg',
    selfieWithIdUrl: 'https://example.com/selfie.jpg',
    acceptedTermsAt: DateTime.now(),
    acceptedPrivacyAt: DateTime.now(),
    status: 'pending',
    submittedAt: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('getCurrentUser', () {
    test('should return UserEntity when datasource succeeds', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.getCurrentUser(),
      ).thenAnswer((_) async => testUser);

      // Act
      final result = await repository.getCurrentUser();

      // Assert
      expect(result, Right(testUser));
      verify(() => mockRemoteDataSource.getCurrentUser()).called(1);
    });

    test('should return null when no user is signed in', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.getCurrentUser(),
      ).thenAnswer((_) async => null);

      // Act
      final result = await repository.getCurrentUser();

      // Assert
      expect(result, const Right<Failure, UserEntity?>(null));
    });

    test(
      'should return ServerFailure when datasource throws ServerException',
      () async {
        // Arrange
        when(
          () => mockRemoteDataSource.getCurrentUser(),
        ).thenThrow(ServerException('Failed to get user'));

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result, Left(ServerFailure('Failed to get user')));
      },
    );

    test(
      'should return GeneralFailure when datasource throws generic exception',
      () async {
        // Arrange
        when(
          () => mockRemoteDataSource.getCurrentUser(),
        ).thenThrow(Exception('Unexpected error'));

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<GeneralFailure>()),
          (_) => fail('Should return failure'),
        );
      },
    );
  });

  group('signInWithUsername', () {
    test('should return UserEntity when sign in succeeds', () async {
      // Arrange
      when(
        () =>
            mockRemoteDataSource.signInWithUsername('testuser', 'password123'),
      ).thenAnswer((_) async => testUser);

      // Act
      final result = await repository.signInWithUsername(
        'testuser',
        'password123',
      );

      // Assert
      expect(result, Right(testUser));
      verify(
        () =>
            mockRemoteDataSource.signInWithUsername('testuser', 'password123'),
      ).called(1);
    });

    test('should return AuthFailure when credentials are invalid', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.signInWithUsername(any(), any()),
      ).thenThrow(AuthException('Invalid credentials'));

      // Act
      final result = await repository.signInWithUsername('testuser', 'wrong');

      // Assert
      expect(result, Left(AuthFailure('Invalid credentials')));
    });

    test('should return ServerFailure when server error occurs', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.signInWithUsername(any(), any()),
      ).thenThrow(ServerException('Server error'));

      // Act
      final result = await repository.signInWithUsername(
        'testuser',
        'password123',
      );

      // Assert
      expect(result, Left(ServerFailure('Server error')));
    });
  });

  group('signInWithGoogle', () {
    test('should return UserEntity when Google sign in succeeds', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.signInWithGoogle(),
      ).thenAnswer((_) async => testUser);

      // Act
      final result = await repository.signInWithGoogle();

      // Assert
      expect(result, Right(testUser));
      verify(() => mockRemoteDataSource.signInWithGoogle()).called(1);
    });

    test(
      'should return AuthFailure when Google sign in is cancelled',
      () async {
        // Arrange
        when(
          () => mockRemoteDataSource.signInWithGoogle(),
        ).thenThrow(AuthException('Sign in cancelled'));

        // Act
        final result = await repository.signInWithGoogle();

        // Assert
        expect(result, Left(AuthFailure('Sign in cancelled')));
      },
    );

    test('should return ServerFailure when server error occurs', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.signInWithGoogle(),
      ).thenThrow(ServerException('Server error'));

      // Act
      final result = await repository.signInWithGoogle();

      // Assert
      expect(result, Left(ServerFailure('Server error')));
    });
  });

  group('signOut', () {
    test('should return success when sign out succeeds', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.signOut(),
      ).thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.signOut();

      // Assert
      expect(result, const Right(null));
      verify(() => mockRemoteDataSource.signOut()).called(1);
    });

    test('should return ServerFailure when sign out fails', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.signOut(),
      ).thenThrow(ServerException('Failed to sign out'));

      // Act
      final result = await repository.signOut();

      // Assert
      expect(result, Left(ServerFailure('Failed to sign out')));
    });
  });

  group('signUp', () {
    test('should return UserEntity when sign up succeeds', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.signUp(
          any(),
          any(),
          username: any(named: 'username'),
        ),
      ).thenAnswer((_) async => testUser);

      // Act
      final result = await repository.signUp(
        'test@example.com',
        'password123',
        username: 'testuser',
      );

      // Assert
      expect(result, Right(testUser));
      verify(
        () => mockRemoteDataSource.signUp(
          'test@example.com',
          'password123',
          username: 'testuser',
        ),
      ).called(1);
    });

    test('should return AuthFailure when email already exists', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.signUp(
          any(),
          any(),
          username: any(named: 'username'),
        ),
      ).thenThrow(AuthException('Email already exists'));

      // Act
      final result = await repository.signUp('test@example.com', 'password123');

      // Assert
      expect(result, Left(AuthFailure('Email already exists')));
    });

    test('should return ServerFailure when server error occurs', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.signUp(
          any(),
          any(),
          username: any(named: 'username'),
        ),
      ).thenThrow(ServerException('Server error'));

      // Act
      final result = await repository.signUp('test@example.com', 'password123');

      // Assert
      expect(result, Left(ServerFailure('Server error')));
    });
  });

  group('Password Reset Flow', () {
    test('sendPasswordResetRequest should succeed', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.sendPasswordResetRequest(any()),
      ).thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.sendPasswordResetRequest('testuser');

      // Assert
      expect(result, const Right(null));
      verify(
        () => mockRemoteDataSource.sendPasswordResetRequest('testuser'),
      ).called(1);
    });

    test(
      'sendPasswordResetRequest should return ServerFailure on error',
      () async {
        // Arrange
        when(
          () => mockRemoteDataSource.sendPasswordResetRequest(any()),
        ).thenThrow(ServerException('Failed to send reset request'));

        // Act
        final result = await repository.sendPasswordResetRequest('testuser');

        // Assert
        expect(result, Left(ServerFailure('Failed to send reset request')));
      },
    );

    test('verifyOtp should return true when OTP is valid', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.verifyOtp(any(), any()),
      ).thenAnswer((_) async => true);

      // Act
      final result = await repository.verifyOtp('testuser', '123456');

      // Assert
      expect(result, const Right(true));
      verify(
        () => mockRemoteDataSource.verifyOtp('testuser', '123456'),
      ).called(1);
    });

    test('verifyOtp should return false when OTP is invalid', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.verifyOtp(any(), any()),
      ).thenAnswer((_) async => false);

      // Act
      final result = await repository.verifyOtp('testuser', '000000');

      // Assert
      expect(result, const Right(false));
    });

    test('resetPassword should succeed', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.resetPassword(any(), any()),
      ).thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.resetPassword(
        'testuser',
        'newpassword123',
      );

      // Assert
      expect(result, const Right(null));
      verify(
        () => mockRemoteDataSource.resetPassword('testuser', 'newpassword123'),
      ).called(1);
    });

    test('resetPassword should return ServerFailure on error', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.resetPassword(any(), any()),
      ).thenThrow(ServerException('Failed to reset password'));

      // Act
      final result = await repository.resetPassword(
        'testuser',
        'newpassword123',
      );

      // Assert
      expect(result, Left(ServerFailure('Failed to reset password')));
    });
  });

  group('OTP Verification', () {
    test('sendEmailOtp should succeed', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.sendEmailOtp(any()),
      ).thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.sendEmailOtp('test@example.com');

      // Assert
      expect(result, const Right(null));
      verify(
        () => mockRemoteDataSource.sendEmailOtp('test@example.com'),
      ).called(1);
    });

    test('sendPhoneOtp should succeed', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.sendPhoneOtp(any()),
      ).thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.sendPhoneOtp('+1234567890');

      // Assert
      expect(result, const Right(null));
      verify(() => mockRemoteDataSource.sendPhoneOtp('+1234567890')).called(1);
    });

    test('verifyEmailOtp should return true when valid', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.verifyEmailOtp(any(), any()),
      ).thenAnswer((_) async => true);

      // Act
      final result = await repository.verifyEmailOtp(
        'test@example.com',
        '123456',
      );

      // Assert
      expect(result, const Right(true));
    });

    test('verifyPhoneOtp should return true when valid', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.verifyPhoneOtp(any(), any()),
      ).thenAnswer((_) async => true);

      // Act
      final result = await repository.verifyPhoneOtp('+1234567890', '123456');

      // Assert
      expect(result, const Right(true));
    });
  });

  group('KYC Registration', () {
    test('submitKycRegistration should succeed', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.submitKycRegistration(any()),
      ).thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.submitKycRegistration(testKycData);

      // Assert
      expect(result, const Right(null));
      verify(() => mockRemoteDataSource.submitKycRegistration(any())).called(1);
    });

    test(
      'submitKycRegistration should return ServerFailure on error',
      () async {
        // Arrange
        when(
          () => mockRemoteDataSource.submitKycRegistration(any()),
        ).thenThrow(ServerException('Failed to submit KYC'));

        // Act
        final result = await repository.submitKycRegistration(testKycData);

        // Assert
        expect(result, Left(ServerFailure('Failed to submit KYC')));
      },
    );

    test(
      'getKycRegistrationStatus should return KYC data when found',
      () async {
        // Arrange
        when(
          () => mockRemoteDataSource.getKycRegistrationStatus(any()),
        ).thenAnswer((_) async => testKycData);

        // Act
        final result = await repository.getKycRegistrationStatus('user-123');

        // Assert
        expect(result, Right(testKycData));
        verify(
          () => mockRemoteDataSource.getKycRegistrationStatus('user-123'),
        ).called(1);
      },
    );

    test(
      'getKycRegistrationStatus should return null when not found',
      () async {
        // Arrange
        when(
          () => mockRemoteDataSource.getKycRegistrationStatus(any()),
        ).thenAnswer((_) async => null);

        // Act
        final result = await repository.getKycRegistrationStatus('user-123');

        // Assert
        expect(result, const Right<Failure, KycRegistrationEntity?>(null));
      },
    );

    test(
      'getKycRegistrationStatus should return ServerFailure on error',
      () async {
        // Arrange
        when(
          () => mockRemoteDataSource.getKycRegistrationStatus(any()),
        ).thenThrow(ServerException('Failed to get KYC status'));

        // Act
        final result = await repository.getKycRegistrationStatus('user-123');

        // Assert
        expect(result, Left(ServerFailure('Failed to get KYC status')));
      },
    );
  });

  group('checkUsernameAvailable', () {
    test('should return true when username is available', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.checkUsernameAvailable(any()),
      ).thenAnswer((_) async => true);

      // Act
      final result = await repository.checkUsernameAvailable('newuser');

      // Assert
      expect(result, const Right(true));
      verify(
        () => mockRemoteDataSource.checkUsernameAvailable('newuser'),
      ).called(1);
    });

    test('should return false when username is taken', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.checkUsernameAvailable(any()),
      ).thenAnswer((_) async => false);

      // Act
      final result = await repository.checkUsernameAvailable('existinguser');

      // Assert
      expect(result, const Right(false));
    });

    test('should return ServerFailure on error', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.checkUsernameAvailable(any()),
      ).thenThrow(ServerException('Failed to check username'));

      // Act
      final result = await repository.checkUsernameAvailable('testuser');

      // Assert
      expect(result, Left(ServerFailure('Failed to check username')));
    });
  });
}
