import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// PayMongo payment service for handling payments
/// Documentation: https://developers.paymongo.com/docs
/// Get your keys from: https://dashboard.paymongo.com/developers
class PayMongoService {
  // API credentials loaded from environment variables
  static final String _secretKey = dotenv.env['PAYMONGO_SECRET_KEY'] ?? '';
  static final String _publicKey = dotenv.env['PAYMONGO_PUBLIC_KEY'] ?? '';

  static const String _baseUrl = 'https://api.paymongo.com/v1';

  /// Initialize PayMongo
  static Future<void> init() async {
    // Only initialize if keys are available
    if (_secretKey.isEmpty) {
      print(
        'Warning: PayMongo secret key not found in .env file. Skipping PayMongo initialization.',
      );
      return;
    }

    if (_publicKey.isEmpty) {
      print(
        'Warning: PayMongo public key not found in .env file. Some features may not work.',
      );
    }

    print('PayMongo initialized successfully');
  }

  /// Get authorization header with base64 encoded secret key
  Map<String, String> get _authHeaders {
    final auth = base64Encode(utf8.encode('$_secretKey:'));
    return {'Authorization': 'Basic $auth', 'Content-Type': 'application/json'};
  }

  /// Get authorization header with base64 encoded public key
  /// Creating payment methods should ideally use the public key from the client
  Map<String, String> get _publicAuthHeaders {
    final key = _publicKey.isNotEmpty ? _publicKey : _secretKey;
    final auth = base64Encode(utf8.encode('$key:'));
    return {'Authorization': 'Basic $auth', 'Content-Type': 'application/json'};
  }

  /// Create a PaymentIntent for the purchase
  /// This is the first step in the payment flow
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    // Convert amount to centavos (PayMongo uses smallest currency unit)
    final amountInCentavos = (amount * 100).toInt();

    final url = Uri.parse('$_baseUrl/payment_intent'); // API v1 use /payment_intents or /payment_intent? 
    // Actually PayMongo v1 uses /payment_intents (plural). My previous code had it.
    // Wait, let's stick to plural if it was working.
    final intentsUrl = Uri.parse('$_baseUrl/payment_intents');

    final body = jsonEncode({
      'data': {
        'attributes': {
          'amount': amountInCentavos,
          'currency': 'PHP',
          'description': description,
          'statement_descriptor': 'AutoBid',
          'payment_method_allowed': ['card', 'gcash', 'paymaya', 'grab_pay'],
          'metadata': metadata ?? {},
        },
      },
    });

    final response = await http.post(intentsUrl, headers: _authHeaders, body: body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return responseData['data'] as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw PayMongoException(
        'Failed to create payment intent: ${error['errors']?[0]?['detail'] ?? response.body}',
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

    // Ensure card number contains ONLY digits and is trimmed
    final cleanCardNumber = cardNumber.replaceAll(RegExp(r'[^0-9]'), '').trim();

    final body = jsonEncode({
      'data': {
        'attributes': {
          'type': 'card',
          'details': {
            'card_number': cleanCardNumber,
            'exp_month': expMonth,
            'exp_year': expYear,
            'cvc': cvc.trim(),
          },
          'billing': {
            'name': billingName.trim(),
            'email': billingEmail.trim(),
            if (billingPhone != null) 'phone': billingPhone.trim(),
          },
        },
      },
    });

    // Use Public Key for creating payment methods
    final response = await http.post(url, headers: _publicAuthHeaders, body: body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return responseData['data'] as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw PayMongoException(
        'Failed to create payment method: ${error['errors']?[0]?['detail'] ?? response.body}',
      );
    }
  }

  /// Attach PaymentMethod to PaymentIntent
  Future<Map<String, dynamic>> attachPaymentMethod({
    required String paymentIntentId,
    required String paymentMethodId,
    String? clientKey,
  }) async {
    final url = Uri.parse('$_baseUrl/payment_intents/$paymentIntentId/attach');

    final body = jsonEncode({
      'data': {
        'attributes': {
          'payment_method': paymentMethodId,
          if (clientKey != null) 'client_key': clientKey,
        },
      },
    });

    final response = await http.post(url, headers: _authHeaders, body: body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return responseData['data'] as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw PayMongoException(
        'Failed to attach payment method: ${error['errors']?[0]?['detail'] ?? response.body}',
      );
    }
  }

  /// Retrieve PaymentIntent status
  Future<Map<String, dynamic>> retrievePaymentIntent(
    String paymentIntentId,
  ) async {
    final url = Uri.parse('$_baseUrl/payment_intents/$paymentIntentId');

    final response = await http.get(url, headers: _authHeaders);

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return responseData['data'] as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw PayMongoException(
        'Failed to retrieve payment intent: ${error['errors']?[0]?['detail'] ?? response.body}',
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

    final response = await http.post(url, headers: _authHeaders, body: body);

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

    final response = await http.get(url, headers: _authHeaders);

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

    final body = jsonEncode({
      'data': {
        'attributes': {
          'source': {'id': sourceId, 'type': 'source'},
          'description': description,
        },
      },
    });

    final response = await http.post(url, headers: _authHeaders, body: body);

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
enum PaymentMethodType { card, gcash, paymaya, grabPay }

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
enum PaymentStatus { awaiting, processing, succeeded, failed }
