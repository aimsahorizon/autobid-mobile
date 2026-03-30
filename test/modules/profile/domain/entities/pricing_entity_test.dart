import 'package:flutter_test/flutter_test.dart';
import 'package:autobid_mobile/modules/profile/domain/entities/pricing_entity.dart';

void main() {
  group('SubscriptionPlanExtension', () {
    test('parses new tier plan keys correctly', () {
      expect(
        SubscriptionPlanExtension.fromJson('silver_monthly'),
        SubscriptionPlan.silverMonthly,
      );
      expect(
        SubscriptionPlanExtension.fromJson('silver_yearly'),
        SubscriptionPlan.silverYearly,
      );
      expect(
        SubscriptionPlanExtension.fromJson('gold_monthly'),
        SubscriptionPlan.goldMonthly,
      );
      expect(
        SubscriptionPlanExtension.fromJson('gold_yearly'),
        SubscriptionPlan.goldYearly,
      );
    });

    test('maps legacy pro plan keys for backward compatibility', () {
      expect(
        SubscriptionPlanExtension.fromJson('pro_basic_monthly'),
        SubscriptionPlan.silverMonthly,
      );
      expect(
        SubscriptionPlanExtension.fromJson('pro_basic_yearly'),
        SubscriptionPlan.silverYearly,
      );
      expect(
        SubscriptionPlanExtension.fromJson('pro_plus_monthly'),
        SubscriptionPlan.goldMonthly,
      );
      expect(
        SubscriptionPlanExtension.fromJson('pro_plus_yearly'),
        SubscriptionPlan.goldYearly,
      );
    });

    test('exposes auto-bid only on gold plans', () {
      expect(SubscriptionPlan.free.includesAutoBid, false);
      expect(SubscriptionPlan.silverMonthly.includesAutoBid, false);
      expect(SubscriptionPlan.silverYearly.includesAutoBid, false);
      expect(SubscriptionPlan.goldMonthly.includesAutoBid, true);
      expect(SubscriptionPlan.goldYearly.includesAutoBid, true);
    });
  });
}
