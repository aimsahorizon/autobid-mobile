import 'dart:io';

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
class MockAiIdExtractionService implements IAiIdExtractionService {
  @override
  Future<ExtractedIdData> extractFromNationalId({
    required File frontImage,
    File? backImage,
  }) async {
    // Simulate AI processing time
    await Future.delayed(const Duration(seconds: 2));

    // Return mock data - minimal extraction from national ID only
    return const ExtractedIdData(
      firstName: 'Juan',
      middleName: 'Dela',
      lastName: 'Cruz',
      dateOfBirth: null, // Not extracted yet
      sex: null,
      idNumber: '1234-5678-9012',
    );
  }

  @override
  Future<ExtractedIdData> extractFromSecondaryId({
    required File secondaryIdFront,
    File? secondaryIdBack,
    required File nationalIdFront,
    File? nationalIdBack,
  }) async {
    // Simulate comprehensive AI processing time
    await Future.delayed(const Duration(seconds: 3));

    // Return comprehensive mock data
    return ExtractedIdData(
      firstName: 'Juan',
      middleName: 'Dela',
      lastName: 'Cruz',
      dateOfBirth: DateTime(1990, 5, 15),
      sex: 'Male',
      address: '123 Sampaguita Street',
      province: 'Metro Manila',
      city: 'Quezon City',
      barangay: 'Barangay Commonwealth',
      zipCode: '1121',
      idNumber: '1234-5678-9012',
    );
  }
}

/// Production AI implementation placeholder
/// Replace with actual AI model integration when ready
class ProductionAiIdExtractionService implements IAiIdExtractionService {
  // TODO: Integrate with actual AI model (e.g., TensorFlow Lite, ML Kit, or cloud API)

  @override
  Future<ExtractedIdData> extractFromNationalId({
    required File frontImage,
    File? backImage,
  }) async {
    // TODO: Implement actual AI extraction
    // Example: Call OCR API, process with ML model, etc.
    throw UnimplementedError('Production AI not yet implemented');
  }

  @override
  Future<ExtractedIdData> extractFromSecondaryId({
    required File secondaryIdFront,
    File? secondaryIdBack,
    required File nationalIdFront,
    File? nationalIdBack,
  }) async {
    // TODO: Implement comprehensive AI extraction
    // Should analyze both IDs for cross-verification
    throw UnimplementedError('Production AI not yet implemented');
  }
}
