import '../../domain/entities/seller_listing_entity.dart';

/// Mock data source for seller listings
/// Provides sample data for all listing statuses
/// Replace with Supabase implementation for production
class SellerListingsMockDataSource {
  /// Fetches all seller listings grouped by status
  Future<Map<ListingStatus, List<SellerListingEntity>>> getAllListings() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    final now = DateTime.now();

    return {
      ListingStatus.active: [
        SellerListingEntity(
          id: 'list_001',
          imageUrl: 'https://images.unsplash.com/photo-1544636331-e26879cd4d9b?w=800',
          year: 2023,
          make: 'Toyota',
          model: 'Supra GR',
          status: ListingStatus.active,
          startingPrice: 400000,
          currentBid: 485000,
          reservePrice: 450000,
          totalBids: 12,
          watchersCount: 45,
          viewsCount: 320,
          createdAt: now.subtract(const Duration(days: 5)),
          endTime: now.add(const Duration(hours: 2, minutes: 30)),
        ),
        SellerListingEntity(
          id: 'list_002',
          imageUrl: 'https://images.unsplash.com/photo-1603584173870-7f23fdae1b7a?w=800',
          year: 2021,
          make: 'Porsche',
          model: '911 Carrera',
          status: ListingStatus.active,
          startingPrice: 800000,
          currentBid: 890000,
          reservePrice: 850000,
          totalBids: 8,
          watchersCount: 67,
          viewsCount: 512,
          createdAt: now.subtract(const Duration(days: 3)),
          endTime: now.add(const Duration(days: 1, hours: 8)),
        ),
      ],
      ListingStatus.pending: [
        SellerListingEntity(
          id: 'list_003',
          imageUrl: 'https://images.unsplash.com/photo-1580273916550-e323be2ae537?w=800',
          year: 2022,
          make: 'BMW',
          model: 'M4 Competition',
          status: ListingStatus.pending,
          startingPrice: 550000,
          reservePrice: 600000,
          totalBids: 0,
          watchersCount: 0,
          viewsCount: 0,
          createdAt: now.subtract(const Duration(hours: 12)),
        ),
        SellerListingEntity(
          id: 'list_004',
          imageUrl: 'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=800',
          year: 2020,
          make: 'Mercedes-Benz',
          model: 'AMG GT',
          status: ListingStatus.pending,
          startingPrice: 520000,
          reservePrice: 550000,
          totalBids: 0,
          watchersCount: 0,
          viewsCount: 0,
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ],
      ListingStatus.inTransaction: [
        SellerListingEntity(
          id: 'list_005',
          imageUrl: 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=800',
          year: 2020,
          make: 'Chevrolet',
          model: 'Corvette C8',
          status: ListingStatus.inTransaction,
          startingPrice: 650000,
          currentBid: 720000,
          reservePrice: 700000,
          totalBids: 15,
          watchersCount: 34,
          viewsCount: 445,
          createdAt: now.subtract(const Duration(days: 10)),
          endTime: now.subtract(const Duration(days: 2)),
          winnerName: 'John D.',
        ),
      ],
      ListingStatus.draft: [
        SellerListingEntity(
          id: 'list_006',
          imageUrl: 'https://images.unsplash.com/photo-1494976388531-d1058494cdd8?w=800',
          year: 2022,
          make: 'Ford',
          model: 'Mustang GT',
          status: ListingStatus.draft,
          startingPrice: 320000,
          reservePrice: 350000,
          totalBids: 0,
          watchersCount: 0,
          viewsCount: 0,
          createdAt: now.subtract(const Duration(days: 7)),
        ),
        SellerListingEntity(
          id: 'list_007',
          imageUrl: 'https://images.unsplash.com/photo-1542362567-b07e54358753?w=800',
          year: 2021,
          make: 'Nissan',
          model: 'GT-R',
          status: ListingStatus.draft,
          startingPrice: 680000,
          totalBids: 0,
          watchersCount: 0,
          viewsCount: 0,
          createdAt: now.subtract(const Duration(days: 14)),
        ),
      ],
      ListingStatus.sold: [
        SellerListingEntity(
          id: 'list_008',
          imageUrl: 'https://images.unsplash.com/photo-1617531653332-bd46c24f2068?w=800',
          year: 2020,
          make: 'Audi',
          model: 'RS7',
          status: ListingStatus.sold,
          startingPrice: 480000,
          currentBid: 545000,
          soldPrice: 545000,
          reservePrice: 500000,
          totalBids: 18,
          watchersCount: 56,
          viewsCount: 678,
          createdAt: now.subtract(const Duration(days: 30)),
          endTime: now.subtract(const Duration(days: 20)),
          winnerName: 'Maria S.',
        ),
        SellerListingEntity(
          id: 'list_009',
          imageUrl: 'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=800',
          year: 2019,
          make: 'Lexus',
          model: 'LC 500',
          status: ListingStatus.sold,
          startingPrice: 420000,
          currentBid: 485000,
          soldPrice: 485000,
          reservePrice: 450000,
          totalBids: 11,
          watchersCount: 42,
          viewsCount: 534,
          createdAt: now.subtract(const Duration(days: 45)),
          endTime: now.subtract(const Duration(days: 35)),
          winnerName: 'Carlos M.',
        ),
      ],
      ListingStatus.cancelled: [
        SellerListingEntity(
          id: 'list_010',
          imageUrl: 'https://images.unsplash.com/photo-1583121274602-3e2820c69888?w=800',
          year: 2018,
          make: 'Ferrari',
          model: '488 GTB',
          status: ListingStatus.cancelled,
          startingPrice: 1200000,
          currentBid: 950000,
          reservePrice: 1100000,
          totalBids: 5,
          watchersCount: 89,
          viewsCount: 892,
          createdAt: now.subtract(const Duration(days: 20)),
          endTime: now.subtract(const Duration(days: 15)),
        ),
      ],
    };
  }

  /// Get listings by specific status
  Future<List<SellerListingEntity>> getListingsByStatus(
    ListingStatus status,
  ) async {
    final allListings = await getAllListings();
    return allListings[status] ?? [];
  }
}
