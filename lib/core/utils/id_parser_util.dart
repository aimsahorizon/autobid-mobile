import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Utility to parse raw text blocks from ML Kit into structured ID data.
/// Specialized for Philippine IDs (PhilSys, UMID, Driver's License).
class IdParserUtil {
  
  /// Main parsing entry point
  static Map<String, String?> parse(RecognizedText recognizedText) {
    final blocks = recognizedText.blocks;
    final text = recognizedText.text;

    // 1. Identify ID Type (Optional, helps heuristics)
    final isDriversLicense = text.contains('DRIVER') && text.contains('LICENSE');
    final isPhilSys = text.contains('REPUBLIKA') && text.contains('PILIPINAS');
    
    // 2. Extract Fields
    String? idNumber = _findIdNumber(text);
    String? lastName = _findValueByLabel(blocks, ['Last Name', 'Surname', 'Family Name']);
    String? firstName = _findValueByLabel(blocks, ['First Name', 'Given Name']);
    String? middleName = _findValueByLabel(blocks, ['Middle Name']);
    String? dateOfBirth = _findDateOfBirth(blocks, text);
    
    // 3. Fallbacks for Driver's License (which uses codes sometimes)
    if (isDriversLicense) {
      // Driver's license often puts the ID number prominently at the top or center
      idNumber ??= _findDriversLicenseNumber(text);
    }

    return {
      'idNumber': idNumber,
      'lastName': lastName,
      'firstName': firstName,
      'middleName': middleName,
      'dateOfBirth': dateOfBirth,
    };
  }

  // --- Barcode Logic ---

  /// Parses the raw string from a Driver's License PDF417 barcode
  static Map<String, String?> parseDriverLicenseBarcode(String rawValue) {
    // LTO Format varies but commonly:
    // "D01-23-456789,DELA CRUZ,JUAN,M,1990-01-01,..."
    // or newline separated.
    
    String clean = rawValue.replaceAll('\r', '\n');
    List<String> parts;
    
    if (clean.contains(',')) {
      parts = clean.split(',');
    } else if (clean.contains('\n')) {
      parts = clean.split('\n');
    } else {
      parts = [clean];
    }
    
    parts = parts.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    if (parts.isEmpty) return {};

    // Heuristic: Find the ID Number first (Pattern matching)
    String? idNumber;
    int idIndex = -1;
    
    final idRegex = RegExp(r'[A-Z]\d{2}-\d{2}-\d{6}');
    
    for (int i = 0; i < parts.length; i++) {
      if (idRegex.hasMatch(parts[i])) {
        idNumber = parts[i];
        idIndex = i;
        break;
      }
    }

    if (idNumber == null) return {};

    // Usually Last Name is next, then First, then Middle
    // Index mapping heuristic relative to ID
    try {
      String? lastName = parts.length > idIndex + 1 ? parts[idIndex + 1] : null;
      String? firstName = parts.length > idIndex + 2 ? parts[idIndex + 2] : null;
      String? middleName = parts.length > idIndex + 3 ? parts[idIndex + 3] : null;
      // DOB might be index 4 or further
      String? dob;
      
      // Look for date pattern in subsequent parts
      final dateRegex = RegExp(r'\d{4}-\d{2}-\d{2}');
      for (int i = idIndex + 1; i < parts.length; i++) {
        if (dateRegex.hasMatch(parts[i])) {
          dob = parts[i];
          break;
        }
      }

      return {
        'idNumber': idNumber,
        'lastName': lastName,
        'firstName': firstName,
        'middleName': middleName,
        'dateOfBirth': dob,
      };
    } catch (e) {
      return {'idNumber': idNumber};
    }
  }

  // --- Specialized Finders ---

  static String? _findIdNumber(String text) {
    // PhilSys / UMID / General Patterns
    final patterns = [
      RegExp(r'\d{4}-\d{4}-\d{4}-\d{4}'), // PhilSys (16 digits)
      RegExp(r'\d{4}-\d{7}-\d{1}'),      // UMID (CRN)
      RegExp(r'[A-Z]\d{2}-\d{2}-\d{6}'), // Driver's License (Standard)
    ];

    for (final regex in patterns) {
      final match = regex.firstMatch(text);
      if (match != null) return match.group(0);
    }
    return null;
  }
  
  static String? _findDriversLicenseNumber(String text) {
    // Looks for pattern N01-23-456789 strict
    final regex = RegExp(r'[A-Z]\d{2}-\d{2}-\d{6}');
    return regex.stringMatch(text);
  }

  static String? _findDateOfBirth(List<TextBlock> blocks, String rawText) {
    // 1. Try Spatial Search first
    String? spatialResult = _findValueByLabel(blocks, ['Date of Birth', 'Birth Date', 'DOB']);
    if (spatialResult != null && _isValidDate(spatialResult)) {
      return spatialResult;
    }

    // 2. Regex Search in full text (YYYY/MM/DD or MM/DD/YYYY)
    final datePattern = RegExp(r'\d{4}[-/]\d{2}[-/]\d{2}|\d{2}[-/]\d{2}[-/]\d{4}');
    final matches = datePattern.allMatches(rawText);
    
    for (final m in matches) {
      // Return the first valid looking date that isn't the expiry (usually DOB is earlier)
      // This is a naive heuristic, spatial is better.
      return m.group(0);
    }
    
    return null;
  }

  // --- Spatial Logic ---

  static String? _findValueByLabel(List<TextBlock> blocks, List<String> labels) {
    TextBlock? labelBlock;
    
    // Find the label block
    for (final block in blocks) {
      for (final label in labels) {
        if (block.text.toLowerCase().contains(label.toLowerCase())) {
          labelBlock = block;
          break;
        }
      }
      if (labelBlock != null) break;
    }

    if (labelBlock == null) return null;

    // Strategy: Look Below first (common in IDs), then Right
    final labelRect = labelBlock.boundingBox;
    
    TextBlock? bestCandidate;
    double minDistance = double.infinity;

    for (final block in blocks) {
      if (block == labelBlock) continue;
      
      // Filter noise (too far away)
      // ... (Same spatial logic as previous implementation, simplified here)
      
      final blockRect = block.boundingBox;
      
      // Check "Below"
      if (blockRect.top > labelRect.bottom && 
          blockRect.top < labelRect.bottom + 100 && // Within 100px down
          blockRect.left > labelRect.left - 50 && 
          blockRect.left < labelRect.right + 50) {
            
        final distance = blockRect.top - labelRect.bottom;
        if (distance < minDistance) {
          minDistance = distance;
          bestCandidate = block;
        }
      }
    }
    
    return bestCandidate?.text;
  }

  static bool _isValidDate(String date) {
    // Basic length check
    return date.length >= 8;
  }
}
