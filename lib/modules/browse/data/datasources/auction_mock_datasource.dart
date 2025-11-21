import '../models/auction_model.dart';

/// Mock data source for testing without Supabase
/// Replace AuctionRemoteDataSource with this for offline development
class AuctionMockDataSource {
  /// Simulated network delay
  Future<void> _simulateDelay() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Mock auction data
  static final List<AuctionModel> _mockAuctions = [
    AuctionModel(
      id: '1',
      carImageUrl: 'https://images.unsplash.com/photo-1605559424843-9e4c228bf1c2?w=800',
      year: 2020,
      make: 'Toyota',
      model: 'Camry',
      currentBid: 850000,
      watchersCount: 45,
      biddersCount: 12,
      endTime: DateTime.now().add(const Duration(hours: 2)),
    ),
    AuctionModel(
      id: '2',
      carImageUrl: 'https://images.unsplash.com/photo-1617531653332-bd46c24f2068?w=800',
      year: 2019,
      make: 'Honda',
      model: 'Civic',
      currentBid: 720000,
      watchersCount: 32,
      biddersCount: 8,
      endTime: DateTime.now().add(const Duration(minutes: 45)),
    ),
    AuctionModel(
      id: '3',
      carImageUrl: 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=800',
      year: 2021,
      make: 'Ford',
      model: 'Mustang',
      currentBid: 1850000,
      watchersCount: 89,
      biddersCount: 23,
      endTime: DateTime.now().add(const Duration(days: 1)),
    ),
    AuctionModel(
      id: '4',
      carImageUrl: 'https://images.unsplash.com/photo-1583121274602-3e2820c69888?w=800',
      year: 2018,
      make: 'Mazda',
      model: 'CX-5',
      currentBid: 680000,
      watchersCount: 28,
      biddersCount: 6,
      endTime: DateTime.now().add(const Duration(hours: 5)),
    ),
    AuctionModel(
      id: '5',
      carImageUrl: 'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=800',
      year: 2022,
      make: 'Tesla',
      model: 'Model 3',
      currentBid: 2100000,
      watchersCount: 156,
      biddersCount: 34,
      endTime: DateTime.now().add(const Duration(hours: 12)),
    ),
    AuctionModel(
      id: '6',
      carImageUrl: 'https://images.unsplash.com/photo-1621007947382-bb3c3994e3fb?w=800',
      year: 2017,
      make: 'Nissan',
      model: 'Altima',
      currentBid: 540000,
      watchersCount: 19,
      biddersCount: 4,
      endTime: DateTime.now().add(const Duration(hours: 3)),
    ),
    AuctionModel(
      id: '7',
      carImageUrl: 'https://images.unsplash.com/photo-1619405399517-d7fce0f13302?w=800',
      year: 2020,
      make: 'BMW',
      model: 'X5',
      currentBid: 2450000,
      watchersCount: 203,
      biddersCount: 41,
      endTime: DateTime.now().add(const Duration(days: 2)),
    ),
    AuctionModel(
      id: '8',
      carImageUrl: 'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=800',
      year: 2019,
      make: 'Hyundai',
      model: 'Tucson',
      currentBid: 620000,
      watchersCount: 37,
      biddersCount: 9,
      endTime: DateTime.now().add(const Duration(hours: 8)),
    ),
  ];

  /// Fetch all active auctions (mock)
  Future<List<AuctionModel>> getActiveAuctions() async {
    await _simulateDelay();
    return List.from(_mockAuctions);
  }

  /// Fetch auction by ID (mock)
  Future<AuctionModel?> getAuctionById(String id) async {
    await _simulateDelay();
    try {
      return _mockAuctions.firstWhere((auction) => auction.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Search auctions by make or model (mock)
  Future<List<AuctionModel>> searchAuctions(String query) async {
    await _simulateDelay();
    final lowercaseQuery = query.toLowerCase();
    return _mockAuctions.where((auction) {
      return auction.make.toLowerCase().contains(lowercaseQuery) ||
          auction.model.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
}
