import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/browse/domain/repositories/auction_detail_repository.dart';
import 'package:autobid_mobile/modules/browse/domain/usecases/save_auto_bid_settings_usecase.dart';

class MockAuctionDetailRepository extends Mock
    implements AuctionDetailRepository {}

void main() {
  late MockAuctionDetailRepository repository;

  setUp(() {
    repository = MockAuctionDetailRepository();
  });

  group('SaveAutoBidSettingsUseCase', () {
    test(
      'returns PermissionFailure when user is not eligible for auto-bid',
      () async {
        final usecase = SaveAutoBidSettingsUseCase(
          repository,
          canUseAutoBid: (_) async => false,
        );

        final result = await usecase.call(
          auctionId: 'auction-1',
          userId: 'user-1',
          maxBidAmount: 50000,
          bidIncrement: 500,
          isActive: true,
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<PermissionFailure>()),
          (_) => fail('Expected failure result'),
        );

        verifyNever(
          () => repository.saveAutoBidSettings(
            auctionId: any(named: 'auctionId'),
            userId: any(named: 'userId'),
            maxBidAmount: any(named: 'maxBidAmount'),
            bidIncrement: any(named: 'bidIncrement'),
            isActive: any(named: 'isActive'),
          ),
        );
      },
    );

    test('saves settings when user is eligible for auto-bid', () async {
      when(
        () => repository.saveAutoBidSettings(
          auctionId: any(named: 'auctionId'),
          userId: any(named: 'userId'),
          maxBidAmount: any(named: 'maxBidAmount'),
          bidIncrement: any(named: 'bidIncrement'),
          isActive: any(named: 'isActive'),
        ),
      ).thenAnswer((_) async => const Right(null));

      final usecase = SaveAutoBidSettingsUseCase(
        repository,
        canUseAutoBid: (_) async => true,
      );

      final result = await usecase.call(
        auctionId: 'auction-2',
        userId: 'user-2',
        maxBidAmount: 75000,
        bidIncrement: 1000,
        isActive: true,
      );

      expect(result.isRight(), true);
      verify(
        () => repository.saveAutoBidSettings(
          auctionId: 'auction-2',
          userId: 'user-2',
          maxBidAmount: 75000,
          bidIncrement: 1000,
          isActive: true,
        ),
      ).called(1);
    });
  });
}
