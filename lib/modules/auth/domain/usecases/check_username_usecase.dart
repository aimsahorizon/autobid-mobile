import '../repositories/auth_repository.dart';

class CheckUsernameUseCase {
  final AuthRepository repository;

  CheckUsernameUseCase(this.repository);

  Future<bool> call(String username) async {
    return await repository.checkUsernameAvailable(username);
  }
}
