import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:autobid_mobile/modules/profile/presentation/controllers/pricing_controller.dart';
import 'package:autobid_mobile/modules/profile/domain/entities/pricing_entity.dart';
import 'package:autobid_mobile/modules/profile/domain/usecases/get_token_balance_usecase.dart';
import 'package:autobid_mobile/modules/profile/domain/usecases/get_user_subscription_usecase.dart';
import 'package:autobid_mobile/modules/profile/domain/usecases/get_token_packages_usecase.dart';
import 'package:autobid_mobile/modules/profile/domain/usecases/purchase_token_package_usecase.dart';
import 'package:autobid_mobile/modules/profile/domain/usecases/subscribe_to_plan_usecase.dart';
import 'package:autobid_mobile/modules/profile/data/datasources/pricing_supabase_datasource.dart';

class MockGetTokenBalance extends Mock implements GetTokenBalanceUsecase {}

class MockGetUserSubscription extends Mock
    implements GetUserSubscriptionUsecase {}

class MockGetTokenPackages extends Mock implements GetTokenPackagesUsecase {}

class MockPurchaseTokenPackage extends Mock
    implements PurchaseTokenPackageUsecase {}

class MockSubscribeToPlan extends Mock implements SubscribeToPlanUsecase {}

void main() {
  late PricingController controller;
  late MockGetTokenBalance mockGetTokenBalance;
  late MockSubscribeToPlan mockSubscribeToPlan;

  const userId = 'user-123';

  setUp(() {
    mockGetTokenBalance = MockGetTokenBalance();
    mockSubscribeToPlan = MockSubscribeToPlan();

    controller = PricingController(
      getTokenBalanceUsecase: mockGetTokenBalance,
      getUserSubscriptionUsecase: MockGetUserSubscription(),
      getTokenPackagesUsecase: MockGetTokenPackages(),
      purchaseTokenPackageUsecase: MockPurchaseTokenPackage(),
      subscribeToPlanUsecase: mockSubscribeToPlan,
    );
  });

  group('PricingController.subscribe', () {
    test('returns true on successful subscription', () async {
      final sub = UserSubscriptionEntity(
        userId: userId,
        plan: SubscriptionPlan.silverMonthly,
        isActive: true,
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 4, 1),
      );
      final balance = TokenBalanceEntity(
        userId: userId,
        biddingTokens: 60,
        listingTokens: 3,
        updatedAt: DateTime.now(),
      );

      when(
        () => mockSubscribeToPlan.call(
          userId: userId,
          plan: SubscriptionPlan.silverMonthly,
        ),
      ).thenAnswer((_) async => sub);
      when(
        () => mockGetTokenBalance.call(userId),
      ).thenAnswer((_) async => balance);

      final result = await controller.subscribe(
        userId: userId,
        plan: SubscriptionPlan.silverMonthly,
      );
      expect(result, true);
      expect(controller.error, isNull);
      expect(controller.currentPlan, SubscriptionPlan.silverMonthly);
    });

    test('sets cooldown error on downgrade_cooldown', () async {
      when(
        () => mockSubscribeToPlan.call(
          userId: userId,
          plan: SubscriptionPlan.free,
        ),
      ).thenThrow(
        SubscriptionChangeException(
          'downgrade_cooldown',
          cooldownEndsAt: '2026-03-25T12:00:00Z',
        ),
      );

      final result = await controller.subscribe(
        userId: userId,
        plan: SubscriptionPlan.free,
      );
      expect(result, false);
      expect(controller.error, contains('24 hours'));
    });

    test('sets already_on_plan error', () async {
      when(
        () => mockSubscribeToPlan.call(
          userId: userId,
          plan: SubscriptionPlan.goldMonthly,
        ),
      ).thenThrow(SubscriptionChangeException('already_on_plan'));

      final result = await controller.subscribe(
        userId: userId,
        plan: SubscriptionPlan.goldMonthly,
      );
      expect(result, false);
      expect(controller.error, contains('already on this plan'));
    });
  });
}
