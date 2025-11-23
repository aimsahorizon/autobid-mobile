import '../models/auction_detail_model.dart';

/// Mock data source for auction details
class AuctionDetailMockDataSource {
  /// Simulated network delay
  Future<void> _simulateDelay() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Mock auction detail data
  static final Map<String, AuctionDetailModel> _mockAuctionDetails = {
    '1': AuctionDetailModel(
      id: '1',
      carImageUrl: 'https://images.unsplash.com/photo-1605559424843-9e4c228bf1c2?w=1200',
      year: 2020,
      make: 'Toyota',
      model: 'Camry',
      currentBid: 850000,
      minimumBid: 800000,
      reservePrice: 900000,
      isReserveMet: false,
      showReservePrice: false,
      watchersCount: 45,
      biddersCount: 12,
      totalBids: 28,
      endTime: DateTime.now().add(const Duration(hours: 2, minutes: 30, seconds: 45)),
      status: 'active',
      photos: const CarPhotosModel(
        exterior: [
          'https://images.unsplash.com/photo-1605559424843-9e4c228bf1c2?w=800',
          'https://images.unsplash.com/photo-1621007947382-bb3c3994e3fb?w=800',
          'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=800',
        ],
        interior: [
          'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800',
          'https://images.unsplash.com/photo-1489824904134-891ab64532f1?w=800',
        ],
        engine: [
          'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=800',
        ],
        details: [
          'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=800',
        ],
        documents: [
          'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?w=800',
        ],
      ),
      hasUserDeposited: false,
    ),
    '2': AuctionDetailModel(
      id: '2',
      carImageUrl: 'https://images.unsplash.com/photo-1617531653332-bd46c24f2068?w=1200',
      year: 2019,
      make: 'Honda',
      model: 'Civic',
      currentBid: 720000,
      minimumBid: 650000,
      reservePrice: 700000,
      isReserveMet: true,
      showReservePrice: true,
      watchersCount: 32,
      biddersCount: 8,
      totalBids: 15,
      endTime: DateTime.now().add(const Duration(minutes: 45, seconds: 30)),
      status: 'active',
      photos: const CarPhotosModel(
        exterior: [
          'https://images.unsplash.com/photo-1617531653332-bd46c24f2068?w=800',
          'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=800',
        ],
        interior: [
          'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800',
        ],
        engine: [
          'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=800',
        ],
        details: [],
        documents: [],
      ),
      hasUserDeposited: true,
    ),
    '3': AuctionDetailModel(
      id: '3',
      carImageUrl: 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=1200',
      year: 2021,
      make: 'Ford',
      model: 'Mustang',
      currentBid: 1850000,
      minimumBid: 1500000,
      reservePrice: 2000000,
      isReserveMet: false,
      showReservePrice: false,
      watchersCount: 89,
      biddersCount: 23,
      totalBids: 56,
      endTime: DateTime.now().add(const Duration(days: 1, hours: 5)),
      status: 'active',
      photos: const CarPhotosModel(
        exterior: [
          'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=800',
          'https://images.unsplash.com/photo-1583121274602-3e2820c69888?w=800',
        ],
        interior: [
          'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800',
        ],
        engine: [
          'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=800',
        ],
        details: [
          'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=800',
        ],
        documents: [],
      ),
      hasUserDeposited: false,
    ),
  };

  /// Default mock for auctions not in map
  static AuctionDetailModel _createDefaultMock(String id) {
    return AuctionDetailModel(
      id: id,
      carImageUrl: 'https://images.unsplash.com/photo-1605559424843-9e4c228bf1c2?w=1200',
      year: 2020,
      make: 'Generic',
      model: 'Car',
      currentBid: 500000,
      minimumBid: 450000,
      reservePrice: 600000,
      isReserveMet: false,
      showReservePrice: false,
      watchersCount: 10,
      biddersCount: 5,
      totalBids: 8,
      endTime: DateTime.now().add(const Duration(hours: 3)),
      status: 'active',
      photos: const CarPhotosModel(
        exterior: ['https://images.unsplash.com/photo-1605559424843-9e4c228bf1c2?w=800'],
        interior: ['https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800'],
        engine: [],
        details: [],
        documents: [],
      ),
      hasUserDeposited: false,
    );
  }

  /// Get auction detail by ID
  Future<AuctionDetailModel> getAuctionDetail(String id) async {
    await _simulateDelay();
    return _mockAuctionDetails[id] ?? _createDefaultMock(id);
  }

  /// Simulate deposit payment
  Future<bool> processDeposit(String auctionId) async {
    await Future.delayed(const Duration(seconds: 2));
    return true; // Always succeeds in mock
  }

  /// Simulate placing a bid
  Future<bool> placeBid(String auctionId, double amount) async {
    await Future.delayed(const Duration(seconds: 1));
    return true; // Always succeeds in mock
  }
}
