import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel?> getCurrentUser();
  Future<UserModel> signInWithUsername(String username, String password);
  Future<UserModel> signInWithGoogle();
  Future<void> signOut();
  Future<void> sendPasswordResetRequest(String username);
  Future<bool> verifyOtp(String username, String otp);
  Future<UserModel> signUp(String email, String password, {String? username});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  // TODO: Inject Supabase client when ready

  @override
  Future<UserModel?> getCurrentUser() async {
    // TODO: Implement with Supabase
    await Future.delayed(const Duration(milliseconds: 500));
    return null;
  }

  @override
  Future<UserModel> signInWithUsername(String username, String password) async {
    // TODO: Implement with Supabase
    await Future.delayed(const Duration(seconds: 1));
    return UserModel(
      id: '1',
      email: '$username@autobid.com',
      username: username,
    );
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    // TODO: Implement with Supabase + Google Sign In
    await Future.delayed(const Duration(seconds: 1));
    return const UserModel(
      id: '1',
      email: 'user@example.com',
      displayName: 'User Name',
    );
  }

  @override
  Future<void> signOut() async {
    // TODO: Implement with Supabase
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> sendPasswordResetRequest(String username) async {
    // TODO: Implement with Supabase
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<bool> verifyOtp(String username, String otp) async {
    // TODO: Implement with Supabase
    await Future.delayed(const Duration(seconds: 1));
    return otp == '123456'; // Mock validation
  }

  @override
  Future<UserModel> signUp(String email, String password, {String? username}) async {
    // TODO: Implement with Supabase
    await Future.delayed(const Duration(seconds: 1));
    return UserModel(
      id: '1',
      email: email,
      username: username,
    );
  }
}
