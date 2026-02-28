import 'package:flutter_test/flutter_test.dart';
import 'package:autobid_mobile/modules/lists/data/models/listing_model.dart';
import 'package:autobid_mobile/modules/lists/domain/entities/seller_listing_entity.dart';

void main() {
  group('Transaction Cancellation Logic', () {
    test('ListingModel should map seller_rejection_reason to cancellationReason', () {
      final json = {
        'id': 'txn-123',
        'transaction_id': 'txn-123',
        'cancellation_reason': 'Buyer did not show up',
        'seller_id': 'seller-1',
        'status': 'deal_failed',
        'admin_status': 'approved',
        'brand': 'Toyota',
        'model': 'Camry',
        'year': 2020,
        'transmission': 'Automatic',
        'fuel_type': 'Gasoline',
        'exterior_color': 'Black',
        'condition': 'Used',
        'mileage': 50000,
        'has_modifications': false,
        'has_warranty': false,
        'plate_number': 'ABC 1234',
        'orcr_status': 'Complete',
        'registration_status': 'Registered',
        'province': 'Metro Manila',
        'city_municipality': 'Makati',
        'photo_urls': <String, dynamic>{},
        'description': 'Nice car',
        'starting_price': 500000.0,
        'current_bid': 550000.0,
        'total_bids': 5,
        'watchers_count': 10,
        'views_count': 100,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final model = ListingModel.fromJson(json);

      expect(model.cancellationReason, 'Buyer did not show up');
      expect(model.transactionId, 'txn-123');
    });

    test('SellerListingEntity should retain cancellationReason from ListingModel', () {
      final model = ListingModel(
        id: 'txn-123',
        sellerId: 'seller-1',
        status: 'deal_failed',
        adminStatus: 'approved',
        brand: 'Toyota',
        model: 'Camry',
        year: 2020,
        transmission: 'Automatic',
        fuelType: 'Gasoline',
        exteriorColor: 'Black',
        condition: 'Used',
        mileage: 50000,
        hasModifications: false,
        hasWarranty: false,
        plateNumber: 'ABC 1234',
        orcrStatus: 'Complete',
        registrationStatus: 'Registered',
        province: 'Metro Manila',
        cityMunicipality: 'Makati',
        photoUrls: {},
        description: 'Nice car',
        startingPrice: 500000,
        currentBid: 550000,
        totalBids: 5,
        watchersCount: 10,
        viewsCount: 100,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        transactionId: 'txn-123',
        cancellationReason: 'Buyer did not show up',
      );

      final entity = model.toSellerListingEntity();

      expect(entity.cancellationReason, 'Buyer did not show up');
      expect(entity.status, ListingStatus.dealFailed);
    });
  });
}
