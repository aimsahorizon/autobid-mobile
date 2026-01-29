import 'paymongo_service.dart';

/// Mock PayMongo service for demo/testing without API keys
/// Simulates successful payments after a short delay
class PayMongoMockService extends PayMongoService {
  static const _mockDelay = Duration(seconds: 2);

  @override
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    await Future.delayed(_mockDelay);

    // Return mock payment intent
    return {
      'id': 'pi_mock_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'payment_intent',
      'attributes': {
        'amount': (amount * 100).toInt(),
        'currency': 'PHP',
        'description': description,
        'status': 'awaiting_payment_method',
        'client_key': 'mock_client_key_${DateTime.now().millisecondsSinceEpoch}',
        'metadata': metadata ?? {},
      },
    };
  }

  @override
  Future<Map<String, dynamic>> createPaymentMethod({
    required String cardNumber,
    required int expMonth,
    required int expYear,
    required String cvc,
    required String billingName,
    required String billingEmail,
    String? billingPhone,
  }) async {
    await Future.delayed(_mockDelay);

    // Return mock payment method
    return {
      'id': 'pm_mock_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'payment_method',
      'attributes': {
        'type': 'card',
        'billing': {
          'name': billingName,
          'email': billingEmail,
          'phone': billingPhone,
        },
        'details': {
          'last4': cardNumber.length >= 4 
              ? cardNumber.substring(cardNumber.length - 4) 
              : cardNumber,
          'exp_month': expMonth,
          'exp_year': expYear,
        },
      },
    };
  }

  @override
  Future<Map<String, dynamic>> attachPaymentMethod({
    required String paymentIntentId,
    required String paymentMethodId,
    String? clientKey,
  }) async {
    await Future.delayed(_mockDelay);

    // Simulate successful payment
    return {
      'id': paymentIntentId,
      'type': 'payment_intent',
      'attributes': {
        'status': 'succeeded',
        'amount': 10000, // Mock amount
        'currency': 'PHP',
        'payment_method': paymentMethodId,
        'paid_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> createSource({
    required double amount,
    required String type,
    required String redirectSuccessUrl,
    required String redirectFailedUrl,
    Map<String, dynamic>? metadata,
  }) async {
    await Future.delayed(_mockDelay);

    // Return mock source with checkout URL
    return {
      'id': 'src_mock_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'source',
      'attributes': {
        'amount': (amount * 100).toInt(),
        'currency': 'PHP',
        'type': type,
        'status': 'pending',
        'redirect': {
          'checkout_url': 'https://mock-checkout.paymongo.com/sources/mock_${DateTime.now().millisecondsSinceEpoch}',
          'success': redirectSuccessUrl,
          'failed': redirectFailedUrl,
        },
        'metadata': metadata ?? {},
      },
    };
  }

  @override
  Future<Map<String, dynamic>> retrieveSource(String sourceId) async {
    await Future.delayed(_mockDelay);

    // Return mock source with chargeable status
    return {
      'id': sourceId,
      'type': 'source',
      'attributes': {
        'status': 'chargeable',
        'amount': 10000,
        'currency': 'PHP',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> createPayment({
    required String sourceId,
    required String description,
  }) async {
    await Future.delayed(_mockDelay);

    // Simulate successful payment
    return {
      'id': 'pay_mock_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'payment',
      'attributes': {
        'status': 'paid',
        'amount': 10000,
        'currency': 'PHP',
        'source': {
          'id': sourceId,
          'type': 'source',
        },
        'paid_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> retrievePaymentIntent(String paymentIntentId) async {
    await Future.delayed(_mockDelay);

    return {
      'id': paymentIntentId,
      'type': 'payment_intent',
      'attributes': {
        'status': 'succeeded',
        'amount': 10000,
        'currency': 'PHP',
      },
    };
  }
}
