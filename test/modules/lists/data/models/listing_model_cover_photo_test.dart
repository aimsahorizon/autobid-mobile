import 'package:flutter_test/flutter_test.dart';
import 'package:autobid_mobile/modules/lists/data/models/listing_model.dart';

void main() {
  group('ListingModel cover photo fallback', () {
    test('uses cover_photo_url when present', () {
      final model = ListingModel.fromJson({
        'id': 'listing-1',
        'seller_id': 'seller-1',
        'status': 'pending_approval',
        'admin_status': 'pending',
        'brand': 'Toyota',
        'model': 'Vios',
        'year': 2020,
        'transmission': 'AT',
        'fuel_type': 'Gasoline',
        'exterior_color': 'White',
        'condition': 'Used',
        'mileage': 12000,
        'plate_number': 'ABC123',
        'orcr_status': 'complete',
        'registration_status': 'active',
        'province': 'Metro Manila',
        'city_municipality': 'Taguig',
        'photo_urls': {
          'exterior': ['https://img/exterior.jpg'],
        },
        'cover_photo_url': 'https://img/featured.jpg',
        'description': 'Nice car',
        'starting_price': 500000,
        'current_bid': 0,
        'total_bids': 0,
        'watchers_count': 0,
        'views_count': 0,
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-01T00:00:00.000Z',
      });

      final entity = model.toSellerListingEntity();
      expect(entity.imageUrl, 'https://img/featured.jpg');
    });

    test('falls back to preferred category when cover_photo_url is null', () {
      final model = ListingModel.fromJson({
        'id': 'listing-2',
        'seller_id': 'seller-1',
        'status': 'pending_approval',
        'admin_status': 'pending',
        'brand': 'Honda',
        'model': 'City',
        'year': 2019,
        'transmission': 'CVT',
        'fuel_type': 'Gasoline',
        'exterior_color': 'Gray',
        'condition': 'Used',
        'mileage': 18000,
        'plate_number': 'XYZ789',
        'orcr_status': 'complete',
        'registration_status': 'active',
        'province': 'Cebu',
        'city_municipality': 'Cebu City',
        'photo_urls': {
          'details': ['https://img/details.jpg'],
          'interior': ['https://img/interior.jpg'],
        },
        'description': 'Clean unit',
        'starting_price': 450000,
        'current_bid': 0,
        'total_bids': 0,
        'watchers_count': 0,
        'views_count': 0,
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-01T00:00:00.000Z',
      });

      final entity = model.toSellerListingEntity();
      expect(entity.imageUrl, 'https://img/interior.jpg');
    });
  });
}
