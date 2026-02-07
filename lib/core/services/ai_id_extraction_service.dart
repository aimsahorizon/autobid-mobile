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
    return _parseWithSpatialAnalysis(recognizedText);
  }

  @override
  Future<ExtractedIdData> extractFromSecondaryId({
    required File secondaryIdFront,
    File? secondaryIdBack,
    required File nationalIdFront,
    File? nationalIdBack,
  }) async {
    final secondaryInput = InputImage.fromFile(secondaryIdFront);
    final nationalInput = InputImage.fromFile(nationalIdFront);

    final secondaryResult = await _textRecognizer.processImage(secondaryInput);
    final nationalResult = await _textRecognizer.processImage(nationalInput);

    final nationalData = _parseWithSpatialAnalysis(nationalResult);
    final secondaryData = _parseWithSpatialAnalysis(secondaryResult);

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

  /// Advanced parsing using spatial relationships (bounding boxes)
  ExtractedIdData _parseWithSpatialAnalysis(RecognizedText recognizedText) {
    final blocks = recognizedText.blocks;

    // 1. Locate Label Blocks
    final lastNameLabel = _findBlockByKeywords(blocks, [
      'last name',
      'surname',
      'family name',
    ]);
    final firstNameLabel = _findBlockByKeywords(blocks, [
      'first name',
      'given name',
    ]);
    final middleNameLabel = _findBlockByKeywords(blocks, ['middle name']);
    final dobLabel = _findBlockByKeywords(blocks, [
      'date of birth',
      'birth date',
      'dob',
    ]);
    final sexLabel = _findBlockByKeywords(blocks, ['sex', 'gender']);
    final addressLabel = _findBlockByKeywords(blocks, ['address']);
    final idLabel = _findBlockByKeywords(blocks, [
      'id no',
      'crn',
      'common reference number',
      'license no',
    ]);

    // 2. Extract Values based on Label Locations
    // Prioritize "Below" then "Right"
    String? lastName = _getValueForLabel(blocks, lastNameLabel);
    String? firstName = _getValueForLabel(blocks, firstNameLabel);
    String? middleName = _getValueForLabel(blocks, middleNameLabel);
    String? dobStr = _getValueForLabel(blocks, dobLabel);
    String? sexStr = _getValueForLabel(blocks, sexLabel);
    String? address = _getValueForLabel(
      blocks,
      addressLabel,
      lookBelow: true,
      linesToCheck: 3,
    );
    String? idNumber = _getValueForLabel(blocks, idLabel);

    // 3. Fallback Heuristics (if labels not found, try Regex or keyword-in-line)
    idNumber ??= _findIdNumberByRegex(recognizedText.text);
    dobStr ??= _findDateByRegex(recognizedText.text);

    // 4. Parse Complex Types
    DateTime? dateOfBirth;
    if (dobStr != null) {
      dateOfBirth = _parseDate(dobStr);
    }

    // 5. Sex Normalization
    String? sex;
    if (sexStr != null) {
      final s = sexStr.toLowerCase();
      if (s.startsWith('m'))
        sex = 'Male';
      else if (s.startsWith('f'))
        sex = 'Female';
    }

    // 6. Cleanup
    firstName = _cleanText(firstName);
    lastName = _cleanText(lastName);
    middleName = _cleanText(middleName);
    address = _cleanText(address);

    return ExtractedIdData(
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      sex: sex,
      address: address,
      idNumber: idNumber,
    );
  }

  /// Finds a text block containing any of the keywords
  TextBlock? _findBlockByKeywords(
    List<TextBlock> blocks,
    List<String> keywords,
  ) {
    for (final block in blocks) {
      final text = block.text.toLowerCase();
      for (final keyword in keywords) {
        if (text.contains(keyword)) {
          return block;
        }
      }
    }
    return null;
  }

  /// Finds the value associated with a label using spatial logic
  /// 1. Look to the RIGHT of the label (same line)
  /// 2. If empty, look BELOW the label (next line)
  String? _getValueForLabel(
    List<TextBlock> blocks,
    TextBlock? labelBlock, {
    bool lookBelow = true,
    int linesToCheck = 1,
  }) {
    if (labelBlock == null) return null;

    final labelRect = labelBlock.boundingBox;

    // Strategy 1: Look Right (Same Y-axis, to the right of X-axis)
    // Tolerance for Y-axis alignment
    final yTolerance = labelRect.height * 0.5;

    TextBlock? rightMatch;
    double minDistanceX = double.infinity;

    for (final block in blocks) {
      if (block == labelBlock) continue;

      final blockRect = block.boundingBox;

      // Check Vertical Alignment (Overlap on Y axis)
      bool isVerticallyAligned =
          (blockRect.top < labelRect.bottom - yTolerance &&
          blockRect.bottom > labelRect.top + yTolerance);

      if (isVerticallyAligned && blockRect.left > labelRect.right) {
        final distance = blockRect.left - labelRect.right;
        if (distance < minDistanceX) {
          minDistanceX = distance;
          rightMatch = block;
        }
      }
    }

    if (rightMatch != null) {
      // If the "Right" match is very close, it's likely the value
      // But verify it's not another label
      return rightMatch.text;
    }

    // Strategy 2: Look Below (Higher Y value, similar X range)
    if (lookBelow) {
      TextBlock? belowMatch;
      double minDistanceY = double.infinity;

      // X tolerance: The value should start roughly where the label starts or slightly before/after
      final xTolerance = 100.0; // Pixels

      for (final block in blocks) {
        if (block == labelBlock) continue;

        final blockRect = block.boundingBox;

        // Check if block is strictly below
        if (blockRect.top > labelRect.bottom) {
          // Check horizontal alignment
          bool isHorizontallyAligned =
              (blockRect.left >= labelRect.left - xTolerance &&
              blockRect.left <= labelRect.right + xTolerance);

          if (isHorizontallyAligned) {
            final distance = blockRect.top - labelRect.bottom;
            // Must be close enough (e.g., within 2 line heights)
            if (distance < labelRect.height * 2.5 && distance < minDistanceY) {
              minDistanceY = distance;
              belowMatch = block;
            }
          }
        }
      }

      if (belowMatch != null) {
        return belowMatch.text;
      }
    }

    return null;
  }

  String? _findIdNumberByRegex(String text) {
    final idPattern = RegExp(r'\d{4}-\d{4}-\d{4}|\d{12}|\d{3}-\d{2}-\d{6}');
    return idPattern.stringMatch(text);
  }

  String? _findDateByRegex(String text) {
    final datePattern = RegExp(
      r'\d{2}[-/]\d{2}[-/]\d{4}|\d{4}[-/]\d{2}[-/]\d{2}',
    );
    return datePattern.stringMatch(text);
  }

  DateTime? _parseDate(String dateStr) {
    try {
      // Normalize separators
      final clean = dateStr.replaceAll(RegExp(r'[-/]'), '-');
      // Try standard parse
      return DateTime.tryParse(clean);
    } catch (_) {
      return null;
    }
  }

  String? _cleanText(String? text) {
    if (text == null) return null;
    // Remove labels from value if caught together (e.g., "Name: John")
    final cleaned = text.replaceAll(
      RegExp(
        r'^(Name|Address|Date|Birth|Sex|Gender)[:\.]?\s*',
        caseSensitive: false,
      ),
      '',
    );
    return cleaned.trim().replaceAll(RegExp(r'[^\w\s\-\.,]'), '');
  }

  void dispose() {
    _textRecognizer.close();
  }
}
