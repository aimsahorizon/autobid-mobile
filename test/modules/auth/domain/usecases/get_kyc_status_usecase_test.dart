import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/get_kyc_status_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';
import 'package:autobid_mobile/modules/auth/domain/entities/kyc_registration_entity.dart';
import 'package:autobid_mobile/core/error/failures.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late GetKycRegistrationStatusUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = GetKycRegistrationStatusUseCase(mockRepository);
  });

  const testUserId = 'user-123';

  final testKycEntity = KycRegistrationEntity(
    id: testUserId,
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

  group('GetKycRegistrationStatusUseCase', () {
    test('should return KYC registration when user has submitted', () async {
      // Arrange
      when(
        () => mockRepository.getKycRegistrationStatus(testUserId),
      ).thenAnswer((_) async => Right(testKycEntity));

      // Act
      final result = await useCase(testUserId);

      // Assert
      expect(result.isRight(), true);
      result.fold((failure) => fail('Should return KYC entity'), (kycEntity) {
        expect(kycEntity, isNotNull);
        expect(kycEntity!.id, testUserId);
        expect(kycEntity.status, 'pending');
      });

      verify(
        () => mockRepository.getKycRegistrationStatus(testUserId),
      ).called(1);
    });

    test('should return null when user has not submitted KYC', () async {
      // Arrange
      when(
        () => mockRepository.getKycRegistrationStatus(testUserId),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final result = await useCase(testUserId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return null'),
        (kycEntity) => expect(kycEntity, isNull),
      );
    });

    test('should return NotFoundFailure when user does not exist', () async {
      // Arrange
      when(
        () => mockRepository.getKycRegistrationStatus(testUserId),
      ).thenAnswer((_) async => Left(NotFoundFailure('User not found')));

      // Act
      final result = await useCase(testUserId);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<NotFoundFailure>());
        expect(failure.message, 'User not found');
      }, (_) => fail('Should return failure'));
    });

    test('should return NetworkFailure when network is unavailable', () async {
      // Arrange
      when(
        () => mockRepository.getKycRegistrationStatus(testUserId),
      ).thenAnswer((_) async => Left(NetworkFailure('No internet connection')));

      // Act
      final result = await useCase(testUserId);

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
        () => mockRepository.getKycRegistrationStatus(testUserId),
      ).thenAnswer((_) async => Left(ServerFailure('Server error')));

      // Act
      final result = await useCase(testUserId);

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Server error');
      }, (_) => fail('Should return failure'));
    });
  });
}
