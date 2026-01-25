import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/modules/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';
import 'package:autobid_mobile/modules/auth/domain/entities/user_entity.dart';
import 'package:autobid_mobile/core/error/failures.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignInWithGoogleUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignInWithGoogleUseCase(mockRepository);
  });

  final testUser = UserEntity(
    id: '123',
    email: 'test@gmail.com',
    username: 'testuser',
  );

  group('SignInWithGoogleUseCase', () {
    test('should sign in with Google successfully', () async {
      // Arrange
      when(
        () => mockRepository.signInWithGoogle(),
      ).thenAnswer((_) async => Right(testUser));

      // Act
      final result = await useCase();

      // Assert
      expect(result.isRight(), true);
      result.fold((failure) => fail('Should return user'), (user) {
        expect(user.id, testUser.id);
        expect(user.email, testUser.email);
        expect(user.username, testUser.username);
      });

      verify(() => mockRepository.signInWithGoogle()).called(1);
    });

    test(
      'should return AuthFailure when Google sign in is cancelled',
      () async {
        // Arrange
        when(() => mockRepository.signInWithGoogle()).thenAnswer(
          (_) async => Left(AuthFailure('Google sign in cancelled')),
        );

        // Act
        final result = await useCase();

        // Assert
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<AuthFailure>());
          expect(failure.message, 'Google sign in cancelled');
        }, (_) => fail('Should return failure'));
      },
    );

    test(
      'should return AuthFailure when Google account is not found',
      () async {
        // Arrange
        when(
          () => mockRepository.signInWithGoogle(),
        ).thenAnswer((_) async => Left(AuthFailure('No Google account found')));

        // Act
        final result = await useCase();

        // Assert
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<AuthFailure>());
          expect(failure.message, 'No Google account found');
        }, (_) => fail('Should return failure'));
      },
    );

    test('should return AuthFailure when account is disabled', () async {
      // Arrange
      when(
        () => mockRepository.signInWithGoogle(),
      ).thenAnswer((_) async => Left(AuthFailure('Account has been disabled')));

      // Act
      final result = await useCase();

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<AuthFailure>());
        expect(failure.message, 'Account has been disabled');
      }, (_) => fail('Should return failure'));
    });

    test('should return NetworkFailure when network is unavailable', () async {
      // Arrange
      when(
        () => mockRepository.signInWithGoogle(),
      ).thenAnswer((_) async => Left(NetworkFailure('No internet connection')));

      // Act
      final result = await useCase();

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
        () => mockRepository.signInWithGoogle(),
      ).thenAnswer((_) async => Left(ServerFailure('Server error')));

      // Act
      final result = await useCase();

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Server error');
      }, (_) => fail('Should return failure'));
    });
  });
}
