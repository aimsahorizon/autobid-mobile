import 'package:flutter_test/flutter_test.dart';
import 'package:autobid_mobile/modules/lists/domain/entities/listing_draft_entity.dart';

void main() {
  group('PhotoCategories', () {
    test('toKey should convert display names to snake_case', () {
      expect(PhotoCategories.toKey('Front View'), 'front_view');
      expect(PhotoCategories.toKey('Rear View'), 'rear_view');
      expect(PhotoCategories.toKey('Left Side'), 'left_side');
      expect(PhotoCategories.toKey('OR/CR'), 'or_cr');
      expect(PhotoCategories.toKey('Engine & Mechanical'), 'engine_&_mechanical'); // Assuming basic replacement
    });

    test('toKey should handle already lowercase strings', () {
      expect(PhotoCategories.toKey('front_view'), 'front_view');
    });
  });
}
