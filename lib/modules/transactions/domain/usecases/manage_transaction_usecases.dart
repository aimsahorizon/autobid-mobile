import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class SendMessageUseCase {
  final TransactionRepository repository;
  SendMessageUseCase(this.repository);
  Future<Either<Failure, bool>> call(
    String transactionId,
    String userId,
    String userName,
    String message,
  ) => repository.sendMessage(transactionId, userId, userName, message);
}

class SubmitFormUseCase {
  final TransactionRepository repository;
  SubmitFormUseCase(this.repository);
  Future<Either<Failure, bool>> call(TransactionFormEntity form) =>
      repository.submitForm(form);
}

class ConfirmFormUseCase {
  final TransactionRepository repository;
  ConfirmFormUseCase(this.repository);
  Future<Either<Failure, bool>> call(
    String transactionId,
    FormRole otherPartyRole,
  ) => repository.confirmForm(transactionId, otherPartyRole);
}

class SubmitToAdminUseCase {
  final TransactionRepository repository;
  SubmitToAdminUseCase(this.repository);
  Future<Either<Failure, bool>> call(String transactionId) =>
      repository.submitToAdmin(transactionId);
}

class UpdateDeliveryStatusUseCase {
  final TransactionRepository repository;
  UpdateDeliveryStatusUseCase(this.repository);
  Future<Either<Failure, bool>> call(
    String transactionId,
    String sellerId,
    DeliveryStatus status,
  ) => repository.updateDeliveryStatus(transactionId, sellerId, status);
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
  Future<Either<Failure, bool>> call(
    String transactionId,
    String buyerId,
    String reason,
  ) => repository.rejectVehicle(transactionId, buyerId, reason);
}

/// Retrieve the next eligible winner after a deal cancellation.
/// Excludes all bids from the cancelled buyer.
/// Returns null if no eligible next winner (e.g. only 1 unique bidder).
class GetNextEligibleWinnerUseCase {
  final TransactionRepository repository;
  GetNextEligibleWinnerUseCase(this.repository);
  Future<Either<Failure, Map<String, dynamic>?>> call(String transactionId) =>
      repository.getNextEligibleWinner(transactionId);
}

/// Count unique eligible bidders that could be the next winner.
class CountEligibleNextBiddersUseCase {
  final TransactionRepository repository;
  CountEligibleNextBiddersUseCase(this.repository);
  Future<Either<Failure, int>> call(String transactionId) =>
      repository.countEligibleNextBidders(transactionId);
}

/// Cancel the auction with a penalty record for the cancelling party.
class CancelAuctionWithPenaltyUseCase {
  final TransactionRepository repository;
  CancelAuctionWithPenaltyUseCase(this.repository);
  Future<Either<Failure, bool>> call(String transactionId, String reason) =>
      repository.cancelAuctionWithPenalty(transactionId, reason);
}

/// Automatically reselect the next highest bidder after a deal fails.
class AutoReselectNextWinnerUseCase {
  final TransactionRepository repository;
  AutoReselectNextWinnerUseCase(this.repository);
  Future<Either<Failure, bool>> call(String transactionId) =>
      repository.autoReselectNextWinner(transactionId);
}

/// Restart the auction bidding from scratch.
class RestartAuctionBiddingUseCase {
  final TransactionRepository repository;
  RestartAuctionBiddingUseCase(this.repository);
  Future<Either<Failure, bool>> call(String transactionId) =>
      repository.restartAuctionBidding(transactionId);
}
