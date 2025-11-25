import '../../domain/entities/bid_detail_entity.dart';

/// Mock datasource for bid details (Active/Won/Lost auctions)
/// Combines auction data with user's bidding information
///
/// TODO: Replace with Supabase implementation
/// - Query: auctions table JOIN user_bids WHERE user_id = current_user
/// - Include: car specs, bid history, deposit status
/// - Real-time: Subscribe to bid updates for active auctions
class BidDetailMockDataSource {
  // Toggle to switch between mock and real backend
  // Set to true for mock data, false when backend is ready
  static const bool useMockData = true;

  // Simulated network delay
  Future<void> _delay() => Future.delayed(const Duration(milliseconds: 800));

  /// Get complete bid details by auction ID
  /// Includes car specs, bid history, and user's participation
  Future<BidDetailEntity?> getBidDetail(String auctionId) async {
    await _delay();

    // Try to find in mock data
    try {
      return _mockBidDetails.firstWhere((b) => b.id == auctionId);
    } catch (e) {
      // Create dynamic bid detail if not found
      return _createDynamicBidDetail(auctionId);
    }
  }

  /// Creates dynamic bid detail for any auction ID
  /// Ensures UI works even if data doesn't exist in mock storage
  BidDetailEntity _createDynamicBidDetail(String auctionId) {
    final now = DateTime.now();

    return BidDetailEntity(
      id: auctionId,
      sellerId: 'seller_001',
      brand: 'Toyota',
      model: 'Supra GR',
      variant: '3.0 Premium',
      year: 2023,
      startingPrice: 400000,
      currentBid: 485000,
      reservePrice: 450000,
      totalBids: 12,
      auctionEndDate: now.add(const Duration(hours: 2)),
      bidHistory: _createSampleBidHistory(auctionId),
      userHighestBid: 485000,
      userBidCount: 3,
      isUserHighestBidder: true,
      hasDeposited: true,
      depositAmount: 50000,
      depositPaidAt: now.subtract(const Duration(days: 1)),
      engineType: 'Inline-6 Turbo',
      engineDisplacement: 3.0,
      cylinderCount: 6,
      horsepower: 382,
      torque: 500,
      transmission: 'Automatic',
      fuelType: 'Gasoline',
      driveType: 'RWD',
      length: 4380.0,
      width: 1865.0,
      height: 1295.0,
      wheelbase: 2470.0,
      groundClearance: 125.0,
      seatingCapacity: 2,
      doorCount: 2,
      fuelTankCapacity: 52.0,
      curbWeight: 1520.0,
      grossWeight: 1720.0,
      exteriorColor: 'Nitro Yellow',
      paintType: 'Metallic',
      rimType: 'Forged Alloy',
      rimSize: '19"',
      tireSize: '255/35 R19',
      tireBrand: 'Michelin Pilot Sport 4',
      condition: 'Excellent',
      mileage: 8500,
      previousOwners: 1,
      hasModifications: false,
      modificationsDetails: null,
      hasWarranty: true,
      warrantyDetails: 'Factory warranty valid until 2028',
      usageType: 'Private',
      plateNumber: 'ABC 1234',
      orcrStatus: 'Available',
      registrationStatus: 'Current',
      registrationExpiry: now.add(const Duration(days: 365)),
      province: 'Metro Manila',
      cityMunicipality: 'Quezon City',
      photoUrls: _createSamplePhotos(),
      description: 'Pristine 2023 Toyota Supra GR in rare Nitro Yellow. One owner, full service history.',
      knownIssues: null,
      features: const [
        'Adaptive Suspension',
        'Carbon Fiber Interior',
        'Launch Control',
        'Premium Sound System',
      ],
    );
  }

  /// Creates sample bid history for visualization
  List<BidHistoryItem> _createSampleBidHistory(String auctionId) {
    final now = DateTime.now();

    return [
      BidHistoryItem(
        id: 'bid_${auctionId}_1',
        bidderId: 'user_current',
        bidderName: 'You',
        bidAmount: 485000,
        timestamp: now.subtract(const Duration(minutes: 15)),
        isCurrentUser: true,
      ),
      BidHistoryItem(
        id: 'bid_${auctionId}_2',
        bidderId: 'user_002',
        bidderName: 'Juan D.',
        bidAmount: 475000,
        timestamp: now.subtract(const Duration(hours: 1)),
        isCurrentUser: false,
      ),
      BidHistoryItem(
        id: 'bid_${auctionId}_3',
        bidderId: 'user_current',
        bidderName: 'You',
        bidAmount: 465000,
        timestamp: now.subtract(const Duration(hours: 2)),
        isCurrentUser: true,
      ),
      BidHistoryItem(
        id: 'bid_${auctionId}_4',
        bidderId: 'user_003',
        bidderName: 'Maria S.',
        bidAmount: 455000,
        timestamp: now.subtract(const Duration(hours: 4)),
        isCurrentUser: false,
      ),
      BidHistoryItem(
        id: 'bid_${auctionId}_5',
        bidderId: 'user_current',
        bidderName: 'You',
        bidAmount: 445000,
        timestamp: now.subtract(const Duration(hours: 6)),
        isCurrentUser: true,
      ),
    ];
  }

  /// Creates sample photo URLs organized by category
  Map<String, List<String>> _createSamplePhotos() {
    return {
      'Exterior': [
        'https://images.unsplash.com/photo-1544636331-e26879cd4d9b?w=800',
        'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=800',
      ],
      'Interior': [
        'https://images.unsplash.com/photo-1580273916550-e323be2ae537?w=800',
      ],
      'Engine': [
        'https://images.unsplash.com/photo-1603584173870-7f23fdae1b7a?w=800',
      ],
    };
  }

  // Mock data storage - Active bids
  static final List<BidDetailEntity> _mockBidDetails = [
    BidDetailEntity(
      id: 'auction_001',
      sellerId: 'seller_001',
      brand: 'Toyota',
      model: 'Supra GR',
      variant: '3.0 Premium',
      year: 2023,
      startingPrice: 400000,
      currentBid: 485000,
      reservePrice: 450000,
      totalBids: 12,
      auctionEndDate: DateTime.now().add(const Duration(hours: 2, minutes: 30)),
      bidHistory: [
        BidHistoryItem(
          id: 'bid_001_1',
          bidderId: 'user_current',
          bidderName: 'You',
          bidAmount: 485000,
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
          isCurrentUser: true,
        ),
        BidHistoryItem(
          id: 'bid_001_2',
          bidderId: 'user_002',
          bidderName: 'Juan D.',
          bidAmount: 475000,
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          isCurrentUser: false,
        ),
      ],
      userHighestBid: 485000,
      userBidCount: 3,
      isUserHighestBidder: true,
      hasDeposited: true,
      depositAmount: 50000,
      depositPaidAt: DateTime.now().subtract(const Duration(days: 1)),
      engineType: 'Inline-6 Turbo',
      engineDisplacement: 3.0,
      horsepower: 382,
      torque: 500,
      transmission: 'Automatic',
      fuelType: 'Gasoline',
      driveType: 'RWD',
      exteriorColor: 'Nitro Yellow',
      condition: 'Excellent',
      mileage: 8500,
      description: 'Pristine 2023 Toyota Supra GR in rare Nitro Yellow.',
      features: const ['Adaptive Suspension', 'Launch Control'],
    ),
  ];
}
