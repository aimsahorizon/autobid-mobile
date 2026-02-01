import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Stripe payment service for handling payments
/// Get your keys from: https://dashboard.stripe.com/test/apikeys
class StripeService {
  // Test mode credentials loaded from environment variables
  static final String _testPublishableKey =
      dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
  static final String _testSecretKey =
      dotenv.env['STRIPE_SECRET_KEY'] ?? '';

  static const String _baseUrl = 'https://api.stripe.com/v1';

  /// Initialize Stripe
  static Future<void> init() async {
    // Only initialize if publishable key is available
    if (_testPublishableKey.isEmpty) {
      debugPrint('Warning: Stripe publishable key not found in .env file. Skipping Stripe initialization.');
      return;
    }

    try {
      Stripe.publishableKey = _testPublishableKey;
      await Stripe.instance.applySettings();
    } catch (e) {
      debugPrint('Warning: Failed to initialize Stripe: $e');
    }
  }

  /// Create a PaymentIntent on the server
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    // Convert amount to smallest currency unit (cents for USD, centavos for PHP)
    final amountInCents = (amount * 100).toInt();

    final url = Uri.parse('$_baseUrl/payment_intents');
    final auth = base64Encode(utf8.encode('$_testSecretKey:'));

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Basic $auth',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'amount': amountInCents.toString(),
        'currency': currency.toLowerCase(),
        'description': description,
        'automatic_payment_methods[enabled]': 'true',
        if (metadata != null)
          ...metadata.map(
            (key, value) => MapEntry('metadata[$key]', value.toString()),
          ),
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw StripeServiceException(
        'Failed to create payment intent: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Process card payment
  Future<Map<String, dynamic>> processCardPayment({
    required String paymentIntentClientSecret,
    required BillingDetails billingDetails,
  }) async {
    try {
      // Confirm payment with card details
      final paymentIntent = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: paymentIntentClientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(billingDetails: billingDetails),
        ),
      );

      return {'status': 'succeeded', 'payment_intent_id': paymentIntent.id};
    } on StripeException catch (e) {
      throw StripeServiceException(e.error.message ?? 'Payment failed');
    } catch (e) {
      throw StripeServiceException('Payment failed: ${e.toString()}');
    }
  }

  /// Retrieve PaymentIntent status
  Future<Map<String, dynamic>> retrievePaymentIntent(
    String paymentIntentId,
  ) async {
    final url = Uri.parse('$_baseUrl/payment_intents/$paymentIntentId');
    final auth = base64Encode(utf8.encode('$_testSecretKey:'));

    final response = await http.get(
      url,
      headers: {'Authorization': 'Basic $auth'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw StripeServiceException(
        'Failed to retrieve payment intent: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Create a customer
  Future<Map<String, dynamic>> createCustomer({
    required String email,
    String? name,
    String? phone,
    Map<String, dynamic>? metadata,
  }) async {
    final url = Uri.parse('$_baseUrl/customers');
    final auth = base64Encode(utf8.encode('$_testSecretKey:'));

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Basic $auth',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'email': email,
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (metadata != null)
          ...metadata.map(
            (key, value) => MapEntry('metadata[$key]', value.toString()),
          ),
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw StripeServiceException(
        'Failed to create customer: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Get test card numbers
  static Map<String, String> get testCards => {
    'success': '4242424242424242',
    'requires_authentication': '4000002500003155',
    'declined': '4000000000000002',
    'insufficient_funds': '4000000000009995',
  };
}

/// Custom exception for Stripe service errors
class StripeServiceException implements Exception {
  final String message;

  StripeServiceException(this.message);

  @override
  String toString() => 'StripeServiceException: $message';
}
