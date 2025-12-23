import '../../domain/entities/listing_draft_entity.dart';
import 'photo_categories_data.dart';

/// Demo data generator for testing listing creation flow
/// TODO: Remove this file before production deployment
/// This is isolated and doesn't affect business logic
class DemoListingData {
  /// Toggle to enable/disable demo autofill feature
  static const bool enableDemoAutofill = true;

  /// Generate complete demo listing data
  /// Used for quick testing of the listing creation flow
  static ListingDraftEntity generateDemoData(String draftId, String sellerId) {
    return ListingDraftEntity(
      id: draftId,
      sellerId: sellerId,
      currentStep: 1,
      lastSaved: DateTime.now(),
      // Step 1: Basic Information
      brand: 'Toyota',
      model: 'Corolla',
      variant: 'Altis',
      year: 2020,
      // Step 2: Mechanical Specification
      engineType: 'Inline-4',
      engineDisplacement: 1.8,
      cylinderCount: 4,
      horsepower: 140,
      torque: 173,
      transmission: 'CVT',
      fuelType: 'Gasoline',
      driveType: 'FWD',
      // Step 3: Dimensions & Capacity
      length: 4630.0,
      width: 1780.0,
      height: 1435.0,
      wheelbase: 2700.0,
      groundClearance: 135.0,
      seatingCapacity: 5,
      doorCount: 4,
      fuelTankCapacity: 50.0,
      curbWeight: 1310.0,
      grossWeight: 1700.0,
      // Step 4: Exterior Details
      exteriorColor: 'Pearl White',
      paintType: 'Metallic',
      rimType: 'Alloy',
      rimSize: '16"',
      tireSize: '205/55 R16',
      tireBrand: 'Bridgestone',
      // Step 5: Condition & History
      condition: 'Excellent',
      mileage: 45000,
      previousOwners: 1,
      hasModifications: false,
      modificationsDetails: null,
      hasWarranty: true,
      warrantyDetails: 'Factory warranty valid until 2025',
      usageType: 'Private',
      // Step 6: Documentation & Location
      plateNumber: 'ABC 1234',
      orcrStatus: 'Available',
      registrationStatus: 'Current',
      registrationExpiry: DateTime.now().add(const Duration(days: 365)),
      province: 'Metro Manila',
      cityMunicipality: 'Quezon City',
      // Step 7: Photos (all 56 categories filled)
      photoUrls: PhotoCategoriesData.generateAllPhotos(),
      // Step 8: Final Details & Pricing
      description: 'Well-maintained 2020 Toyota Corolla Altis in excellent condition. '
          'Single owner, regularly serviced at authorized Toyota service center. '
          'Complete documentation and clean title. Perfect for daily commute.',
      knownIssues: null,
      features: ['Sunroof', 'Leather Seats', 'Backup Camera', 'Bluetooth'],
      startingPrice: 750000.0,
      reservePrice: 700000.0,
      auctionEndDate: DateTime.now().add(const Duration(days: 7)),
    );
  }

  /// Get demo data for specific step
  /// Returns a map of field name to value for that step
  static Map<String, dynamic> getDemoDataForStep(int step) {
    switch (step) {
      case 1:
        return {
          'brand': 'Toyota',
          'model': 'Corolla',
          'variant': 'Altis',
          'year': 2020,
        };
      case 2:
        return {
          'engineType': 'Inline-4',
          'engineDisplacement': 1.8,
          'cylinderCount': 4,
          'horsepower': 140,
          'torque': 173,
          'transmission': 'CVT',
          'fuelType': 'Gasoline',
          'driveType': 'FWD',
        };
      case 3:
        return {
          'length': 4630.0,
          'width': 1780.0,
          'height': 1435.0,
          'wheelbase': 2700.0,
          'groundClearance': 135.0,
          'seatingCapacity': 5,
          'doorCount': 4,
          'fuelTankCapacity': 50.0,
          'curbWeight': 1310.0,
          'grossWeight': 1700.0,
        };
      case 4:
        return {
          'exteriorColor': 'Pearl White',
          'paintType': 'Metallic',
          'rimType': 'Alloy',
          'rimSize': '16"',
          'tireSize': '205/55 R16',
          'tireBrand': 'Bridgestone',
        };
      case 5:
        return {
          'condition': 'Excellent',
          'mileage': 45000,
          'previousOwners': 1,
          'hasModifications': false,
          'hasWarranty': true,
          'warrantyDetails': 'Factory warranty valid until 2025',
          'usageType': 'Private',
        };
      case 6:
        return {
          'plateNumber': 'ABC 1234',
          'orcrStatus': 'Available',
          'registrationStatus': 'Current',
          'registrationExpiry': DateTime.now().add(const Duration(days: 365)),
          'province': 'Metro Manila',
          'cityMunicipality': 'Quezon City',
        };
      case 7:
        // All 56 photo categories with mock URLs
        return {
          'photoUrls': PhotoCategoriesData.generateAllPhotos(),
        };
      case 8:
        return {
          'description': 'Well-maintained 2020 Toyota Corolla Altis in excellent condition. '
              'Single owner, regularly serviced at authorized Toyota service center. '
              'Complete documentation and clean title. Perfect for daily commute.',
          'features': ['Sunroof', 'Leather Seats', 'Backup Camera', 'Bluetooth'],
          'startingPrice': 750000.0,
          'reservePrice': 700000.0,
          'auctionEndDate': DateTime.now().add(const Duration(days: 7)),
        };
      default:
        return {};
    }
  }
}
