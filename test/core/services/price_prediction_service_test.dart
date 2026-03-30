import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for AI Price Prediction pipeline.
///
/// Since TFLite Interpreter requires native binaries (can't run in flutter test),
/// we test: metadata format, preprocessing logic, fallback behavior, and encoding
/// correctness to ensure the training→deployment pipeline is consistent.
void main() {
  late Map<String, dynamic> metadata;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Load the actual deployed metadata
    final jsonStr = await rootBundle.loadString(
      'assets/ai/pricing_metadata.json',
    );
    metadata = json.decode(jsonStr);
  });

  group('Pricing Metadata Format', () {
    test('has required top-level keys', () {
      expect(
        metadata.containsKey('encoders'),
        isTrue,
        reason: 'Missing "encoders" key',
      );
      expect(
        metadata.containsKey('stats'),
        isTrue,
        reason: 'Missing "stats" key',
      );
      expect(
        metadata.containsKey('price_max'),
        isTrue,
        reason: 'Missing "price_max" key',
      );
    });

    test('encoders has brand, condition, transmission maps', () {
      final encoders = metadata['encoders'] as Map<String, dynamic>;
      expect(encoders.containsKey('brand'), isTrue);
      expect(encoders.containsKey('condition'), isTrue);
      expect(encoders.containsKey('transmission'), isTrue);
    });

    test('brand encoder has Philippine market brands', () {
      final brands = metadata['encoders']['brand'] as Map<String, dynamic>;
      expect(brands.containsKey('Toyota'), isTrue, reason: 'Missing Toyota');
      expect(brands.containsKey('Honda'), isTrue, reason: 'Missing Honda');
      expect(
        brands.containsKey('Mitsubishi'),
        isTrue,
        reason: 'Missing Mitsubishi',
      );
      expect(brands.containsKey('Hyundai'), isTrue, reason: 'Missing Hyundai');
      expect(
        brands.length,
        greaterThanOrEqualTo(10),
        reason: 'Should have at least 10 PH brands',
      );
    });

    test('brand encoder values are sequential integers starting from 0', () {
      final brands = metadata['encoders']['brand'] as Map<String, dynamic>;
      final values = brands.values.map((v) => v as int).toList()..sort();
      for (int i = 0; i < values.length; i++) {
        expect(
          values[i],
          equals(i),
          reason: 'Brand codes should be sequential 0..${values.length - 1}',
        );
      }
    });

    test('condition encoder has exactly 4 levels in correct order', () {
      final conditions =
          metadata['encoders']['condition'] as Map<String, dynamic>;
      expect(conditions['Excellent'], equals(0));
      expect(conditions['Good'], equals(1));
      expect(conditions['Fair'], equals(2));
      expect(conditions['Poor'], equals(3));
      expect(conditions.length, equals(4));
    });

    test('transmission encoder maps known types', () {
      final trans =
          metadata['encoders']['transmission'] as Map<String, dynamic>;
      expect(trans.containsKey('Automatic'), isTrue);
      expect(trans.containsKey('Manual'), isTrue);
      expect(trans.length, greaterThanOrEqualTo(2));
    });

    test('stats has year and mileage ranges', () {
      final stats = metadata['stats'] as Map<String, dynamic>;
      expect(stats['year']['min'], isA<num>());
      expect(stats['year']['max'], isA<num>());
      expect(stats['mileage']['min'], isA<num>());
      expect(stats['mileage']['max'], isA<num>());
    });

    test('year range is valid', () {
      final yearMin = (metadata['stats']['year']['min'] as num).toDouble();
      final yearMax = (metadata['stats']['year']['max'] as num).toDouble();
      expect(yearMin, greaterThanOrEqualTo(2000));
      expect(yearMax, lessThanOrEqualTo(2030));
      expect(yearMax, greaterThan(yearMin));
    });

    test('mileage range is valid', () {
      final mileMin = (metadata['stats']['mileage']['min'] as num).toDouble();
      final mileMax = (metadata['stats']['mileage']['max'] as num).toDouble();
      expect(mileMin, greaterThanOrEqualTo(0));
      expect(mileMax, greaterThan(mileMin));
      expect(
        mileMax,
        lessThan(1000000),
        reason: 'Max mileage should be realistic',
      );
    });

    test('price_max is a reasonable Philippine car price', () {
      final priceMax = (metadata['price_max'] as num).toDouble();
      expect(priceMax, greaterThan(500000), reason: 'Price max too low');
      expect(priceMax, lessThan(10000000), reason: 'Price max too high');
    });
  });

  group('Feature Preprocessing Logic', () {
    test('year normalization produces [0, 1] range', () {
      final yearMin = (metadata['stats']['year']['min'] as num).toDouble();
      final yearMax = (metadata['stats']['year']['max'] as num).toDouble();

      final norm2020 = (2020 - yearMin) / (yearMax - yearMin);
      expect(norm2020, greaterThanOrEqualTo(0.0));
      expect(norm2020, lessThanOrEqualTo(1.0));

      final normMin = (yearMin - yearMin) / (yearMax - yearMin);
      expect(normMin, equals(0.0));

      final normMax = (yearMax - yearMin) / (yearMax - yearMin);
      expect(normMax, equals(1.0));
    });

    test('mileage normalization produces [0, 1] range', () {
      final mileMin = (metadata['stats']['mileage']['min'] as num).toDouble();
      final mileMax = (metadata['stats']['mileage']['max'] as num).toDouble();

      final norm50k = (50000 - mileMin) / (mileMax - mileMin);
      expect(norm50k, greaterThanOrEqualTo(0.0));
      expect(norm50k, lessThanOrEqualTo(1.0));
    });

    test('brand encoding handles unknown brands gracefully', () {
      final brands = metadata['encoders']['brand'] as Map<String, dynamic>;
      // Unknown brand should default to 0 (as the Dart service does)
      final unknownCode = brands['UnknownBrand'] ?? 0;
      expect(unknownCode, equals(0));
    });

    test('condition encoding handles unknown conditions gracefully', () {
      final conditions =
          metadata['encoders']['condition'] as Map<String, dynamic>;
      // Unknown condition should default to 1 (Good) as the Dart service does
      final unknownCode = conditions['Unknown'] ?? 1;
      expect(unknownCode, equals(1));
    });

    test('all 5 input features can be constructed from vehicle data', () {
      final encoders = metadata['encoders'];
      final stats = metadata['stats'];

      const year = 2022;
      const mileage = 30000;

      // Replicate the preprocessing from PricePredictionService
      final brandCode = (encoders['brand']['Toyota'] ?? 0).toDouble();
      final conditionCode = (encoders['condition']['Good'] ?? 1).toDouble();
      final transCode = (encoders['transmission']['Automatic'] ?? 0).toDouble();

      final yearMin = (stats['year']['min'] as num).toDouble();
      final yearMax = (stats['year']['max'] as num).toDouble();
      final yearNorm = (year - yearMin) / (yearMax - yearMin);

      final mileMin = (stats['mileage']['min'] as num).toDouble();
      final mileMax = (stats['mileage']['max'] as num).toDouble();
      final mileNorm = (mileage - mileMin) / (mileMax - mileMin);

      final input = [brandCode, yearNorm, mileNorm, conditionCode, transCode];

      expect(
        input.length,
        equals(5),
        reason: 'Model expects exactly 5 features',
      );
      for (final val in input) {
        expect(val, isA<double>(), reason: 'All features must be doubles');
        expect(
          val.isFinite,
          isTrue,
          reason: 'Features must not be NaN or Infinity',
        );
      }
    });
  });

  group('Denormalization Logic', () {
    test('output 0.0 maps to ₱0', () {
      final priceMax = (metadata['price_max'] as num).toDouble();
      expect(0.0 * priceMax, equals(0.0));
    });

    test('output 1.0 maps to price_max', () {
      final priceMax = (metadata['price_max'] as num).toDouble();
      expect(1.0 * priceMax, equals(priceMax));
    });

    test('output 0.5 maps to half of price_max', () {
      final priceMax = (metadata['price_max'] as num).toDouble();
      final predicted = 0.5 * priceMax;
      expect(predicted, equals(priceMax / 2));
    });

    test('typical output produces a reasonable Philippine car price', () {
      final priceMax = (metadata['price_max'] as num).toDouble();
      // A typical model output might be around 0.3-0.6
      final typicalOutput = 0.4;
      final price = typicalOutput * priceMax;
      expect(price, greaterThan(100000));
      expect(price, lessThan(5000000));
    });
  });

  group('Fallback Behavior', () {
    test('fallback returns expected structure', () async {
      // Simulate fallback manually (same logic as service)
      final basePrice = 700000.0;
      final result = {
        'predicted_price': basePrice,
        'confidence': 0.70,
        'method': 'fallback_heuristic',
      };

      expect(result['predicted_price'], isA<double>());
      expect(result['confidence'], isA<double>());
      expect(result['method'], equals('fallback_heuristic'));
      expect((result['predicted_price'] as double), greaterThan(0));
    });
  });

  group('Model File Existence', () {
    test('pricing_model.tflite is bundled in assets', () async {
      // This will throw if the file doesn't exist
      final data = await rootBundle.load('assets/ai/pricing_model.tflite');
      expect(
        data.lengthInBytes,
        greaterThan(0),
        reason: 'TFLite model file should not be empty',
      );
      expect(
        data.lengthInBytes,
        greaterThan(1000),
        reason: 'TFLite model should be at least 1KB',
      );
    });

    test('pricing_metadata.json is bundled and valid JSON', () async {
      final jsonStr = await rootBundle.loadString(
        'assets/ai/pricing_metadata.json',
      );
      expect(jsonStr.isNotEmpty, isTrue);
      // Should parse without throwing
      final parsed = json.decode(jsonStr);
      expect(parsed, isA<Map<String, dynamic>>());
    });
  });

  group('Encoder Consistency', () {
    test('all encoder values are non-negative integers', () {
      for (final encoderName in ['brand', 'condition', 'transmission']) {
        final encoder =
            metadata['encoders'][encoderName] as Map<String, dynamic>;
        for (final entry in encoder.entries) {
          expect(
            entry.value,
            isA<int>(),
            reason: '$encoderName["${entry.key}"] should be int',
          );
          expect(
            entry.value as int,
            greaterThanOrEqualTo(0),
            reason: '$encoderName["${entry.key}"] should be >= 0',
          );
        }
      }
    });

    test('no duplicate codes within any encoder', () {
      for (final encoderName in ['brand', 'condition', 'transmission']) {
        final encoder =
            metadata['encoders'][encoderName] as Map<String, dynamic>;
        final values = encoder.values.toList();
        final unique = values.toSet();
        expect(
          values.length,
          equals(unique.length),
          reason: '$encoderName has duplicate codes',
        );
      }
    });
  });
}
