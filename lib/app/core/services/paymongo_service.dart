import 'dart:convert';
import 'package:http/http.dart' as http;

/// PayMongo payment service for handling payments
/// Documentation: https://developers.paymongo.com/docs
class PayMongoService {
  // Sandbox credentials (test mode)
  // Get your keys from: https://dashboard.paymongo.com/developers
  static const String _sandboxPublicKey =
      'pk_test_YOUR_PUBLIC_KEY_HERE'; // Replace with your test public key
  static const String _sandboxSecretKey =
      'sk_test_YOUR_SECRET_KEY_HERE'; // Replace with your test secret key

  static const String _baseUrl = 'https://api.paymongo.com/v1';

  /// Create a PaymentIntent for the purchase
  /// This is the first step in the payment flow
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    // Convert amount to centavos (PayMongo uses smallest currency unit)
    final amountInCentavos = (amount * 100).toInt();

    final url = Uri.parse('$_baseUrl/payment_intents');
    final auth = base64Encode(utf8.encode('$_sandboxSecretKey:'));

    final body = jsonEncode({
      'data': {
        'attributes': {
          'amount': amountInCentavos,
          'currency': 'PHP',
          'description': description,
          'statement_descriptor': 'AutoBid Tokens',
          'payment_method_allowed': [
            'card',
            'gcash',
            'paymaya',
            'grab_pay',
          ],
          'metadata': metadata ?? {},
        },
      },
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Basic $auth',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw PayMongoException(
        'Failed to create payment intent: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Create a PaymentMethod from card details
  Future<Map<String, dynamic>> createPaymentMethod({
    required String cardNumber,
    required int expMonth,
    required int expYear,
    required String cvc,
    required String billingName,
    required String billingEmail,
    String? billingPhone,
  }) async {
    final url = Uri.parse('$_baseUrl/payment_methods');
    final auth = base64Encode(utf8.encode('$_sandboxPublicKey:'));

    final body = jsonEncode({
      'data': {
        'attributes': {
          'type': 'card',
          'details': {
            'card_number': cardNumber,
            'exp_month': expMonth,
            'exp_year': expYear,
            'cvc': cvc,
          },
          'billing': {
            'name': billingName,
            'email': billingEmail,
            'phone': billingPhone,
          },
        },
      },
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Basic $auth',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw PayMongoException(
        'Failed to create payment method: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Attach PaymentMethod to PaymentIntent
  Future<Map<String, dynamic>> attachPaymentMethod({
    required String paymentIntentId,
    required String paymentMethodId,
    String? clientKey,
  }) async {
    final url =
        Uri.parse('$_baseUrl/payment_intents/$paymentIntentId/attach');

    // Use public key if client key is provided, otherwise use secret key
    final key = clientKey != null ? _sandboxPublicKey : _sandboxSecretKey;
    final auth = base64Encode(utf8.encode('$key:'));

    final body = jsonEncode({
      'data': {
        'attributes': {
          'payment_method': paymentMethodId,
          if (clientKey != null) 'client_key': clientKey,
        },
      },
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Basic $auth',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw PayMongoException(
        'Failed to attach payment method: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Retrieve PaymentIntent status
  Future<Map<String, dynamic>> retrievePaymentIntent(
      String paymentIntentId) async {
    final url = Uri.parse('$_baseUrl/payment_intents/$paymentIntentId');
    final auth = base64Encode(utf8.encode('$_sandboxSecretKey:'));

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Basic $auth',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw PayMongoException(
        'Failed to retrieve payment intent: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Create a Source for e-wallet payments (GCash, PayMaya, GrabPay)
  Future<Map<String, dynamic>> createSource({
    required double amount,
    required String type, // 'gcash', 'paymaya', 'grab_pay'
    required String redirectSuccessUrl,
    required String redirectFailedUrl,
    Map<String, dynamic>? metadata,
  }) async {
    final amountInCentavos = (amount * 100).toInt();
    final url = Uri.parse('$_baseUrl/sources');
    final auth = base64Encode(utf8.encode('$_sandboxPublicKey:'));

    final body = jsonEncode({
      'data': {
        'attributes': {
          'amount': amountInCentavos,
          'currency': 'PHP',
          'type': type,
          'redirect': {
            'success': redirectSuccessUrl,
            'failed': redirectFailedUrl,
          },
          'metadata': metadata ?? {},
        },
      },
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Basic $auth',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw PayMongoException(
        'Failed to create source: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Retrieve Source (for checking e-wallet payment status)
  Future<Map<String, dynamic>> retrieveSource(String sourceId) async {
    final url = Uri.parse('$_baseUrl/sources/$sourceId');
    final auth = base64Encode(utf8.encode('$_sandboxSecretKey:'));

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Basic $auth',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw PayMongoException(
        'Failed to retrieve source: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Create a Payment from a Source (after successful redirect)
  Future<Map<String, dynamic>> createPayment({
    required String sourceId,
    required String description,
  }) async {
    final url = Uri.parse('$_baseUrl/payments');
    final auth = base64Encode(utf8.encode('$_sandboxSecretKey:'));

    final body = jsonEncode({
      'data': {
        'attributes': {
          'source': {
            'id': sourceId,
            'type': 'source',
          },
          'description': description,
        },
      },
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Basic $auth',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw PayMongoException(
        'Failed to create payment: ${response.statusCode} - ${response.body}',
      );
    }
  }
}

/// Custom exception for PayMongo errors
class PayMongoException implements Exception {
  final String message;

  PayMongoException(this.message);

  @override
  String toString() => 'PayMongoException: $message';
}

/// Payment method types
enum PaymentMethodType {
  card,
  gcash,
  paymaya,
  grabPay,
}

extension PaymentMethodTypeExtension on PaymentMethodType {
  String get value {
    switch (this) {
      case PaymentMethodType.card:
        return 'card';
      case PaymentMethodType.gcash:
        return 'gcash';
      case PaymentMethodType.paymaya:
        return 'paymaya';
      case PaymentMethodType.grabPay:
        return 'grab_pay';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentMethodType.card:
        return 'Credit/Debit Card';
      case PaymentMethodType.gcash:
        return 'GCash';
      case PaymentMethodType.paymaya:
        return 'PayMaya';
      case PaymentMethodType.grabPay:
        return 'GrabPay';
    }
  }
}

/// Payment status
enum PaymentStatus {
  awaiting,
  processing,
  succeeded,
  failed,
}
