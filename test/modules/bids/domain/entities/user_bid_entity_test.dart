import 'package:flutter_test/flutter_test.dart';
import 'package:autobid_mobile/modules/bids/domain/entities/user_bid_entity.dart';

void main() {
  group('UserBidEntity', () {
    test('carName should include variant when present', () {
      final bid = UserBidEntity(
        id: 'bid_1',
        auctionId: 'auction_1',
        carImageUrl: 'http://example.com/image.jpg',
        year: 2023,
        make: 'Ford',
        model: 'Ranger',
        variant: 'Raptor',
        userBidAmount: 2500000,
        currentHighestBid: 2600000,
        endTime: DateTime.now().add(const Duration(days: 1)),
        status: UserBidStatus.active,
        hasDeposited: true,
        isHighestBidder: false,
        userBidCount: 2,
        canAccess: false,
      );

      expect(bid.carName, '2023 Ford Ranger Raptor');
    });

    test('carName should exclude variant when null', () {
      final bid = UserBidEntity(
        id: 'bid_2',
        auctionId: 'auction_2',
        carImageUrl: 'http://example.com/image.jpg',
        year: 2020,
        make: 'Toyota',
        model: 'Vios',
        variant: null,
        userBidAmount: 500000,
        currentHighestBid: 550000,
        endTime: DateTime.now().add(const Duration(days: 1)),
        status: UserBidStatus.active,
        hasDeposited: true,
        isHighestBidder: false,
        userBidCount: 1,
        canAccess: false,
      );

      expect(bid.carName, '2020 Toyota Vios');
    });
  });
}
