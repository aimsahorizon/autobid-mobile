/// Interface for PayMongo service to allow switching between real and mock implementations
abstract class IPayMongoService {
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String description,
    Map<String, dynamic>? metadata,
  });

  Future<Map<String, dynamic>> createPaymentMethod({
    required String cardNumber,
    required int expMonth,
    required int expYear,
    required String cvc,
    required String billingName,
    required String billingEmail,
    String? billingPhone,
  });

  Future<Map<String, dynamic>> attachPaymentMethod({
    required String paymentIntentId,
    required String paymentMethodId,
    String? clientKey,
  });

  Future<Map<String, dynamic>> createSource({
    required double amount,
    required String type,
    required String redirectSuccessUrl,
    required String redirectFailedUrl,
    Map<String, dynamic>? metadata,
  });

  Future<Map<String, dynamic>> retrieveSource(String sourceId);

  Future<Map<String, dynamic>> createPayment({
    required String sourceId,
    required String description,
  });
}
