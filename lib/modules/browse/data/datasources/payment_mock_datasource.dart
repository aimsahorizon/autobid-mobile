import '../../domain/entities/payment_entity.dart';

/// Mock data source for payment operations
/// In production, this will be replaced with PayMongo API calls
/// TODO: Replace with PayMongoDataSource for production
class PaymentMockDataSource {
  // Toggle to switch between mock and real API
  // Set to false when PayMongo sandbox is configured
  static const bool useMockData = true;

  // Simulated delay to mimic network requests
  static const _mockDelay = Duration(milliseconds: 1500);

  // In-memory storage for mock payments
  // In production, payments are stored in PayMongo
  final Map<String, PaymentEntity> _payments = {};

  /// Creates a new payment intent for deposit
  /// Returns payment entity with checkout URL for redirect flow
  ///
  /// In production with PayMongo:
  /// 1. Create a PaymentIntent with amount and description
  /// 2. Attach payment method (gcash/maya/card)
  /// 3. Return checkout_url for user to complete payment
  Future<PaymentEntity> createPayment({
    required String auctionId,
    required double amount,
    required PaymentMethod method,
  }) async {
    await Future.delayed(_mockDelay);

    // Generate mock payment ID (PayMongo uses pi_ prefix)
    final paymentId = 'pi_mock_${DateTime.now().millisecondsSinceEpoch}';

    // Create payment entity in pending state
    final payment = PaymentEntity(
      id: paymentId,
      auctionId: auctionId,
      amount: amount,
      method: method,
      status: PaymentStatus.pending,
      createdAt: DateTime.now(),
      // Mock checkout URL - in production this comes from PayMongo
      checkoutUrl: 'https://checkout.paymongo.com/mock/$paymentId',
    );

    _payments[paymentId] = payment;
    return payment;
  }

  /// Simulates completing a payment (for demo/mock purposes)
  /// In production, PayMongo webhooks handle payment completion
  ///
  /// Production flow:
  /// 1. User completes payment on PayMongo checkout page
  /// 2. PayMongo sends webhook to your backend
  /// 3. Backend updates payment status and auction deposit status
  Future<PaymentEntity> completePayment(String paymentId) async {
    await Future.delayed(_mockDelay);

    final existing = _payments[paymentId];
    if (existing == null) {
      throw Exception('Payment not found');
    }

    // Update payment to success status
    final completed = PaymentEntity(
      id: existing.id,
      auctionId: existing.auctionId,
      amount: existing.amount,
      method: existing.method,
      status: PaymentStatus.success,
      createdAt: existing.createdAt,
      completedAt: DateTime.now(),
    );

    _payments[paymentId] = completed;
    return completed;
  }

  /// Gets payment status by ID
  /// Used to poll for payment completion if webhooks aren't available
  Future<PaymentEntity?> getPaymentStatus(String paymentId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _payments[paymentId];
  }

  /// Cancels a pending payment
  /// In production, this expires the PayMongo payment intent
  Future<bool> cancelPayment(String paymentId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final existing = _payments[paymentId];
    if (existing == null || !existing.isPending) {
      return false;
    }

    _payments[paymentId] = PaymentEntity(
      id: existing.id,
      auctionId: existing.auctionId,
      amount: existing.amount,
      method: existing.method,
      status: PaymentStatus.cancelled,
      createdAt: existing.createdAt,
    );

    return true;
  }
}

/// PayMongo API configuration
/// TODO: Move to environment config for security
class PayMongoConfig {
  // Sandbox keys for testing - replace with live keys in production
  static const String publicKey = 'pk_test_YOUR_PUBLIC_KEY';
  static const String secretKey = 'sk_test_YOUR_SECRET_KEY';

  // API endpoints
  static const String baseUrl = 'https://api.paymongo.com/v1';
  static const String paymentIntentsUrl = '$baseUrl/payment_intents';
  static const String paymentMethodsUrl = '$baseUrl/payment_methods';
  static const String sourcesUrl = '$baseUrl/sources';

  // Webhook endpoint (configure in PayMongo dashboard)
  static const String webhookEndpoint = 'YOUR_BACKEND_URL/api/paymongo/webhook';
}
