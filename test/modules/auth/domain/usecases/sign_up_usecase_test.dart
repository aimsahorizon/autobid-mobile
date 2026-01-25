import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/sign_up_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';
import 'package:autobid_mobile/modules/auth/domain/entities/user_entity.dart';
import 'package:autobid_mobile/core/error/failures.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignUpUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignUpUseCase(mockRepository);
  });

  const testEmail = 'test@example.com';
  const testPassword = 'Password123!';
  const testUsername = 'testuser';

  final testUser = UserEntity(
    id: '123',
    email: testEmail,
    username: testUsername,
  );

  group('SignUpUseCase', () {
    group('Successful sign up', () {
      test('should sign up successfully with username', () async {
        // Arrange
        when(
          () => mockRepository.signUp(
            testEmail,
            testPassword,
            username: testUsername,
          ),
        ).thenAnswer((_) async => Right(testUser));

        // Act
        final result = await useCase(
          email: testEmail,
          password: testPassword,
          username: testUsername,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold((failure) => fail('Should return user'), (user) {
          expect(user.id, testUser.id);
          expect(user.email, testUser.email);
          expect(user.username, testUser.username);
        });

        verify(
          () => mockRepository.signUp(
            testEmail,
            testPassword,
            username: testUsername,
          ),
        ).called(1);
      });

      test('should sign up successfully without username', () async {
        // Arrange
        when(
          () => mockRepository.signUp(testEmail, testPassword, username: null),
        ).thenAnswer((_) async => Right(testUser));

        // Act
        final result = await useCase(email: testEmail, password: testPassword);

        // Assert
        expect(result.isRight(), true);
        result.fold((failure) => fail('Should return user'), (user) {
          expect(user.id, testUser.id);
          expect(user.email, testUser.email);
        });

        verify(
          () => mockRepository.signUp(testEmail, testPassword, username: null),
        ).called(1);
      });
    });

    group('Failed sign up', () {
      test(
        'should return AuthFailure when email is already registered',
        () async {
          // Arrange
          when(
            () => mockRepository.signUp(
              testEmail,
              testPassword,
              username: testUsername,
            ),
          ).thenAnswer((_) async => Left(AuthFailure('Email already in use')));

          // Act
          final result = await useCase(
            email: testEmail,
            password: testPassword,
            username: testUsername,
          );

          // Assert
          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<AuthFailure>());
            expect(failure.message, 'Email already in use');
          }, (user) => fail('Should return failure'));
        },
      );

      test(
        'should return AuthFailure when username is already taken',
        () async {
          // Arrange
          when(
            () => mockRepository.signUp(
              testEmail,
              testPassword,
              username: testUsername,
            ),
          ).thenAnswer(
            (_) async => Left(AuthFailure('Username already taken')),
          );

          // Act
          final result = await useCase(
            email: testEmail,
            password: testPassword,
            username: testUsername,
          );

          // Assert
          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<AuthFailure>());
            expect(failure.message, 'Username already taken');
          }, (user) => fail('Should return failure'));
        },
      );

      test('should return AuthFailure when password is weak', () async {
        // Arrange
        when(
          () =>
              mockRepository.signUp(testEmail, 'weak', username: testUsername),
        ).thenAnswer((_) async => Left(AuthFailure('Password too weak')));

        // Act
        final result = await useCase(
          email: testEmail,
          password: 'weak',
          username: testUsername,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<AuthFailure>());
          expect(failure.message, 'Password too weak');
        }, (user) => fail('Should return failure'));
      });

      test(
        'should return NetworkFailure when network is unavailable',
        () async {
          // Arrange
          when(
            () => mockRepository.signUp(
              testEmail,
              testPassword,
              username: testUsername,
            ),
          ).thenAnswer(
            (_) async => Left(NetworkFailure('No internet connection')),
          );

          // Act
          final result = await useCase(
            email: testEmail,
            password: testPassword,
            username: testUsername,
          );

          // Assert
          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<NetworkFailure>());
            expect(failure.message, 'No internet connection');
          }, (user) => fail('Should return failure'));
        },
      );

      test('should return ServerFailure on server error', () async {
        // Arrange
        when(
          () => mockRepository.signUp(
            testEmail,
            testPassword,
            username: testUsername,
          ),
        ).thenAnswer((_) async => Left(ServerFailure('Server error')));

        // Act
        final result = await useCase(
          email: testEmail,
          password: testPassword,
          username: testUsername,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Server error');
        }, (user) => fail('Should return failure'));
      });
    });
  });
}
