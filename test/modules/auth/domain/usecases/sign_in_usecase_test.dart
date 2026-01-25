import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/sign_in_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';
import 'package:autobid_mobile/modules/auth/domain/entities/user_entity.dart';
import 'package:autobid_mobile/core/error/failures.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignInUseCase useCase;
  late MockAuthRepository mockRepository;

  const testUsername = 'testuser';
  const testPassword = 'password123';
  const testUser = UserEntity(
    id: 'user-123',
    email: 'test@example.com',
    username: testUsername,
  );

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignInUseCase(mockRepository);
  });

  group('SignInUseCase', () {
    test('should return UserEntity when sign in is successful', () async {
      // Arrange
      when(
        () => mockRepository.signInWithUsername(any(), any()),
      ).thenAnswer((_) async => const Right(testUser));

      // Act
      final result = await useCase(testUsername, testPassword);

      // Assert
      expect(result, equals(const Right(testUser)));
      verify(
        () => mockRepository.signInWithUsername(testUsername, testPassword),
      ).called(1);
    });

    test('should return AuthFailure when credentials are invalid', () async {
      // Arrange
      const failure = AuthFailure('Invalid username or password');
      when(
        () => mockRepository.signInWithUsername(any(), any()),
      ).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(testUsername, testPassword);

      // Assert
      expect(result, equals(const Left(failure)));
      verify(
        () => mockRepository.signInWithUsername(testUsername, testPassword),
      ).called(1);
    });

    test('should return NetworkFailure when network error occurs', () async {
      // Arrange
      const failure = NetworkFailure('No internet connection');
      when(
        () => mockRepository.signInWithUsername(any(), any()),
      ).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(testUsername, testPassword);

      // Assert
      expect(result, equals(const Left(failure)));
    });

    test('should return ServerFailure when server error occurs', () async {
      // Arrange
      const failure = ServerFailure('Server error occurred');
      when(
        () => mockRepository.signInWithUsername(any(), any()),
      ).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(testUsername, testPassword);

      // Assert
      expect(result, equals(const Left(failure)));
    });
  });
}
