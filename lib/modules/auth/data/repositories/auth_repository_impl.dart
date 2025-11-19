import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserEntity?> getCurrentUser() {
    return remoteDataSource.getCurrentUser();
  }

  @override
  Future<UserEntity> signInWithUsername(String username, String password) {
    return remoteDataSource.signInWithUsername(username, password);
  }

  @override
  Future<UserEntity> signInWithGoogle() {
    return remoteDataSource.signInWithGoogle();
  }

  @override
  Future<void> signOut() {
    return remoteDataSource.signOut();
  }

  @override
  Future<void> sendPasswordResetRequest(String username) {
    return remoteDataSource.sendPasswordResetRequest(username);
  }

  @override
  Future<bool> verifyOtp(String username, String otp) {
    return remoteDataSource.verifyOtp(username, otp);
  }

  @override
  Future<UserEntity> signUp(String email, String password, {String? username}) {
    return remoteDataSource.signUp(email, password, username: username);
  }
}
