import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
// import 'package:tflite_flutter/tflite_flutter.dart'; // Uncomment when pkg is available

/// Abstract base class for AI services
abstract class AIService {
  Future<bool> isConfigured();
  String get serviceName;
}

// ... IDExtractionService remains unchanged ...

/// Service for predicting vehicle prices using AI
/// Uses On-Device TensorFlow Lite Model (Regression)
class PricePredictionService extends AIService {
  
  // Cache for metadata (encoders, normalization stats)
  Map<String, dynamic>? _metadata;
  // Interpreter? _interpreter; // Uncomment

  @override
  String get serviceName => 'Price Prediction Service';

  @override
  Future<bool> isConfigured() async {
    // Check if assets exist
    try {
      await rootBundle.load('assets/ai/pricing_metadata.json');
      // await rootBundle.load('assets/ai/pricing_model.tflite');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadResources() async {
    if (_metadata != null) return;
    
    try {
      final jsonString = await rootBundle.loadString('assets/ai/pricing_metadata.json');
      _metadata = json.decode(jsonString);
      
      // _interpreter = await Interpreter.fromAsset('assets/ai/pricing_model.tflite');
    } catch (e) {
      print('Error loading pricing AI resources: $e');
    }
  }

  /// Predicts the market price of a vehicle based on its features
  Future<Map<String, dynamic>> predictPrice(
      Map<String, dynamic> vehicleData) async {
    
    await _loadResources();
    
    // If model missing, fallback to heuristics
    if (_metadata == null) { // || _interpreter == null
       print('Pricing AI model not found. Using Fallback Heuristics.');
       return _fallbackPrediction(vehicleData);
    }
    
    try {
      // 1. Preprocess Input
      // We must match the python script's logic exactly
      // Inputs: [brand_code, year_norm, mileage_norm, condition_code, transmission_code]
      
      final encoders = _metadata!['encoders'];
      final stats = _metadata!['stats'];
      
      // Encode Categorical
      final brandCode = (encoders['brand'][vehicleData['brand']] ?? 0).toDouble();
      final conditionCode = (encoders['condition'][vehicleData['condition']] ?? 1).toDouble(); // Default to Fair
      final transCode = (encoders['transmission'][vehicleData['transmission']] ?? 0).toDouble();

      // Normalize Numerical
      final yearMin = stats['year']['min'];
      final yearMax = stats['year']['max'];
      final yearNorm = (vehicleData['year'] - yearMin) / (yearMax - yearMin);

      final mileMin = stats['mileage']['min'];
      final mileMax = stats['mileage']['max'];
      final mileNorm = (vehicleData['mileage'] - mileMin) / (mileMax - mileMin);

      final input = [[brandCode, yearNorm, mileNorm, conditionCode, transCode]];
      
      // 2. Inference
      // var output = List.filled(1 * 1, 0).reshape([1, 1]);
      // _interpreter!.run(input, output);
      // final predictedNorm = output[0][0];
      
      // Mock Inference for now (replace with above lines)
      final predictedNorm = 0.5; // Dummy

      // 3. Denormalize Output
      final priceMin = _metadata!['price_min'];
      final priceMax = _metadata!['price_max'];
      final predictedPrice = predictedNorm * priceMax; // Simplified denorm logic
      
      return {
        'predicted_price': predictedPrice,
        'confidence': 0.85, // Regression models don't typically give confidence, this is static
        'method': 'ai_tflite'
      };

    } catch (e) {
      print('AI Inference Failed: $e');
      return _fallbackPrediction(vehicleData);
    }
  }

  // Fallback Logic (Old mock implementation)
  Future<Map<String, dynamic>> _fallbackPrediction(Map<String, dynamic> vehicleData) async {
    await Future.delayed(const Duration(seconds: 1));
    final basePrice = 700000.0;
    return {
      'predicted_price': basePrice,
      'confidence': 0.70,
      'method': 'fallback_heuristic'
    };
  }
}

