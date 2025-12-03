import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case for user registration
/// Handles sign up with email/password and optional username
class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  /// Call sign up use case
  /// Returns UserEntity on successful registration
  Future<UserEntity> call({
    required String email,
    required String password,
    String? username,
  }) {
    return repository.signUp(email, password, username: username);
  }
}
