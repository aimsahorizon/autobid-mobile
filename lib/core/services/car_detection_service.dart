import 'dart:math';

/// AI Car Detection Service
/// Provides mock and real AI car detection from images
class CarDetectionService {
  final _random = Random();

  // Filipino car brands commonly seen in Philippines
  static const _brands = [
    'Toyota', 'Honda', 'Mitsubishi', 'Nissan', 'Suzuki',
    'Ford', 'Mazda', 'Hyundai', 'Kia', 'Chevrolet',
    'Isuzu', 'Subaru', 'BMW', 'Mercedes-Benz', 'Audi'
  ];

  // Models per brand
  static const _modelsByBrand = {
    'Toyota': ['Vios', 'Corolla', 'Camry', 'Innova', 'Fortuner', 'Hilux', 'Wigo', 'Avanza', 'Rush'],
    'Honda': ['City', 'Civic', 'Accord', 'CR-V', 'HR-V', 'BR-V', 'Jazz', 'Brio'],
    'Mitsubishi': ['Mirage', 'Lancer', 'Montero Sport', 'Strada', 'Xpander', 'L300'],
    'Nissan': ['Almera', 'Sylphy', 'Altima', 'Navara', 'Terra', 'Juke', 'X-Trail'],
    'Suzuki': ['Swift', 'Celerio', 'Dzire', 'Ertiga', 'Jimny', 'Vitara', 'APV'],
    'Ford': ['Fiesta', 'Focus', 'Mustang', 'Ranger', 'Everest', 'EcoSport', 'Territory'],
    'Mazda': ['Mazda2', 'Mazda3', 'Mazda6', 'CX-3', 'CX-5', 'CX-9', 'BT-50'],
    'Hyundai': ['Accent', 'Elantra', 'Tucson', 'Santa Fe', 'Kona', 'Reina', 'Starex'],
    'Kia': ['Picanto', 'Rio', 'Seltos', 'Sportage', 'Sorento', 'Carnival', 'Stonic'],
    'Chevrolet': ['Spark', 'Sail', 'Trailblazer', 'Colorado'],
    'Isuzu': ['D-Max', 'mu-X', 'Traviz'],
    'Subaru': ['Impreza', 'XV', 'Forester', 'Outback', 'WRX'],
    'BMW': ['3 Series', '5 Series', 'X1', 'X3', 'X5'],
    'Mercedes-Benz': ['C-Class', 'E-Class', 'GLA', 'GLC', 'GLE'],
    'Audi': ['A3', 'A4', 'Q3', 'Q5', 'Q7'],
  };

  // Common colors in Philippines
  static const _colors = [
    'White', 'Black', 'Silver', 'Gray', 'Red',
    'Blue', 'Pearl White', 'Metallic Gray', 'Dark Blue'
  ];

  // Body types
  static const _bodyTypes = [
    'Sedan', 'SUV', 'Hatchback', 'Pickup', 'MPV', 'Crossover', 'Coupe', 'Van'
  ];

  // Transmission types
  static const _transmissions = ['Automatic', 'Manual', 'CVT', 'DCT'];

  /// Detect car details from image (Mock AI)
  /// Returns randomized car details with realistic Filipino market data
  Future<Map<String, dynamic>> detectCarFromImage(String imagePath) async {
    // Simulate AI processing time
    await Future.delayed(const Duration(seconds: 2));

    final brand = _brands[_random.nextInt(_brands.length)];
    final models = _modelsByBrand[brand]!;
    final model = models[_random.nextInt(models.length)];
    final currentYear = DateTime.now().year;
    final year = currentYear - _random.nextInt(15); // Cars from last 15 years
    final color = _colors[_random.nextInt(_colors.length)];
    final bodyType = _bodyTypes[_random.nextInt(_bodyTypes.length)];
    final transmission = _transmissions[_random.nextInt(_transmissions.length)];

    // Generate tags based on detected info
    final tags = _generateTags(brand, bodyType, transmission, year);

    return {
      'brand': brand,
      'model': model,
      'year': year,
      'color': color,
      'bodyType': bodyType,
      'transmission': transmission,
      'tags': tags,
      'confidence': 0.85 + (_random.nextDouble() * 0.14), // 85-99% confidence
      'detectedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Generate search/filter tags from car details
  List<String> _generateTags(String brand, String bodyType, String transmission, int year) {
    final tags = <String>[];

    // Brand tag
    tags.add(brand.toLowerCase());

    // Body type tag
    tags.add(bodyType.toLowerCase());

    // Transmission tag
    tags.add(transmission.toLowerCase());

    // Year range tags
    final currentYear = DateTime.now().year;
    if (year >= currentYear - 3) {
      tags.add('new');
      tags.add('almost-new');
    } else if (year >= currentYear - 7) {
      tags.add('used');
    } else {
      tags.add('pre-owned');
      tags.add('classic');
    }

    // Vehicle class tags
    if (bodyType == 'SUV' || bodyType == 'Pickup') {
      tags.add('off-road');
      tags.add('4x4');
    }

    if (bodyType == 'Sedan' || bodyType == 'Hatchback') {
      tags.add('city-car');
      tags.add('compact');
    }

    if (bodyType == 'MPV' || bodyType == 'Van') {
      tags.add('family-car');
      tags.add('spacious');
    }

    // Transmission-based tags
    if (transmission == 'Automatic' || transmission == 'CVT' || transmission == 'DCT') {
      tags.add('automatic-transmission');
      tags.add('easy-drive');
    } else {
      tags.add('manual-transmission');
      tags.add('fuel-efficient');
    }

    // Luxury brand tags
    if (['BMW', 'Mercedes-Benz', 'Audi'].contains(brand)) {
      tags.add('luxury');
      tags.add('premium');
    }

    // Japanese brand tags
    if (['Toyota', 'Honda', 'Nissan', 'Mazda', 'Suzuki', 'Mitsubishi', 'Subaru', 'Isuzu'].contains(brand)) {
      tags.add('japanese-brand');
      tags.add('reliable');
    }

    return tags;
  }

  /// Real AI detection (placeholder for future implementation)
  /// Will integrate with TensorFlow Lite or Cloud Vision API
  Future<Map<String, dynamic>> detectCarFromImageReal(String imagePath) async {
    // TODO: Implement real AI detection
    // Options:
    // 1. TensorFlow Lite with custom-trained model
    // 2. Google Cloud Vision API
    // 3. AWS Rekognition
    // 4. Azure Computer Vision

    throw UnimplementedError('Real AI detection not yet implemented');
  }
}
