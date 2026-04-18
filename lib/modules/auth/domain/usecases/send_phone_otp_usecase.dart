import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';

class SendPhoneOtpUseCase {
  final AuthRepository repository;

  SendPhoneOtpUseCase(this.repository);

  Future<Either<Failure, void>> call(String phoneNumber) {
    return repository.sendPhoneOtp(phoneNumber);
  }
}