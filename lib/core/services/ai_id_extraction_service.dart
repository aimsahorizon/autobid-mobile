import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

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
      address != null;
}

/// Abstract interface for ID extraction service
/// Allows switching between mock and real AI implementation
abstract class IAiIdExtractionService {
  /// Extract data from National ID
  Future<ExtractedIdData> extractFromNationalId({
    required File frontImage,
    File? backImage,
  });

  /// Extract data from Secondary ID and National ID combined
  /// This is the comprehensive extraction that autofills all fields
  Future<ExtractedIdData> extractFromSecondaryId({
    required File secondaryIdFront,
    File? secondaryIdBack,
    required File nationalIdFront,
    File? nationalIdBack,
  });
}

/// Mock implementation of AI ID extraction service
/// Simulates AI extraction with realistic delays and mock data
// class MockAiIdExtractionService implements IAiIdExtractionService {
//   @override
//   Future<ExtractedIdData> extractFromNationalId({
//     required File frontImage,
//     File? backImage,
//   }) async {
//     // Simulate AI processing time
//     await Future.delayed(const Duration(seconds: 2));

//     // Return mock data - minimal extraction from national ID only
//     return const ExtractedIdData(
//       firstName: 'Juan',
//       middleName: 'Dela',
//       lastName: 'Cruz',
//       dateOfBirth: null, // Not extracted yet
//       sex: null,
//       idNumber: '1234-5678-9012',
//     );
//   }

//   @override
//   Future<ExtractedIdData> extractFromSecondaryId({
//     required File secondaryIdFront,
//     File? secondaryIdBack,
//     required File nationalIdFront,
//     File? nationalIdBack,
//   }) async {
//     // Simulate comprehensive AI processing time
//     await Future.delayed(const Duration(seconds: 3));

//     // Return comprehensive mock data
//     return ExtractedIdData(
//       firstName: 'Juan',
//       middleName: 'Dela',
//       lastName: 'Cruz',
//       dateOfBirth: DateTime(1990, 5, 15),
//       sex: 'Male',
//       address: '123 Sampaguita Street',
//       province: 'Metro Manila',
//       city: 'Quezon City',
//       barangay: 'Barangay Commonwealth',
//       zipCode: '1121',
//       idNumber: '1234-5678-9012',
//     );
//   }
// }

/// Production AI implementation using Google ML Kit (On-Device OCR)
class ProductionAiIdExtractionService implements IAiIdExtractionService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<ExtractedIdData> extractFromNationalId({
    required File frontImage,
    File? backImage,
  }) async {
    final inputImage = InputImage.fromFile(frontImage);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    return _parseTextToData(recognizedText.text);
  }

  @override
  Future<ExtractedIdData> extractFromSecondaryId({
    required File secondaryIdFront,
    File? secondaryIdBack,
    required File nationalIdFront,
    File? nationalIdBack,
  }) async {
    // Process both IDs for better accuracy (merging results)
    final secondaryInput = InputImage.fromFile(secondaryIdFront);
    final nationalInput = InputImage.fromFile(nationalIdFront);

    final secondaryResult = await _textRecognizer.processImage(secondaryInput);
    final nationalResult = await _textRecognizer.processImage(nationalInput);

    // Merge data - prioritizing national ID for core fields
    final nationalData = _parseTextToData(nationalResult.text);
    final secondaryData = _parseTextToData(secondaryResult.text);

    return ExtractedIdData(
      firstName: nationalData.firstName ?? secondaryData.firstName,
      middleName: nationalData.middleName ?? secondaryData.middleName,
      lastName: nationalData.lastName ?? secondaryData.lastName,
      dateOfBirth: nationalData.dateOfBirth ?? secondaryData.dateOfBirth,
      sex: nationalData.sex ?? secondaryData.sex,
      address: nationalData.address ?? secondaryData.address,
      province: nationalData.province ?? secondaryData.province,
      city: nationalData.city ?? secondaryData.city,
      barangay: nationalData.barangay ?? secondaryData.barangay,
      zipCode: nationalData.zipCode ?? secondaryData.zipCode,
      idNumber: nationalData.idNumber ?? secondaryData.idNumber,
    );
  }

  /// Heuristic parsing of OCR text to extract fields
  ExtractedIdData _parseTextToData(String text) {
    String? firstName;
    String? middleName;
    String? lastName;
    DateTime? dateOfBirth;
    String? sex;
    String? address;
    String? idNumber;

    final lines = text.split('\n');

    // Regex patterns
    final datePattern = RegExp(
      r'\d{2}[-/]\d{2}[-/]\d{4}|\d{4}[-/]\d{2}[-/]\d{2}',
    );
    final idPattern = RegExp(
      r'\d{4}-\d{4}-\d{4}|\d{12}|\d{3}-\d{2}-\d{6}',
    ); // Common formats

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final lowerLine = line.toLowerCase();

      // ID Number
      if (idNumber == null && idPattern.hasMatch(line)) {
        idNumber = idPattern.firstMatch(line)?.group(0);
      } else if (lowerLine.contains('id no') || lowerLine.contains('crn')) {
        // Check next line or same line
        if (i + 1 < lines.length && idPattern.hasMatch(lines[i + 1])) {
          idNumber = idPattern.firstMatch(lines[i + 1])?.group(0);
        }
      }

      // Name (Very heuristic - assumes Last Name, First Name format or labeled)
      if (lowerLine.contains('last name') && i + 1 < lines.length) {
        lastName = lines[i + 1].trim();
      }
      if (lowerLine.contains('first name') && i + 1 < lines.length) {
        firstName = lines[i + 1].trim();
      }
      if (lowerLine.contains('middle name') && i + 1 < lines.length) {
        middleName = lines[i + 1].trim();
      }

      // Sex
      if (sex == null) {
        if (lowerLine == 'm' || lowerLine == 'male') sex = 'Male';
        if (lowerLine == 'f' || lowerLine == 'female') sex = 'Female';
        if (lowerLine.contains('sex') || lowerLine.contains('gender')) {
          if (line.contains('M') || line.contains('Male'))
            sex = 'Male';
          else if (line.contains('F') || line.contains('Female'))
            sex = 'Female';
          else if (i + 1 < lines.length) {
            final next = lines[i + 1].trim().toLowerCase();
            if (next == 'm' || next == 'male') sex = 'Male';
            if (next == 'f' || next == 'female') sex = 'Female';
          }
        }
      }

      // Date of Birth
      if (dateOfBirth == null) {
        if (lowerLine.contains('birth') || lowerLine.contains('dob')) {
          // Search in this line or next
          final match =
              datePattern.firstMatch(line) ??
              ((i + 1 < lines.length)
                  ? datePattern.firstMatch(lines[i + 1])
                  : null);
          if (match != null) {
            try {
              // Try parsing YYYY-MM-DD or MM/DD/YYYY - Simplified for demo
              dateOfBirth = DateTime.tryParse(match.group(0)!);
            } catch (_) {}
          }
        }
      }

      // Address
      if (address == null &&
          (lowerLine.contains('address') ||
              lowerLine.contains('subdivision') ||
              lowerLine.contains('barangay'))) {
        // Grab the next 1-2 lines as address
        if (i + 1 < lines.length) {
          address = lines[i + 1];
          if (i + 2 < lines.length && !lines[i + 2].contains(':')) {
            address = '$address ${lines[i + 2]}';
          }
        }
      }
    }

    // Clean up
    if (firstName != null) firstName = _cleanText(firstName);
    if (lastName != null) lastName = _cleanText(lastName);
    if (address != null) address = _cleanText(address);

    return ExtractedIdData(
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      sex: sex,
      address: address,
      idNumber: idNumber,
      // Cannot reliably extract broken down address fields (city, province) without more complex logic
      // leaving them null to be filled manually
    );
  }

  String _cleanText(String text) {
    return text.replaceAll(RegExp(r'[^\w\s\-\.,]'), '').trim();
  }

  void dispose() {
    _textRecognizer.close();
  }
}
