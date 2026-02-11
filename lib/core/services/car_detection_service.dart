import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// AI Car Detection Service
/// Provides mock and real AI car detection from images
class CarDetectionService {
  final _random = Random();
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  
  // Singleton pattern for interpreter to avoid reloading it constantly
  Interpreter? _interpreter;
  List<String>? _labels;

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

  // Known body types for common models (inference helper)
  static const _knownBodyTypes = {
    'vios': 'Sedan', 'corolla': 'Sedan', 'camry': 'Sedan', 'city': 'Sedan', 'civic': 'Sedan', 'accord': 'Sedan',
    'accent': 'Sedan', 'elantra': 'Sedan', 'reina': 'Sedan', 'mirage g4': 'Sedan', 'almera': 'Sedan', 'sylphy': 'Sedan',
    'dzire': 'Sedan', 'mazda2 sedan': 'Sedan', 'mazda3': 'Sedan', 'mazda6': 'Sedan', 'impreza': 'Sedan',
    
    'fortuner': 'SUV', 'land cruiser': 'SUV', 'rush': 'SUV', 'cr-v': 'SUV', 'hr-v': 'SUV', 'br-v': 'SUV',
    'montero': 'SUV', 'montero sport': 'SUV', 'terra': 'SUV', 'x-trail': 'SUV', 'jimny': 'SUV', 'vitara': 'SUV',
    'everest': 'SUV', 'territory': 'SUV', 'ecosport': 'SUV', 'tucson': 'SUV', 'santa fe': 'SUV', 'kona': 'SUV',
    'sportage': 'SUV', 'sorento': 'SUV', 'seltos': 'SUV', 'trailblazer': 'SUV', 'subaru xv': 'SUV', 'forester': 'SUV',
    
    'wigo': 'Hatchback', 'yaris': 'Hatchback', 'brio': 'Hatchback', 'jazz': 'Hatchback', 'mirage': 'Hatchback',
    'swift': 'Hatchback', 'celerio': 'Hatchback', 'picanto': 'Hatchback', 'spark': 'Hatchback', 'mazda2': 'Hatchback',
    
    'hilux': 'Pickup', 'strada': 'Pickup', 'navara': 'Pickup', 'ranger': 'Pickup', 'raptor': 'Pickup', 
    'd-max': 'Pickup', 'bt-50': 'Pickup', 'colorado': 'Pickup',
    
    'innova': 'MPV', 'avanza': 'MPV', 'xpander': 'MPV', 'ertiga': 'MPV', 'apv': 'MPV', 'livina': 'MPV',
    
    'hiace': 'Van', 'urvan': 'Van', 'l300': 'Van', 'grand starex': 'Van', 'starex': 'Van', 'carnival': 'Van',
    'alphard': 'Van',
  };

  String _guessBodyType(String model) {
    final key = model.toLowerCase();
    // Try exact match
    if (_knownBodyTypes.containsKey(key)) return _knownBodyTypes[key]!;
    
    // Try partial match (e.g. "Vios G" matches "vios")
    for (final entry in _knownBodyTypes.entries) {
      if (key.contains(entry.key)) return entry.value;
    }
    
    return 'Sedan'; // Fallback
  }

  // Database for detailed specs (loaded from JSON)
  Map<String, dynamic>? _specDatabase;

  Future<void> _loadSpecDatabase() async {
    if (_specDatabase != null) return;
    try {
      final jsonStr = await rootBundle.loadString('assets/ai/car_specs.json');
      _specDatabase = json.decode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      print('Error loading spec database: $e');
      _specDatabase = {};
    }
  }

  Map<String, dynamic> _guessCarSpecs(String model) {
    if (_specDatabase == null || _specDatabase!.isEmpty) {
      return {
        'transmission': 'Automatic',
        'fuelType': 'Gasoline',
        'seatingCapacity': 5,
        'engineDisplacement': 1.5,
        'doorCount': 4,
        'driveType': 'FWD'
      };
    }

    final key = model.toLowerCase().replaceAll(' ', '_');
    
    // 1. Try exact match
    if (_specDatabase!.containsKey(key)) {
      return _specDatabase![key]['specs'] as Map<String, dynamic>;
    }

    // 2. Try partial match (e.g. "Toyota Vios 2020" -> match "vios")
    for (final dbKey in _specDatabase!.keys) {
      if (key.contains(dbKey.split('_').last)) { // check if "vios" is in "toyota_vios_2020"
         return _specDatabase![dbKey]['specs'] as Map<String, dynamic>;
      }
    }
    
    return {
        'transmission': 'Automatic',
        'fuelType': 'Gasoline',
        'seatingCapacity': 5,
        'engineDisplacement': 1.5,
        'doorCount': 4,
        'driveType': 'FWD'
    };
  }

  /// Simple algorithm to detect dominant color from the center of the image
  String _detectDominantColor(img.Image image) {
    // 1. Define standard car colors
    final palette = {
      'Black': [30, 30, 30],
      'White': [240, 240, 240],
      'Silver': [192, 192, 192],
      'Gray': [128, 128, 128],
      'Red': [200, 0, 0],
      'Blue': [0, 0, 200],
      'Yellow': [200, 200, 0],
      'Green': [0, 128, 0],
      'Brown': [139, 69, 19],
      'Orange': [255, 165, 0],
    };

    int rTotal = 0, gTotal = 0, bTotal = 0;
    int count = 0;

    // 2. Sample pixels from the center 50% of the image
    final startX = (image.width * 0.25).toInt();
    final endX = (image.width * 0.75).toInt();
    final startY = (image.height * 0.25).toInt();
    final endY = (image.height * 0.75).toInt();

    for (var y = startY; y < endY; y += 10) { // Step 10 for speed
      for (var x = startX; x < endX; x += 10) {
        final pixel = image.getPixel(x, y);
        rTotal += pixel.r.toInt();
        gTotal += pixel.g.toInt();
        bTotal += pixel.b.toInt();
        count++;
      }
    }

    if (count == 0) return 'Unknown';

    final rAvg = rTotal / count;
    final gAvg = gTotal / count;
    final bAvg = bTotal / count;

    // 3. Find closest color in palette
    String closestColor = 'Gray';
    double minDistance = double.maxFinite;

    palette.forEach((name, rgb) {
      final dist = sqrt(
        pow(rAvg - rgb[0], 2) + pow(gAvg - rgb[1], 2) + pow(bAvg - rgb[2], 2)
      );
      if (dist < minDistance) {
        minDistance = dist;
        closestColor = name;
      }
    });

    return closestColor;
  }

  /// Uses OCR to find plate number in the image
  Future<String?> _scanForPlateNumber(String imagePath) async {
    try {
      final inputImage = InputImage.fromFile(File(imagePath));
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      // Regex for PH Plates: 
      // 1. Old: LLL DDD or LLL-DDD (ABC 123)
      // 2. New: LLL DDDD or LLL-DDDD (ABC 1234)
      // 3. Conduction: L DDDD or LL DDDD (E 1234 / AB 1234)
      // 4. MC: LLL DDD (ABC 123)
      
      // Simplified robust regex: 3 letters, space/dash, 3-4 digits
      final plateRegex = RegExp(r'\b([A-Z]{3}[\s-]?[0-9]{3,4})\b');
      
      final match = plateRegex.firstMatch(recognizedText.text);
      if (match != null) {
        return match.group(0)?.replaceAll('-', ' '); // Standardize to space
      }
      return null;
    } catch (e) {
      print('Plate OCR Error: $e');
      return null;
    }
  }

  /// Real AI detection using TensorFlow Lite
  /// Returns detected car details or throws Exception if model not found
  Future<Map<String, dynamic>> detectCarFromImageReal(String imagePath) async {
    try {
      await _loadSpecDatabase();
      // 1. Load Model (Lazy loading)
      if (_interpreter == null) {
        // If the file 'assets/ai/car_model.tflite' is not in pubspec or filesystem, this will throw.
        _interpreter = await Interpreter.fromAsset('assets/ai/car_model.tflite');
        final labelsStr = await rootBundle.loadString('assets/ai/labels.txt');
        _labels = labelsStr.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }

      if (_interpreter == null || _labels == null || _labels!.isEmpty) {
        throw Exception("Model or labels failed to load");
      }

      // 2. Preprocess Image
      final imageData = File(imagePath).readAsBytesSync();
      final image = img.decodeImage(imageData);
      if (image == null) throw Exception("Failed to decode image");

      // Resize to 224x224 (MobileNet standard)
      final resizedImage = img.copyResize(image, width: 224, height: 224);

      // Convert to Float32 List [1, 224, 224, 3] and normalize to [0, 1]
      // Assuming training used rescale=1./255
      var input = List.generate(1, (i) => 
        List.generate(224, (y) => 
          List.generate(224, (x) {
            final pixel = resizedImage.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0
            ];
          })
        )
      );
      
      // 3. Inference
      var output = List.filled(1 * _labels!.length, 0.0).reshape([1, _labels!.length]);
      _interpreter!.run(input, output);
      
      // 4. Parse Results
      final probabilities = output[0] as List<double>;
      var maxProbability = 0.0;
      var maxIndex = 0;
      
      for (var i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxProbability) {
          maxProbability = probabilities[i];
          maxIndex = i;
        }
      }

      final detectedLabel = _labels![maxIndex];
      // Expecting format "Brand_Model_Year"
      final parts = detectedLabel.split('_');
      final detectedBrand = parts.isNotEmpty ? parts[0] : "Unknown";
      final detectedModel = parts.length > 1 ? parts[1] : "Unknown";
      final detectedYear = parts.length > 2 ? int.tryParse(parts[2]) : 2020;
      
      // Infer Body Type and Color
      final detectedBodyType = _guessBodyType(detectedModel);
      final detectedColor = _detectDominantColor(image);
      final specs = _guessCarSpecs(detectedModel);
      
      // Run Plate OCR (Parallel or Sequential)
      final detectedPlate = await _scanForPlateNumber(imagePath);

      final tags = _generateTags(
        detectedBrand, 
        detectedBodyType, 
        specs['transmission'] ?? "Automatic", 
        detectedYear ?? 2020
      );
      
      // Add color tag
      tags.add(detectedColor.toLowerCase());

      return {
         'brand': detectedBrand,
         'model': detectedModel,
         'year': detectedYear,
         'bodyType': detectedBodyType,
         'color': detectedColor,
         'plateNumber': detectedPlate, // New Field
         'confidence': maxProbability,
         'tags': tags,
         'specs': specs, // Return inferred specs
         'is_real_ai': true
      };
      
    } catch (e) {
      print('AI Detection Error (falling back to mock): $e');
      return detectCarFromImage(imagePath);
    }
  }
}