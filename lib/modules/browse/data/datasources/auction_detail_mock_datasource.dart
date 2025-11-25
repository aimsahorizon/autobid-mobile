import '../models/auction_detail_model.dart';

/// Mock data source for auction details
class AuctionDetailMockDataSource {
  /// Simulated network delay
  Future<void> _simulateDelay() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Mock auction detail data with complete 9-step fields
  static final Map<String, AuctionDetailModel> _mockAuctionDetails = {
    '1': AuctionDetailModel(
      id: '1',
      carImageUrl: 'https://images.unsplash.com/photo-1544636331-e26879cd4d9b?w=1200',
      // Auction/Bidding Info
      currentBid: 485000,
      minimumBid: 400000,
      reservePrice: 450000,
      isReserveMet: true,
      showReservePrice: false,
      watchersCount: 45,
      biddersCount: 12,
      totalBids: 28,
      endTime: DateTime.now().add(const Duration(hours: 2, minutes: 30, seconds: 45)),
      status: 'active',
      photos: const CarPhotosModel(
        exterior: [
          'https://images.unsplash.com/photo-1544636331-e26879cd4d9b?w=800',
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
      // Step 1: Basic Information
      brand: 'Toyota',
      model: 'Supra GR',
      variant: '3.0 Premium',
      year: 2023,
      // Step 2: Mechanical Specification
      engineType: 'Inline-6 Turbo',
      engineDisplacement: 3.0,
      cylinderCount: 6,
      horsepower: 382,
      torque: 500,
      transmission: '8-Speed Automatic',
      fuelType: 'Gasoline',
      driveType: 'RWD',
      // Step 3: Dimensions & Capacity
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
      // Step 4: Exterior Details
      exteriorColor: 'Nitro Yellow',
      paintType: 'Metallic',
      rimType: 'Forged Alloy',
      rimSize: '19"',
      tireSize: '255/35 R19',
      tireBrand: 'Michelin Pilot Sport 4',
      // Step 5: Condition & History
      condition: 'Excellent',
      mileage: 8500,
      previousOwners: 1,
      hasModifications: false,
      modificationsDetails: null,
      hasWarranty: true,
      warrantyDetails: 'Factory warranty valid until 2028',
      usageType: 'Private',
      // Step 6: Documentation & Location
      plateNumber: 'XYZ 1234',
      orcrStatus: 'Available',
      registrationStatus: 'Current',
      registrationExpiry: DateTime.now().add(const Duration(days: 730)),
      province: 'Metro Manila',
      cityMunicipality: 'Makati City',
      // Step 8: Final Details
      description: 'Pristine 2023 Toyota Supra GR 3.0 Premium in stunning Nitro Yellow. '
          'Single owner, garage kept, full service history at Toyota authorized center. '
          'Low mileage of only 8,500 km. All original, no modifications. '
          'Comes with complete factory warranty until 2028. '
          'Truly a collector\'s item in perfect condition.',
      knownIssues: null,
      features: const [
        'Adaptive Suspension',
        'Carbon Fiber Interior',
        'Premium Sound System',
        'Launch Control',
        'Active Differential',
        'Heads-Up Display',
        'Apple CarPlay',
        'Heated Seats',
      ],
    ),
    '2': AuctionDetailModel(
      id: '2',
      carImageUrl: 'https://images.unsplash.com/photo-1617531653332-bd46c24f2068?w=1200',
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
      brand: 'Honda',
      model: 'Civic Type R',
      variant: 'Touring',
      year: 2019,
      engineType: 'Inline-4 Turbo',
      engineDisplacement: 2.0,
      cylinderCount: 4,
      horsepower: 306,
      torque: 400,
      transmission: '6-Speed Manual',
      fuelType: 'Gasoline',
      driveType: 'FWD',
      length: 4560.0,
      width: 1875.0,
      height: 1435.0,
      wheelbase: 2700.0,
      groundClearance: 115.0,
      seatingCapacity: 5,
      doorCount: 4,
      fuelTankCapacity: 47.0,
      curbWeight: 1430.0,
      grossWeight: 1850.0,
      exteriorColor: 'Championship White',
      paintType: 'Solid',
      rimType: 'Alloy',
      rimSize: '20"',
      tireSize: '245/30 R20',
      tireBrand: 'Continental Sport Contact',
      condition: 'Very Good',
      mileage: 45000,
      previousOwners: 2,
      hasModifications: true,
      modificationsDetails: 'Aftermarket exhaust system, lowering springs',
      hasWarranty: false,
      warrantyDetails: null,
      usageType: 'Private',
      plateNumber: 'ABC 5678',
      orcrStatus: 'Available',
      registrationStatus: 'Current',
      registrationExpiry: DateTime.now().add(const Duration(days: 180)),
      province: 'Metro Manila',
      cityMunicipality: 'Quezon City',
      description: 'Well-maintained Honda Civic Type R. Performance enthusiast owned. '
          'Documented service history. Minor tasteful modifications enhance the driving experience.',
      knownIssues: 'Minor paint chips on front bumper from normal wear',
      features: const [
        'Limited Slip Differential',
        'Adaptive Dampers',
        'Sport Seats',
        'Track Mode',
        'Brembo Brakes',
      ],
    ),
    '3': AuctionDetailModel(
      id: '3',
      carImageUrl: 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=1200',
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
      brand: 'Ford',
      model: 'Mustang GT',
      variant: 'Premium',
      year: 2021,
      engineType: 'V8 Naturally Aspirated',
      engineDisplacement: 5.0,
      cylinderCount: 8,
      horsepower: 460,
      torque: 569,
      transmission: '10-Speed Automatic',
      fuelType: 'Gasoline',
      driveType: 'RWD',
      length: 4788.0,
      width: 1917.0,
      height: 1381.0,
      wheelbase: 2720.0,
      groundClearance: 125.0,
      seatingCapacity: 4,
      doorCount: 2,
      fuelTankCapacity: 61.0,
      curbWeight: 1745.0,
      grossWeight: 2150.0,
      exteriorColor: 'Grabber Blue',
      paintType: 'Metallic',
      rimType: 'Forged Alloy',
      rimSize: '19"',
      tireSize: '275/40 R19',
      tireBrand: 'Pirelli P Zero',
      condition: 'Excellent',
      mileage: 15000,
      previousOwners: 1,
      hasModifications: false,
      modificationsDetails: null,
      hasWarranty: true,
      warrantyDetails: 'Manufacturer warranty until 2024',
      usageType: 'Private',
      plateNumber: 'DEF 9012',
      orcrStatus: 'Available',
      registrationStatus: 'Current',
      registrationExpiry: DateTime.now().add(const Duration(days: 365)),
      province: 'Metro Manila',
      cityMunicipality: 'Taguig City',
      description: 'Stunning 2021 Ford Mustang GT Premium in rare Grabber Blue. '
          'Powerful 5.0L V8 engine with 460hp. Barely driven, garage kept, immaculate condition. '
          'Premium package includes upgraded interior and tech features.',
      knownIssues: null,
      features: const [
        'Magnetic Ride Control',
        'Premium Audio System',
        'Digital Instrument Cluster',
        'Performance Package',
        'Track Apps',
        'Active Exhaust',
      ],
    ),
  };

  /// Default mock for auctions not in map with complete 9-step data
  static AuctionDetailModel _createDefaultMock(String id) {
    return AuctionDetailModel(
      id: id,
      carImageUrl: 'https://images.unsplash.com/photo-1605559424843-9e4c228bf1c2?w=1200',
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
      brand: 'Toyota',
      model: 'Corolla',
      variant: 'Altis',
      year: 2020,
      engineType: 'Inline-4',
      engineDisplacement: 1.8,
      cylinderCount: 4,
      horsepower: 140,
      torque: 173,
      transmission: 'CVT',
      fuelType: 'Gasoline',
      driveType: 'FWD',
      length: 4640.0,
      width: 1780.0,
      height: 1435.0,
      wheelbase: 2700.0,
      groundClearance: 135.0,
      seatingCapacity: 5,
      doorCount: 4,
      fuelTankCapacity: 50.0,
      curbWeight: 1310.0,
      grossWeight: 1750.0,
      exteriorColor: 'Silver Metallic',
      paintType: 'Metallic',
      rimType: 'Alloy',
      rimSize: '16"',
      tireSize: '205/55 R16',
      tireBrand: 'Bridgestone',
      condition: 'Good',
      mileage: 60000,
      previousOwners: 1,
      hasModifications: false,
      modificationsDetails: null,
      hasWarranty: false,
      warrantyDetails: null,
      usageType: 'Private',
      plateNumber: 'XYZ 0000',
      orcrStatus: 'Available',
      registrationStatus: 'Current',
      registrationExpiry: DateTime.now().add(const Duration(days: 90)),
      province: 'Metro Manila',
      cityMunicipality: 'Manila',
      description: 'Well-maintained Toyota Corolla Altis. Reliable daily driver.',
      knownIssues: null,
      features: const ['Air Conditioning', 'Power Windows', 'Central Locking'],
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
