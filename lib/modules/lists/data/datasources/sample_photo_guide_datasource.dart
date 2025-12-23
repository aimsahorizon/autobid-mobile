/// Data source for sample photo guides
/// Provides sample/reference photos for each photo category
/// Backend can populate this with actual sample images from database
class SamplePhotoGuideDataSource {
  /// Toggle between mock data and backend data
  /// Set to true to use mock URLs, false to fetch from backend
  static const bool useMockData = true;

  /// Get sample photo URL for a specific category
  /// TODO: Replace with actual backend API call
  /// Example: await http.get('api/sample-photos/$category')
  Future<String?> getSamplePhoto(String category) async {
    if (useMockData) {
      return _getMockSamplePhoto(category);
    } else {
      // TODO: Implement backend fetch
      // final response = await http.get(Uri.parse('$baseUrl/sample-photos/$category'));
      // if (response.statusCode == 200) {
      //   final data = json.decode(response.body);
      //   return data['sampleUrl'];
      // }
      return null;
    }
  }

  /// Mock sample photo URLs for testing
  /// These will be replaced with actual backend URLs
  String? _getMockSamplePhoto(String category) {
    // Using picsum.photos for mock sample images
    // Backend will replace these with actual guide photos
    final seed = category.replaceAll(' ', '_').toLowerCase();
    return 'https://picsum.photos/seed/sample_$seed/600/400';
  }
}
