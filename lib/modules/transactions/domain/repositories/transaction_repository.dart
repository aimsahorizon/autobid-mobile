import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import '../entities/transaction_entity.dart';

abstract class TransactionRepository {
  Future<Either<Failure, TransactionEntity?>> getTransaction(String transactionId);
  Future<Either<Failure, List<ChatMessageEntity>>> getChatMessages(String transactionId);
  Future<Either<Failure, TransactionFormEntity?>> getTransactionForm(String transactionId, FormRole role);
  Future<Either<Failure, List<TransactionTimelineEntity>>> getTimeline(String transactionId);
  
  Future<Either<Failure, bool>> sendMessage(String transactionId, String userId, String userName, String message);
  Future<Either<Failure, bool>> submitForm(TransactionFormEntity form);
  Future<Either<Failure, bool>> confirmForm(String transactionId, FormRole otherPartyRole);
  Future<Either<Failure, bool>> submitToAdmin(String transactionId);
  Future<Either<Failure, bool>> updateDeliveryStatus(String transactionId, String sellerId, DeliveryStatus status);
  Future<Either<Failure, bool>> acceptVehicle(String transactionId, String buyerId);
  Future<Either<Failure, bool>> rejectVehicle(String transactionId, String buyerId, String reason);
}
