import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> getCurrentUser();
  Future<UserEntity> signInWithUsername(String username, String password);
  Future<UserEntity> signInWithGoogle();
  Future<void> signOut();
  Future<void> sendPasswordResetRequest(String username);
  Future<bool> verifyOtp(String username, String otp);
  Future<UserEntity> signUp(String email, String password, {String? username});
}
