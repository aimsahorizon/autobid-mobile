import 'package:flutter_test/flutter_test.dart';
import 'package:autobid_mobile/modules/lists/domain/entities/listing_draft_entity.dart';
import 'package:autobid_mobile/modules/lists/domain/entities/seller_listing_entity.dart';

void main() {
  group('ListingDraftEntity', () {
    final tDraft = ListingDraftEntity(
      id: 'draft_1',
      sellerId: 'user_1',
      currentStep: 1,
      lastSaved: DateTime.now(),
      brand: 'Toyota',
      model: 'Supra',
      variant: '3.0 Premium',
      year: 2020,
    );

    test('should copyWith updated fields including barangay', () {
      final updated = tDraft.copyWith(
        barangay: 'San Jose Gusu',
        province: 'Zamboanga del Sur',
        cityMunicipality: 'Zamboanga City',
      );

      expect(updated.barangay, 'San Jose Gusu');
      expect(updated.province, 'Zamboanga del Sur');
      expect(updated.cityMunicipality, 'Zamboanga City');
      expect(updated.id, tDraft.id); // original field unchanged
    });

    test('carName should include variant', () {
      expect(tDraft.carName, '2020 Toyota Supra 3.0 Premium');
    });

    test('carName should handle missing variant', () {
      final noVariantDraft = tDraft.copyWith(variant: null);
      // copyWith might send null, but copyWith implementation usually does "variant ?? this.variant"
      // Wait, copyWith signature is nullable, but default behavior preserves.
      // We need to explicitly pass null if we want to clear it? 
      // The generated copyWith usually ignores nulls passed as arguments if it uses ?? this.field.
      // Let's create a new instance to be sure.
      
      final cleanDraft = ListingDraftEntity(
        id: 'draft_2',
        sellerId: 'user_1',
        currentStep: 1,
        lastSaved: DateTime.now(),
        brand: 'Honda',
        model: 'Civic',
        year: 2018,
      );
      
      expect(cleanDraft.carName, '2018 Honda Civic');
    });

    test('toListingDetailEntity should map fields correctly', () {
      final tFullDraft = tDraft.copyWith(
        barangay: 'Tetuan',
        province: 'Zamboanga del Sur',
        cityMunicipality: 'Zamboanga City',
        startingPrice: 1000000,
        description: 'Test Description',
      );

      final detail = tFullDraft.toListingDetailEntity();

      expect(detail.id, tFullDraft.id);
      expect(detail.barangay, 'Tetuan');
      expect(detail.status, ListingStatus.draft);
      expect(detail.variant, '3.0 Premium');
      expect(detail.carName, '2020 Toyota Supra 3.0 Premium');
    });

    test('isStepComplete for Step 7 should require barangay', () {
      // Create a draft that satisfies other step 7 reqs but misses barangay
      final incompleteDraft = ListingDraftEntity(
        id: 'draft_1',
        sellerId: 'user_1',
        currentStep: 7,
        lastSaved: DateTime.now(),
        plateNumber: 'ABC 1234',
        isPlateValid: true,
        orcrStatus: 'Available',
        province: 'Zamboanga del Sur',
        cityMunicipality: 'Zamboanga City',
        // barangay is null
      );

      expect(incompleteDraft.isStepComplete(7), false);

      final completeDraft = incompleteDraft.copyWith(
        barangay: 'Tumaga',
      );

      expect(completeDraft.isStepComplete(7), true);
    });
  });
}