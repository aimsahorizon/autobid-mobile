import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:autobid_mobile/modules/profile/data/datasources/pricing_supabase_datasource.dart';
import 'package:autobid_mobile/modules/profile/domain/entities/pricing_entity.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class TestPricingSupabaseDatasource extends PricingSupabaseDatasource {
  Map<String, dynamic>? tokenRow;
  Map<String, dynamic>? subscriptionRow;
  bool tokenCreateCalled = false;
  bool subscriptionCreateCalled = false;
  bool biddingRpcCalled = false;
  bool listingRpcCalled = false;

  TestPricingSupabaseDatasource({required SupabaseClient supabase})
    : super(supabase: supabase);

  @override
  Future<Map<String, dynamic>?> fetchTokenBalanceRow(String userId) async {
    return tokenRow;
  }

  @override
  Future<Map<String, dynamic>> createStarterTokenBalance(String userId) async {
    tokenCreateCalled = true;
    tokenRow = {
      'user_id': userId,
      'bidding_tokens': PricingSupabaseDatasource.starterBiddingTokens,
      'listing_tokens': PricingSupabaseDatasource.starterListingTokens,
      'updated_at': DateTime.now().toIso8601String(),
    };
    return tokenRow!;
  }

  @override
  Future<Map<String, dynamic>?> fetchActiveSubscriptionRow(
    String userId,
  ) async {
    return subscriptionRow;
  }

  @override
  Future<Map<String, dynamic>> createFreeSubscription(String userId) async {
    subscriptionCreateCalled = true;
    subscriptionRow = {
      'user_id': userId,
      'plan': SubscriptionPlan.free.toJson(),
      'is_active': true,
      'start_date': DateTime.now().toIso8601String(),
      'end_date': null,
      'cancelled_at': null,
    };
    return subscriptionRow!;
  }

  @override
  Future<bool> callConsumeBiddingTokenRpc({
    required String userId,
    required String referenceId,
  }) async {
    biddingRpcCalled = true;
    return true;
  }

  @override
  Future<bool> callConsumeListingTokenRpc({
    required String userId,
    required String referenceId,
  }) async {
    listingRpcCalled = true;
    return false;
  }
}

void main() {
  group('PricingSupabaseDatasource token accuracy', () {
    late TestPricingSupabaseDatasource datasource;

    setUp(() {
      datasource = TestPricingSupabaseDatasource(
        supabase: MockSupabaseClient(),
      );
    });

    test(
      'initializes and returns starter token balance when missing',
      () async {
        final result = await datasource.getTokenBalance('user-1');

        expect(datasource.tokenCreateCalled, true);
        expect(
          result.biddingTokens,
          PricingSupabaseDatasource.starterBiddingTokens,
        );
        expect(
          result.listingTokens,
          PricingSupabaseDatasource.starterListingTokens,
        );
      },
    );

    test('initializes free subscription when missing', () async {
      final result = await datasource.getUserSubscription('user-2');

      expect(datasource.subscriptionCreateCalled, true);
      expect(result.plan, SubscriptionPlan.free);
      expect(result.isActive, true);
    });

    test(
      'ensures balance is initialized before bidding token consumption RPC',
      () async {
        datasource.tokenRow = null;

        final consumed = await datasource.consumeBiddingToken(
          userId: 'user-3',
          referenceId: 'ref-1',
        );

        expect(consumed, true);
        expect(datasource.tokenCreateCalled, true);
        expect(datasource.biddingRpcCalled, true);
      },
    );

    test(
      'listing token depletion path returns false from RPC result',
      () async {
        datasource.tokenRow = {
          'user_id': 'user-4',
          'bidding_tokens': 5,
          'listing_tokens': 0,
          'updated_at': DateTime.now().toIso8601String(),
        };

        final consumed = await datasource.consumeListingToken(
          userId: 'user-4',
          referenceId: 'ref-2',
        );

        expect(consumed, false);
        expect(datasource.listingRpcCalled, true);
      },
    );
  });
}
