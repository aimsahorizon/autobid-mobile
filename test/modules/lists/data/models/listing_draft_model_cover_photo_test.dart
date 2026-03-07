import 'package:flutter_test/flutter_test.dart';
import 'package:autobid_mobile/modules/lists/data/models/listing_draft_model.dart';

void main() {
  group('ListingDraftModel cover photo mapping', () {
    test('parses and serializes cover_photo_url', () {
      final model = ListingDraftModel.fromJson({
        'id': 'draft-1',
        'seller_id': 'seller-1',
        'current_step': 1,
        'last_saved': '2026-01-01T00:00:00.000Z',
        'photo_urls': {
          'exterior': ['https://img/exterior.jpg'],
        },
        'cover_photo_url': 'https://img/exterior.jpg',
      });

      expect(model.coverPhotoUrl, 'https://img/exterior.jpg');

      final json = model.toJson();
      expect(json['cover_photo_url'], 'https://img/exterior.jpg');
    });
  });
}
