import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:autobid_mobile/modules/profile/domain/usecases/subscribe_to_plan_usecase.dart';
import 'package:autobid_mobile/modules/profile/domain/repositories/pricing_repository.dart';
import 'package:autobid_mobile/modules/profile/domain/entities/pricing_entity.dart';
import 'package:autobid_mobile/modules/profile/data/datasources/pricing_supabase_datasource.dart';

class MockPricingRepository extends Mock implements PricingRepository {}

void main() {
  late SubscribeToPlanUsecase usecase;
  late MockPricingRepository mockRepo;

  setUp(() {
    mockRepo = MockPricingRepository();
    usecase = SubscribeToPlanUsecase(repository: mockRepo);
  });

  const userId = 'user-123';

  final goldSub = UserSubscriptionEntity(
    userId: userId,
    plan: SubscriptionPlan.goldMonthly,
    startDate: DateTime(2026, 3, 1),
    endDate: DateTime(2026, 4, 1),
    isActive: true,
  );

  group('SubscribeToPlanUsecase', () {
    test('returns subscription on success', () async {
      when(
        () => mockRepo.subscribeToPlan(
          userId: userId,
          plan: SubscriptionPlan.goldMonthly,
        ),
      ).thenAnswer((_) async => goldSub);

      final result = await usecase.call(
        userId: userId,
        plan: SubscriptionPlan.goldMonthly,
      );
      expect(result.plan, SubscriptionPlan.goldMonthly);
      expect(result.isActive, true);
    });

    test('propagates SubscriptionChangeException for cooldown', () async {
      when(
        () => mockRepo.subscribeToPlan(
          userId: userId,
          plan: SubscriptionPlan.free,
        ),
      ).thenThrow(
        SubscriptionChangeException(
          'downgrade_cooldown',
          cooldownEndsAt: '2026-03-25T12:00:00Z',
        ),
      );

      expect(
        () => usecase.call(userId: userId, plan: SubscriptionPlan.free),
        throwsA(
          isA<SubscriptionChangeException>().having(
            (e) => e.code,
            'code',
            'downgrade_cooldown',
          ),
        ),
      );
    });

    test(
      'propagates SubscriptionChangeException for already_on_plan',
      () async {
        when(
          () => mockRepo.subscribeToPlan(
            userId: userId,
            plan: SubscriptionPlan.goldMonthly,
          ),
        ).thenThrow(SubscriptionChangeException('already_on_plan'));

        expect(
          () =>
              usecase.call(userId: userId, plan: SubscriptionPlan.goldMonthly),
          throwsA(
            isA<SubscriptionChangeException>().having(
              (e) => e.code,
              'code',
              'already_on_plan',
            ),
          ),
        );
      },
    );
  });
}
