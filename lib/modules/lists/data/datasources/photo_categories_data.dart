import '../../domain/entities/listing_draft_entity.dart';

/// Helper class to generate demo photo URLs for all 56 categories
/// TODO: Remove before production
class PhotoCategoriesData {
  /// Generate mock photo URLs for all 56 photo categories
  /// Each category gets one mock photo URL
  static Map<String, List<String>> generateAllPhotos() {
    final Map<String, List<String>> photoUrls = {};

    // Loop through all 56 photo categories and assign a mock URL to each
    for (final category in PhotoCategories.all) {
      photoUrls[category] = ['mock_photo_${category.replaceAll(' ', '_').toLowerCase()}.jpg'];
    }

    return photoUrls;
  }
}
