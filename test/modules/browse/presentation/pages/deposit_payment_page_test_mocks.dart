import 'package:mockito/mockito.dart';
import 'package:autobid_mobile/core/services/ipaymongo_service.dart';
import 'package:autobid_mobile/modules/browse/data/datasources/deposit_supabase_datasource.dart';

class MockIPayMongoService extends Mock implements IPayMongoService {
  @override
  Future<Map<String, dynamic>> createPaymentIntent({
    required double? amount,
    required String? description,
    Map<String, dynamic>? metadata,
  }) {
    return super.noSuchMethod(
      Invocation.method(#createPaymentIntent, [], {
        #amount: amount,
        #description: description,
        #metadata: metadata,
      }),
      returnValue: Future.value({'id': 'pi_mock'}),
    );
  }

  @override
  Future<Map<String, dynamic>> createPaymentMethod({
    required String? cardNumber,
    required int? expMonth,
    required int? expYear,
    required String? cvc,
    required String? billingName,
    required String? billingEmail,
    String? billingPhone,
  }) {
    return super.noSuchMethod(
      Invocation.method(#createPaymentMethod, [], {
        #cardNumber: cardNumber,
        #expMonth: expMonth,
        #expYear: expYear,
        #cvc: cvc,
        #billingName: billingName,
        #billingEmail: billingEmail,
        #billingPhone: billingPhone,
      }),
      returnValue: Future.value({'id': 'pm_mock'}),
    );
  }

  @override
  Future<Map<String, dynamic>> attachPaymentMethod({
    required String paymentIntentId,
    required String paymentMethodId,
    String? clientKey,
    String? returnUrl,
  }) {
    return super.noSuchMethod(
      Invocation.method(#attachPaymentMethod, [], {
        #paymentIntentId: paymentIntentId,
        #paymentMethodId: paymentMethodId,
        #clientKey: clientKey,
        #returnUrl: returnUrl,
      }),
      returnValue: Future.value({
        'attributes': {'status': 'succeeded'},
      }),
    );
  }
}

class MockDepositSupabaseDataSource extends Mock
    implements DepositSupabaseDataSource {
  @override
  Future<String?> createDeposit({
    required String? auctionId,
    required String? userId,
    required double? amount,
    required String? paymentIntentId,
  }) {
    return super.noSuchMethod(
      Invocation.method(#createDeposit, [], {
        #auctionId: auctionId,
        #userId: userId,
        #amount: amount,
        #paymentIntentId: paymentIntentId,
      }),
      returnValue: Future.value('deposit_mock'),
    );
  }
}
