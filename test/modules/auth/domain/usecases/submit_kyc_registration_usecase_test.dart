import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/submit_kyc_registration_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';
import 'package:autobid_mobile/modules/auth/domain/entities/kyc_registration_entity.dart';
import 'package:autobid_mobile/core/error/failures.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SubmitKycRegistrationUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SubmitKycRegistrationUseCase(mockRepository);
  });

  final testKycData = KycRegistrationEntity(
    id: 'user-123',
    email: 'test@example.com',
    phoneNumber: '+1234567890',
    username: 'testuser',
    firstName: 'John',
    lastName: 'Doe',
    middleName: null,
    dateOfBirth: DateTime(1990, 1, 1),
    sex: 'M',
    region: 'NCR',
    province: 'Metro Manila',
    city: 'Manila',
    barangay: 'Test Barangay',
    streetAddress: '123 Test St',
    zipcode: '1000',
    nationalIdNumber: 'NAT123456',
    nationalIdFrontUrl: 'https://example.com/nat-front.jpg',
    nationalIdBackUrl: 'https://example.com/nat-back.jpg',
    secondaryGovIdType: 'drivers_license',
    secondaryGovIdNumber: 'DL123456',
    secondaryGovIdFrontUrl: 'https://example.com/dl-front.jpg',
    secondaryGovIdBackUrl: 'https://example.com/dl-back.jpg',
    proofOfAddressType: 'utility_bill',
    proofOfAddressUrl: 'https://example.com/proof.jpg',
    selfieWithIdUrl: 'https://example.com/selfie.jpg',
    acceptedTermsAt: DateTime.now(),
    acceptedPrivacyAt: DateTime.now(),
    status: 'pending',
    reviewedBy: null,
    reviewedAt: null,
    rejectionReason: null,
    adminNotes: null,
    submittedAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValue(testKycData);
  });

  group('SubmitKycRegistrationUseCase', () {
    test('should submit KYC registration successfully', () async {
      // Arrange
      when(
        () => mockRepository.submitKycRegistration(any()),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final result = await useCase(testKycData);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.submitKycRegistration(any())).called(1);
    });

    test(
      'should return AuthFailure when user already has pending KYC',
      () async {
        // Arrange
        when(() => mockRepository.submitKycRegistration(any())).thenAnswer(
          (_) async => Left(AuthFailure('KYC registration already exists')),
        );

        // Act
        final result = await useCase(testKycData);

        // Assert
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<AuthFailure>());
          expect(failure.message, 'KYC registration already exists');
        }, (_) => fail('Should return failure'));
      },
    );

    test('should return AuthFailure for invalid KYC data', () async {
      // Arrange
      when(
        () => mockRepository.submitKycRegistration(any()),
      ).thenAnswer((_) async => Left(AuthFailure('Invalid KYC data')));

      // Act
      final result = await useCase(testKycData);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<AuthFailure>());
        expect(failure.message, 'Invalid KYC data');
      }, (_) => fail('Should return failure'));
    });

    test('should return StorageFailure when file upload fails', () async {
      // Arrange
      when(() => mockRepository.submitKycRegistration(any())).thenAnswer(
        (_) async => Left(StorageFailure('Failed to upload KYC documents')),
      );

      // Act
      final result = await useCase(testKycData);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<StorageFailure>());
        expect(failure.message, contains('upload'));
      }, (_) => fail('Should return failure'));
    });

    test('should return NetworkFailure when network is unavailable', () async {
      // Arrange
      when(
        () => mockRepository.submitKycRegistration(any()),
      ).thenAnswer((_) async => Left(NetworkFailure('No internet connection')));

      // Act
      final result = await useCase(testKycData);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<NetworkFailure>());
        expect(failure.message, 'No internet connection');
      }, (_) => fail('Should return failure'));
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      when(
        () => mockRepository.submitKycRegistration(any()),
      ).thenAnswer((_) async => Left(ServerFailure('Server error')));

      // Act
      final result = await useCase(testKycData);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Server error');
      }, (_) => fail('Should return failure'));
    });
  });
}
