import '../../domain/entities/user_bid_entity.dart';
import '../../presentation/controllers/bids_controller.dart';

/// Mock data source for user's bid history across all auctions
/// Provides sample data for Active, Won, and Lost tabs in Bids module
///
/// In production, this will be replaced with Supabase implementation:
/// - Query: user_auction_bids table filtered by current user_id
/// - Join with auctions table to get car details and current bid
/// - Filter by status (active/won/lost) based on auction end_time and user's bid position
///
/// TODO: Replace with SupabaseUserBidsDataSource for production
class UserBidsMockDataSource implements IUserBidsDataSource {
  /// Simulated network delay for realistic UX
  static const _mockDelay = Duration(milliseconds: 600);

  /// Fetches all user bids and categorizes them by status
  /// Returns a map with 'active', 'won', 'lost' lists
  ///
  /// Active: Auctions still ongoing where user has placed bids
  /// Won: Ended auctions where user was the highest bidder
  /// Lost: Ended auctions where user was outbid
  @override
  Future<Map<String, List<UserBidEntity>>> getUserBids([String? userId]) async {
    // Simulate network delay
    await Future.delayed(_mockDelay);

    final now = DateTime.now();

    // Active bids - auctions still ongoing where user deposited
    final activeBids = [
      UserBidEntity(
        id: 'ub_001',
        auctionId: 'auction_001',
        carImageUrl:
            'https://images.unsplash.com/photo-1544636331-e26879cd4d9b?w=800',
        year: 2023,
        make: 'Toyota',
        model: 'Supra GR',
        userBidAmount: 485000,
        currentHighestBid: 485000,
        endTime: now.add(const Duration(hours: 2, minutes: 30)),
        status: UserBidStatus.active,
        hasDeposited: true,
        isHighestBidder: true,
        userBidCount: 3,
        canAccess: true,
        transactionStatus: null,
      ),
      UserBidEntity(
        id: 'ub_002',
        auctionId: 'auction_002',
        carImageUrl:
            'https://images.unsplash.com/photo-1580273916550-e323be2ae537?w=800',
        year: 2022,
        make: 'BMW',
        model: 'M4 Competition',
        userBidAmount: 620000,
        currentHighestBid: 650000,
        endTime: now.add(const Duration(hours: 5)),
        status: UserBidStatus.active,
        hasDeposited: true,
        isHighestBidder: false,
        userBidCount: 2,
        canAccess: true,
        transactionStatus: null,
      ),
      UserBidEntity(
        id: 'ub_003',
        auctionId: 'auction_003',
        carImageUrl:
            'https://images.unsplash.com/photo-1603584173870-7f23fdae1b7a?w=800',
        year: 2021,
        make: 'Porsche',
        model: '911 Carrera',
        userBidAmount: 890000,
        currentHighestBid: 890000,
        endTime: now.add(const Duration(days: 1, hours: 8)),
        status: UserBidStatus.active,
        hasDeposited: true,
        isHighestBidder: true,
        userBidCount: 5,
        canAccess: true,
        transactionStatus: null,
      ),
    ];

    // Won bids - auctions ended where user was highest bidder
    final wonBids = [
      UserBidEntity(
        id: 'ub_004',
        auctionId: 'auction_004',
        carImageUrl:
            'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=800',
        year: 2020,
        make: 'Chevrolet',
        model: 'Corvette C8',
        userBidAmount: 720000,
        currentHighestBid: 720000,
        endTime: now.subtract(const Duration(days: 2)),
        status: UserBidStatus.won,
        hasDeposited: true,
        isHighestBidder: true,
        userBidCount: 8,
        canAccess: false, // awaiting seller proceed
        transactionStatus: null,
      ),
      UserBidEntity(
        id: 'ub_005',
        auctionId: 'auction_005',
        carImageUrl:
            'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=800',
        year: 2019,
        make: 'Mercedes-Benz',
        model: 'AMG GT',
        userBidAmount: 580000,
        currentHighestBid: 580000,
        endTime: now.subtract(const Duration(days: 5)),
        status: UserBidStatus.won,
        hasDeposited: true,
        isHighestBidder: true,
        userBidCount: 4,
        canAccess: true, // seller proceeded
        transactionStatus: 'in_transaction',
      ),
    ];

    // Lost bids - auctions ended where user was outbid
    final lostBids = [
      UserBidEntity(
        id: 'ub_006',
        auctionId: 'auction_006',
        carImageUrl:
            'https://images.unsplash.com/photo-1494976388531-d1058494cdd8?w=800',
        year: 2022,
        make: 'Ford',
        model: 'Mustang GT',
        userBidAmount: 350000,
        currentHighestBid: 385000,
        endTime: now.subtract(const Duration(days: 1)),
        status: UserBidStatus.lost,
        hasDeposited: true,
        isHighestBidder: false,
        userBidCount: 3,
        canAccess: true,
        transactionStatus: null,
      ),
      UserBidEntity(
        id: 'ub_007',
        auctionId: 'auction_007',
        carImageUrl:
            'https://images.unsplash.com/photo-1542362567-b07e54358753?w=800',
        year: 2021,
        make: 'Nissan',
        model: 'GT-R',
        userBidAmount: 680000,
        currentHighestBid: 750000,
        endTime: now.subtract(const Duration(days: 3)),
        status: UserBidStatus.lost,
        hasDeposited: true,
        isHighestBidder: false,
        userBidCount: 6,
        canAccess: true,
        transactionStatus: null,
      ),
      UserBidEntity(
        id: 'ub_008',
        auctionId: 'auction_008',
        carImageUrl:
            'https://images.unsplash.com/photo-1617531653332-bd46c24f2068?w=800',
        year: 2020,
        make: 'Audi',
        model: 'RS7',
        userBidAmount: 520000,
        currentHighestBid: 545000,
        endTime: now.subtract(const Duration(days: 7)),
        status: UserBidStatus.lost,
        hasDeposited: true,
        isHighestBidder: false,
        userBidCount: 2,
        canAccess: true,
        transactionStatus: null,
      ),
    ];

    // Cancelled bids - deals that fell through
    final cancelledBids = <UserBidEntity>[];

    // Return categorized bids
    return {
      'active': activeBids,
      'won': wonBids,
      'lost': lostBids,
      'cancelled': cancelledBids,
    };
  }

  /// Fetches only active bids for real-time monitoring
  /// Useful for dashboard widgets or notifications
  Future<List<UserBidEntity>> getActiveBids() async {
    final allBids = await getUserBids();
    return allBids['active'] ?? [];
  }

  /// Fetches only won bids for history display
  Future<List<UserBidEntity>> getWonBids() async {
    final allBids = await getUserBids();
    return allBids['won'] ?? [];
  }

  /// Fetches only lost bids for history display
  Future<List<UserBidEntity>> getLostBids() async {
    final allBids = await getUserBids();
    return allBids['lost'] ?? [];
  }
}
