import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class GetTransactionUseCase {
  final TransactionRepository repository;
  GetTransactionUseCase(this.repository);
  Future<Either<Failure, TransactionEntity?>> call(String transactionId) => repository.getTransaction(transactionId);
}

class GetChatMessagesUseCase {
  final TransactionRepository repository;
  GetChatMessagesUseCase(this.repository);
  Future<Either<Failure, List<ChatMessageEntity>>> call(String transactionId) => repository.getChatMessages(transactionId);
}

class GetTransactionFormUseCase {
  final TransactionRepository repository;
  GetTransactionFormUseCase(this.repository);
  Future<Either<Failure, TransactionFormEntity?>> call(String transactionId, FormRole role) => repository.getTransactionForm(transactionId, role);
}

class GetTimelineUseCase {
  final TransactionRepository repository;
  GetTimelineUseCase(this.repository);
  Future<Either<Failure, List<TransactionTimelineEntity>>> call(String transactionId) => repository.getTimeline(transactionId);
}
