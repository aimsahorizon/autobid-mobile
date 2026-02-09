import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../utils/id_parser_util.dart';

/// Data extracted from ID documents by AI
class ExtractedIdData {
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final DateTime? dateOfBirth;
  final String? sex;
  final String? address;
  final String? province;
  final String? city;
  final String? barangay;
  final String? zipCode;
  final String? idNumber;

  const ExtractedIdData({
    this.firstName,
    this.middleName,
    this.lastName,
    this.dateOfBirth,
    this.sex,
    this.address,
    this.province,
    this.city,
    this.barangay,
    this.zipCode,
    this.idNumber,
  });

  bool get hasData =>
      firstName != null ||
      middleName != null ||
      lastName != null ||
      dateOfBirth != null ||
      sex != null ||
      address != null ||
      idNumber != null;
}

/// Abstract interface for ID extraction service
abstract class IAiIdExtractionService {
  Future<ExtractedIdData> extractFromNationalId({
    required File frontImage,
    File? backImage,
  });

  Future<ExtractedIdData> extractFromSecondaryId({
    required File secondaryIdFront,
    File? secondaryIdBack,
    required File nationalIdFront,
    File? nationalIdBack,
  });
  
  void dispose();
}

/// Production AI implementation using Google ML Kit with Spatial Analysis
class ProductionAiIdExtractionService implements IAiIdExtractionService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<ExtractedIdData> extractFromNationalId({
    required File frontImage,
    File? backImage,
  }) async {
    final inputImage = InputImage.fromFile(frontImage);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    
    // Delegate parsing to Utility
    final parsedData = IdParserUtil.parse(recognizedText);
    
    return ExtractedIdData(
      firstName: parsedData['firstName'],
      middleName: parsedData['middleName'],
      lastName: parsedData['lastName'],
      idNumber: parsedData['idNumber'],
      dateOfBirth: _parseDate(parsedData['dateOfBirth']),
    );
  }

  @override
  Future<ExtractedIdData> extractFromSecondaryId({
    required File secondaryIdFront,
    File? secondaryIdBack,
    required File nationalIdFront,
    File? nationalIdBack,
  }) async {
    // Process National ID first (Primary source of truth)
    final nationalInput = InputImage.fromFile(nationalIdFront);
    final nationalResult = await _textRecognizer.processImage(nationalInput);
    final nationalData = IdParserUtil.parse(nationalResult);

    return ExtractedIdData(
      firstName: nationalData['firstName'],
      middleName: nationalData['middleName'],
      lastName: nationalData['lastName'],
      idNumber: nationalData['idNumber'],
      dateOfBirth: _parseDate(nationalData['dateOfBirth']),
    );
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      final clean = dateStr.replaceAll(RegExp(r'[-/]'), '-');
      return DateTime.tryParse(clean);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _textRecognizer.close();
  }
}
