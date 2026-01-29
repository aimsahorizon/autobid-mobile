/// Data source for sample photo guides
/// Provides sample/reference photos for each photo category
/// Uses local assets from the images directory
class SamplePhotoGuideDataSource {
  /// Base path for car assets
  static const String _baseAssetPath = 'assets/images/2017 Honda Civic Type R';

  /// Mapping of category names to asset paths
  static const Map<String, String> _assetMapping = {
    // Exterior
    'Front View': 'Front view/5LKfR.jpg',
    'Rear View': 'Rear view/9B_Hg.jpg',
    'Left Side': 'driver side full view/C08XV.jpg',
    'Right Side': 'passenger side full view/s-7lNdaAM.jpg',
    'Front Left Angle': 'front 3-4 angle (driver side)/s-gUCr-Js.jpg',
    'Front Right Angle': 'front 3-4 angle (passenger side)/s-7lNdaAM.jpg',
    'Rear Left Angle': 'rear 3-4 angle (driver seat)/s-EpUblvB.jpg',
    'Rear Right Angle': 'rear 3-4 angle (passenger seat)/0bfXB.jpg',
    
    // Interior
    'Dashboard': 'driver seat and dashboard/s-XICBlSl.jpeg',
    'Steering Wheel': 'steering wheel and controls/Tu9Xe.jpg',
    'Center Console': 'center console and infotainment/s-Nk0JIHF.jpeg',
    'Front Seats': 'passenger seat/s--OrGUsw.jpeg',
    'Instrument Cluster': 'odometer/A42DA.jpg',
    'Trunk Interior': 'trunk or cargo area/s-2zii47X.jpeg',
    
    // Engine
    'Engine Bay Overview': 'engine bay overall shot/s-bnvUXOF.jpeg',
    
    // Wheels
    'Front Left Wheel': 'closeup of all wheels and tires/s-ASZiDOp.jpeg',
    'Front Right Wheel': 'closeup of all wheels and tires/s-ASZiDOp.jpeg',
    'Rear Left Wheel': 'closeup of all wheels and tires/s-ASZiDOp.jpeg',
    'Rear Right Wheel': 'closeup of all wheels and tires/s-ASZiDOp.jpeg',
    
    // Documents
    'OR/CR': 'title or registration/s-soSUY4T.jpeg',
    'Registration Papers': 'title or registration/s-soSUY4T.jpeg',
  };

  /// Get sample photo path for a specific category
  Future<String?> getSamplePhoto(String category) async {
    final relativePath = _assetMapping[category];
    if (relativePath != null) {
      return '$_baseAssetPath/$relativePath';
    }
    
    // Fallback: return a generic car photo or null
    return '$_baseAssetPath/Front view/5LKfR.jpg';
  }
}