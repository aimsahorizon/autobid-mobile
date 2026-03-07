import 'package:flutter_test/flutter_test.dart';
import 'package:autobid_mobile/modules/browse/domain/entities/auction_filter.dart';

void main() {
  group('AuctionFilter visibility', () {
    test('counts private visibility as active filter', () {
      const filter = AuctionFilter(visibility: 'private');

      expect(filter.hasActiveFilters, true);
      expect(filter.activeFilterCount, 1);
    });

    test('updates visibility using copyWith', () {
      const filter = AuctionFilter(visibility: 'private');
      final updated = filter.copyWith(visibility: 'public');

      expect(updated.visibility, 'public');
      expect(updated.hasActiveFilters, true);
      expect(updated.activeFilterCount, 1);
    });

    test('empty visibility is not counted as active', () {
      const filter = AuctionFilter(visibility: '');

      expect(filter.hasActiveFilters, false);
      expect(filter.activeFilterCount, 0);
    });
  });
}
