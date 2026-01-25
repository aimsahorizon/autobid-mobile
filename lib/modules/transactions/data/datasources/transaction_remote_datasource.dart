import '../../domain/entities/transaction_entity.dart';

abstract class TransactionRemoteDataSource {
  Future<TransactionEntity?> getTransaction(String transactionId);
  Future<List<ChatMessageEntity>> getChatMessages(String transactionId);
  Future<TransactionFormEntity?> getTransactionForm(String transactionId, FormRole role);
  Future<List<TransactionTimelineEntity>> getTimeline(String transactionId);
  
  Future<bool> sendMessage(String transactionId, String userId, String userName, String message);
  Future<bool> submitForm(TransactionFormEntity form);
  Future<bool> confirmForm(String transactionId, FormRole otherPartyRole);
  Future<bool> submitToAdmin(String transactionId);
  Future<bool> updateDeliveryStatus(String transactionId, String sellerId, DeliveryStatus status);
  Future<bool> acceptVehicle(String transactionId, String buyerId);
  Future<bool> rejectVehicle(String transactionId, String buyerId, String reason);
}
