import 'dart:async';
import 'ipaymongo_service.dart';

/// Mock PayMongo payment service for testing flows without hitting the API
class PayMongoMockService implements IPayMongoService {
  bool _useSuccess = true;
  
  /// Set whether to return success or failure responses
  void setSuccessMode(bool success) {
    _useSuccess = success;
  }

  /// Create a PaymentIntent (Mock)
  @override
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    
    if (!_useSuccess) {
      throw Exception('Mock Error: Failed to create payment intent');
    }

    return {
      'id': 'pi_mock_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'payment_intent',
      'attributes': {
        'amount': (amount * 100).toInt(),
        'currency': 'PHP',
        'status': 'awaiting_payment_method',
        'client_key': 'pi_mock_client_key',
        'metadata': metadata ?? {},
      }
    };
  }

  /// Create a PaymentMethod (Mock)
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
    await Future.delayed(const Duration(seconds: 1));

    if (!_useSuccess) {
      throw Exception('Mock Error: Invalid card details');
    }

    return {
      'id': 'pm_mock_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'payment_method',
      'attributes': {
        'type': 'card',
        'details': {
          'last4': cardNumber.substring(cardNumber.length - 4),
          'exp_month': expMonth,
          'exp_year': expYear,
        },
        'billing': {
          'name': billingName,
          'email': billingEmail,
        }
      }
    };
  }

  /// Attach PaymentMethod to PaymentIntent (Mock)
  @override
  Future<Map<String, dynamic>> attachPaymentMethod({
    required String paymentIntentId,
    required String paymentMethodId,
    String? clientKey,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    if (!_useSuccess) {
      throw Exception('Mock Error: Payment declined by bank');
    }

    return {
      'id': paymentIntentId,
      'type': 'payment_intent',
      'attributes': {
        'status': 'succeeded',
        'metadata': {},
      }
    };
  }

  /// Create a Source (Mock)
  @override
  Future<Map<String, dynamic>> createSource({
    required double amount,
    required String type,
    required String redirectSuccessUrl,
    required String redirectFailedUrl,
    Map<String, dynamic>? metadata,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    if (!_useSuccess) {
      throw Exception('Mock Error: Provider unavailable');
    }

    return {
      'data': {
        'id': 'src_mock_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'source',
        'attributes': {
          'amount': (amount * 100).toInt(),
          'currency': 'PHP',
          'type': type,
          'status': 'pending',
          'redirect': {
            'checkout_url': 'https://mock.paymongo.com/checkout/mock_source_id',
          },
          'metadata': metadata ?? {},
        }
      }
    };
  }

  /// Retrieve Source (Mock)
  @override
  Future<Map<String, dynamic>> retrieveSource(String sourceId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return {
      'data': {
        'id': sourceId,
        'type': 'source',
        'attributes': {
          'status': 'chargeable',
        }
      }
    };
  }

  /// Create a Payment (Mock)
  @override
  Future<Map<String, dynamic>> createPayment({
    required String sourceId,
    required String description,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    return {
      'data': {
        'id': 'pay_mock_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'payment',
        'attributes': {
          'status': 'succeeded',
          'amount': 100000,
          'currency': 'PHP',
        }
      }
    };
  }
}
