import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class SendMessageUseCase {
  final TransactionRepository repository;
  SendMessageUseCase(this.repository);
  Future<Either<Failure, bool>> call(String transactionId, String userId, String userName, String message) => 
    repository.sendMessage(transactionId, userId, userName, message);
}

class SubmitFormUseCase {
  final TransactionRepository repository;
  SubmitFormUseCase(this.repository);
  Future<Either<Failure, bool>> call(TransactionFormEntity form) => repository.submitForm(form);
}

class ConfirmFormUseCase {
  final TransactionRepository repository;
  ConfirmFormUseCase(this.repository);
  Future<Either<Failure, bool>> call(String transactionId, FormRole otherPartyRole) => 
    repository.confirmForm(transactionId, otherPartyRole);
}

class SubmitToAdminUseCase {
  final TransactionRepository repository;
  SubmitToAdminUseCase(this.repository);
  Future<Either<Failure, bool>> call(String transactionId) => repository.submitToAdmin(transactionId);
}

class UpdateDeliveryStatusUseCase {
  final TransactionRepository repository;
  UpdateDeliveryStatusUseCase(this.repository);
  Future<Either<Failure, bool>> call(String transactionId, String sellerId, DeliveryStatus status) => 
    repository.updateDeliveryStatus(transactionId, sellerId, status);
}

class AcceptVehicleUseCase {
  final TransactionRepository repository;
  AcceptVehicleUseCase(this.repository);
  Future<Either<Failure, bool>> call(String transactionId, String buyerId) => 
    repository.acceptVehicle(transactionId, buyerId);
}

class RejectVehicleUseCase {
  final TransactionRepository repository;
  RejectVehicleUseCase(this.repository);
  Future<Either<Failure, bool>> call(String transactionId, String buyerId, String reason) => 
    repository.rejectVehicle(transactionId, buyerId, reason);
}
