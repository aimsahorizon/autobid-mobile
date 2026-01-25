import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_remote_datasource.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource remoteDataSource;

  TransactionRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, TransactionEntity?>> getTransaction(String transactionId) async {
    try {
      final result = await remoteDataSource.getTransaction(transactionId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessageEntity>>> getChatMessages(String transactionId) async {
    try {
      final result = await remoteDataSource.getChatMessages(transactionId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TransactionFormEntity?>> getTransactionForm(String transactionId, FormRole role) async {
    try {
      final result = await remoteDataSource.getTransactionForm(transactionId, role);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TransactionTimelineEntity>>> getTimeline(String transactionId) async {
    try {
      final result = await remoteDataSource.getTimeline(transactionId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> sendMessage(String transactionId, String userId, String userName, String message) async {
    try {
      final result = await remoteDataSource.sendMessage(transactionId, userId, userName, message);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> submitForm(TransactionFormEntity form) async {
    try {
      final result = await remoteDataSource.submitForm(form);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> confirmForm(String transactionId, FormRole otherPartyRole) async {
    try {
      final result = await remoteDataSource.confirmForm(transactionId, otherPartyRole);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> submitToAdmin(String transactionId) async {
    try {
      final result = await remoteDataSource.submitToAdmin(transactionId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> updateDeliveryStatus(String transactionId, String sellerId, DeliveryStatus status) async {
    try {
      final result = await remoteDataSource.updateDeliveryStatus(transactionId, sellerId, status);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> acceptVehicle(String transactionId, String buyerId) async {
    try {
      final result = await remoteDataSource.acceptVehicle(transactionId, buyerId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> rejectVehicle(String transactionId, String buyerId, String reason) async {
    try {
      final result = await remoteDataSource.rejectVehicle(transactionId, buyerId, reason);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
