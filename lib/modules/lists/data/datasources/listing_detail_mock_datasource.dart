import '../../domain/entities/listing_detail_entity.dart';
import '../../domain/entities/seller_listing_entity.dart';
import 'photo_categories_data.dart';

/// Mock data source for fetching complete listing details
/// Combines seller listing status with full car specifications
/// Replace with Supabase implementation for production
class ListingDetailMockDataSource {
  // Toggle to switch between mock and real backend
  // Set to true for mock data, false when backend is ready
  static const bool useMockData = true;

  /// Fetch complete listing details by ID
  /// Combines SellerListingEntity data with full car specifications
  Future<ListingDetailEntity?> getListingDetail(String listingId) async {
    if (useMockData) {
      return _getMockListingDetail(listingId);
    } else {
      // TODO: Implement backend fetch
      // final response = await supabase
      //   .from('listings')
      //   .select('*, listing_details(*)')
      //   .eq('id', listingId)
      //   .single();
      return null;
    }
  }

  /// Convert SellerListingEntity to full ListingDetailEntity
  /// Used when navigating from list view to detail page
  Future<ListingDetailEntity> convertToDetailEntity(
    SellerListingEntity sellerListing,
  ) async {
    // In real implementation, fetch additional data from backend
    // For mock, generate sample detailed data
    await Future.delayed(const Duration(milliseconds: 300));

    return ListingDetailEntity(
      // From SellerListingEntity - Auction/Status Info
      id: sellerListing.id,
      status: sellerListing.status,
      startingPrice: sellerListing.startingPrice,
      startTime: sellerListing.startTime,
      currentBid: sellerListing.currentBid,
      reservePrice: sellerListing.reservePrice,
      totalBids: sellerListing.totalBids,
      watchersCount: sellerListing.watchersCount,
      viewsCount: sellerListing.viewsCount,
      createdAt: sellerListing.createdAt,
      endTime: sellerListing.endTime,
      winnerName: sellerListing.winnerName,
      soldPrice: sellerListing.soldPrice,
      // Mock full car specifications based on make/model
      brand: sellerListing.make,
      model: sellerListing.model,
      variant: _getVariant(sellerListing.make, sellerListing.model),
      year: sellerListing.year,
      engineType: _getEngineType(sellerListing.make),
      engineDisplacement: _getEngineDisplacement(sellerListing.make),
      cylinderCount: _getCylinderCount(sellerListing.make),
      horsepower: _getHorsepower(sellerListing.make),
      torque: _getTorque(sellerListing.make),
      transmission: _getTransmission(sellerListing.make),
      fuelType: 'Gasoline',
      driveType: _getDriveType(sellerListing.make),
      length: 4500.0,
      width: 1850.0,
      height: 1400.0,
      wheelbase: 2750.0,
      groundClearance: 120.0,
      seatingCapacity: 4,
      doorCount: 2,
      fuelTankCapacity: 60.0,
      curbWeight: 1500.0,
      grossWeight: 1900.0,
      exteriorColor: _getColor(sellerListing.id),
      paintType: 'Metallic',
      rimType: 'Alloy',
      rimSize: '19"',
      tireSize: '245/40 R19',
      tireBrand: 'Michelin',
      condition: 'Excellent',
      mileage: _getMileage(sellerListing.year).toInt(),
      previousOwners: 1,
      hasModifications: false,
      modificationsDetails: null,
      hasWarranty: true,
      warrantyDetails: 'Factory warranty valid until ${sellerListing.year + 5}',
      usageType: 'Private',
      plateNumber: 'ABC ${sellerListing.id.substring(5, 8)}',
      orcrStatus: 'Available',
      registrationStatus: 'Current',
      registrationExpiry: DateTime.now().add(const Duration(days: 365)),
      province: 'Metro Manila',
      cityMunicipality: 'Quezon City',
      photoUrls: PhotoCategoriesData.generateAllPhotos(),
      description: _getDescription(sellerListing.make, sellerListing.model, sellerListing.year),
      knownIssues: null,
      features: _getFeatures(sellerListing.make),
      auctionEndDate: sellerListing.endTime,
    );
  }

  Future<ListingDetailEntity?> _getMockListingDetail(String listingId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Sample mock data - in real app, this would come from database
    return ListingDetailEntity(
      id: listingId,
      status: ListingStatus.active,
      startingPrice: 400000,
      currentBid: 485000,
      reservePrice: 450000,
      totalBids: 12,
      watchersCount: 45,
      viewsCount: 320,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      endTime: DateTime.now().add(const Duration(hours: 2, minutes: 30)),
      brand: 'Toyota',
      model: 'Supra GR',
      variant: '3.0 Premium',
      year: 2023,
      engineType: 'Inline-6 Turbo',
      engineDisplacement: 3.0,
      cylinderCount: 6,
      horsepower: 382,
      torque: 500,
      transmission: '8-Speed Automatic',
      fuelType: 'Gasoline',
      driveType: 'RWD',
      length: 4380.0,
      width: 1865.0,
      height: 1295.0,
      wheelbase: 2470.0,
      groundClearance: 110.0,
      seatingCapacity: 2,
      doorCount: 2,
      fuelTankCapacity: 52.0,
      curbWeight: 1520.0,
      grossWeight: 1800.0,
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
      hasWarranty: true,
      warrantyDetails: 'Factory warranty valid until 2028',
      usageType: 'Private',
      plateNumber: 'XYZ 1234',
      orcrStatus: 'Available',
      registrationStatus: 'Current',
      registrationExpiry: DateTime.now().add(const Duration(days: 730)),
      province: 'Metro Manila',
      cityMunicipality: 'Makati City',
      photoUrls: PhotoCategoriesData.generateAllPhotos(),
      description:
          'Pristine 2023 Toyota Supra GR 3.0 Premium in stunning Nitro Yellow. '
          'Single owner, garage kept, full service history at Toyota authorized center. '
          'Low mileage of only 8,500 km. All original, no modifications. '
          'Comes with complete factory warranty until 2028. '
          'Truly a collector\'s item in perfect condition.',
      knownIssues: null,
      features: [
        'Adaptive Suspension',
        'Carbon Fiber Interior',
        'Premium Sound System',
        'Launch Control',
        'Active Differential',
        'Heads-Up Display',
        'Apple CarPlay',
        'Heated Seats',
      ],
      auctionEndDate: DateTime.now().add(const Duration(hours: 2, minutes: 30)),
    );
  }

  // Helper methods to generate mock data based on car make
  String _getVariant(String make, String model) {
    switch (make) {
      case 'Toyota':
        return '3.0 Premium';
      case 'Porsche':
        return 'S';
      case 'BMW':
        return 'Competition';
      case 'Mercedes-Benz':
        return 'Pro';
      default:
        return 'Standard';
    }
  }

  String _getEngineType(String make) {
    switch (make) {
      case 'Toyota':
        return 'Inline-6 Turbo';
      case 'Porsche':
        return 'Flat-6';
      case 'BMW':
        return 'Inline-6 Twin-Turbo';
      case 'Mercedes-Benz':
        return 'V8 Twin-Turbo';
      default:
        return 'Inline-4';
    }
  }

  double _getEngineDisplacement(String make) {
    switch (make) {
      case 'Toyota':
        return 3.0;
      case 'Porsche':
        return 3.0;
      case 'BMW':
        return 3.0;
      case 'Mercedes-Benz':
        return 4.0;
      default:
        return 2.0;
    }
  }

  int _getCylinderCount(String make) {
    switch (make) {
      case 'Mercedes-Benz':
        return 8;
      default:
        return 6;
    }
  }

  int _getHorsepower(String make) {
    switch (make) {
      case 'Toyota':
        return 382;
      case 'Porsche':
        return 379;
      case 'BMW':
        return 503;
      case 'Mercedes-Benz':
        return 577;
      default:
        return 200;
    }
  }

  int _getTorque(String make) {
    switch (make) {
      case 'Toyota':
        return 500;
      case 'Porsche':
        return 450;
      case 'BMW':
        return 650;
      case 'Mercedes-Benz':
        return 700;
      default:
        return 250;
    }
  }

  String _getTransmission(String make) {
    switch (make) {
      case 'Toyota':
        return '8-Speed Automatic';
      case 'Porsche':
        return '7-Speed PDK';
      case 'BMW':
        return '8-Speed M Steptronic';
      case 'Mercedes-Benz':
        return '7-Speed AMG Speedshift DCT';
      default:
        return 'Automatic';
    }
  }

  String _getDriveType(String make) {
    switch (make) {
      case 'Porsche':
        return 'RWD';
      case 'Toyota':
        return 'RWD';
      default:
        return 'AWD';
    }
  }

  String _getColor(String id) {
    final colors = [
      'Nitro Yellow',
      'Racing Blue',
      'Alpine White',
      'Frozen Black',
      'Guards Red'
    ];
    return colors[id.hashCode % colors.length];
  }

  double _getMileage(int year) {
    final age = DateTime.now().year - year;
    // Generate reasonable mileage based on car age
    return (age * 10000 + (age * 2000)).toDouble();
  }

  String _getDescription(String make, String model, int year) {
    return 'Pristine $year $make $model in excellent condition. '
        'Single owner, garage kept, full service history at authorized service center. '
        'Complete documentation and clean title. Perfect for enthusiasts.';
  }

  List<String> _getFeatures(String make) {
    switch (make) {
      case 'Toyota':
        return [
          'Adaptive Suspension',
          'Carbon Fiber Interior',
          'Premium Sound System',
          'Launch Control'
        ];
      case 'Porsche':
        return [
          'Sport Chrono Package',
          'PASM Suspension',
          'Porsche Torque Vectoring',
          'Alcantara Interior'
        ];
      case 'BMW':
        return [
          'M Carbon Ceramic Brakes',
          'M Driver\'s Package',
          'Harman Kardon Sound',
          'M Sport Exhaust'
        ];
      case 'Mercedes-Benz':
        return [
          'AMG Performance Exhaust',
          'Carbon Fiber Trim',
          'Burmester Sound System',
          'AMG Track Pace'
        ];
      default:
        return ['Premium Sound', 'Leather Seats', 'Sunroof'];
    }
  }
}
