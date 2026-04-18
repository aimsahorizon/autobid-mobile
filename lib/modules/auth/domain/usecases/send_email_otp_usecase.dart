import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';

class SendEmailOtpUseCase {
  final AuthRepository repository;

  SendEmailOtpUseCase(this.repository);

  Future<Either<Failure, void>> call(String email) {
    return repository.sendEmailOtp(email);
  }
}