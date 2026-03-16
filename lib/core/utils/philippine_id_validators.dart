/// Utility class for validating Philippine Government IDs
class PhilippineIdValidator {
  /// Validates Philippine National ID (PhilSys Card Number - PCN)
  /// Format: 16 digits, ####-####-####-####
  /// Note: Uses PCN instead of PSN per Philippine Data Privacy Act compliance
  static bool validateNationalId(String idNumber) {
    // Remove hyphens and spaces for checking length and digits
    final cleanId = idNumber.replaceAll(RegExp(r'[\s-]'), '');

    // Must be exactly 16 digits
    if (!RegExp(r'^\d{16}$').hasMatch(cleanId)) return false;

    // Optional: Check if input matches strict format with hyphens if provided
    if (idNumber.contains('-')) {
      return RegExp(r'^\d{4}-\d{4}-\d{4}-\d{4}$').hasMatch(idNumber);
    }

    return true;
  }

  /// Validates Secondary IDs based on type
  static bool validateSecondaryId(String idNumber, String type) {
    final cleanType = type.toLowerCase().trim();
    final cleanId = idNumber.trim(); // Keep hyphens for strict format check

    if (cleanType.contains('driver') || cleanType.contains('license')) {
      return _validateDriversLicense(cleanId);
    } else if (cleanType.contains('passport')) {
      return _validatePassport(cleanId);
    } else if (cleanType.contains('sss')) {
      return _validateSSS(cleanId);
    } else if (cleanType.contains('tin') || cleanType.contains('tax')) {
      return _validateTIN(cleanId);
    } else if (cleanType.contains('philhealth')) {
      return _validatePhilHealth(cleanId);
    } else if (cleanType.contains('prc')) {
      return _validatePRC(cleanId);
    } else if (cleanType.contains('postal')) {
      return _validatePostalId(cleanId);
    } else if (cleanType.contains('voter')) {
      return _validateVotersId(cleanId);
    } else if (cleanType.contains('umid') || cleanType.contains('gsis')) {
      return _validateUMID(cleanId);
    } else if (cleanType.contains('pwd')) {
      return _validatePWD(cleanId);
    } else if (cleanType.contains('senior')) {
      return _validateSeniorCitizen(cleanId);
    }

    // Default fallback: non-empty and at least 5 chars
    return cleanId.length >= 5;
  }

  // --- Specific Validators ---

  /// Driver's License: A12-34-567890
  /// Format: 1 Letter + 2 Digits - 2 Digits - 6 Digits
  static bool _validateDriversLicense(String id) {
    final clean = id.replaceAll('-', '');
    return RegExp(r'^[A-Z]\d{10}$').hasMatch(clean) ||
        RegExp(r'^[A-Z]\d{2}-\d{2}-\d{6}$').hasMatch(id);
  }

  /// Passport - 3 formats:
  /// New ePassport (2026+): AA1234567 (2 letters + 7 digits)
  /// Legacy ePassport (2016-2026): P1234567A (letter + 7 digits + letter)
  /// Older biometric: AA1234567 (2 letters + 7 digits)
  /// Combined: ^(?:[A-Z]{2}[0-9]{7}|[A-Z][0-9]{7}[A-Z])$
  static bool _validatePassport(String id) {
    return RegExp(r'^[A-Z]{2}\d{7}$').hasMatch(id) ||
        RegExp(r'^[A-Z]\d{7}[A-Z]$').hasMatch(id);
  }

  /// SSS: XX-XXXXXXX-X (10 digits, hyphens optional)
  static bool _validateSSS(String id) {
    final clean = id.replaceAll('-', '');
    return RegExp(r'^\d{10}$').hasMatch(clean) ||
        RegExp(r'^\d{2}-?\d{7}-?\d$').hasMatch(id);
  }

  /// TIN: XXX-XXX-XXX-000 (9 to 12 digits)
  static bool _validateTIN(String id) {
    final clean = id.replaceAll('-', '');
    return RegExp(r'^\d{9,12}$').hasMatch(clean) ||
        RegExp(r'^\d{3}-\d{3}-\d{3}-\d{3}$').hasMatch(id);
  }

  /// PhilHealth: XX-XXXXXXXXX-X (12 digits)
  static bool _validatePhilHealth(String id) {
    final clean = id.replaceAll('-', '');
    return RegExp(r'^\d{12}$').hasMatch(clean) ||
        RegExp(r'^\d{2}-\d{9}-\d{1}$').hasMatch(id);
  }

  /// PRC: 7 digits
  static bool _validatePRC(String id) {
    return RegExp(r'^\d{7}$').hasMatch(id);
  }

  /// Postal ID: XX-XX-XXXXXXX (2+2+7 = 11 digits, hyphens optional)
  static bool _validatePostalId(String id) {
    final clean = id.replaceAll(RegExp(r'[\s-]'), '');
    return RegExp(r'^\d{11}$').hasMatch(clean) ||
        RegExp(r'^\d{2}-\d{2}-\d{7}$').hasMatch(id);
  }

  /// Voter's ID (COMELEC): XXXX-XXXX-XXXX (12 digits, hyphens optional)
  static bool _validateVotersId(String id) {
    final clean = id.replaceAll('-', '');
    return RegExp(r'^\d{12}$').hasMatch(clean) ||
        RegExp(r'^\d{4}-?\d{4}-?\d{4}$').hasMatch(id);
  }

  /// UMID (CRN): XXXX-XXXXXXX-X (4+7+1 = 12 digits)
  static bool _validateUMID(String id) {
    final clean = id.replaceAll('-', '');
    return RegExp(r'^\d{12}$').hasMatch(clean) ||
        RegExp(r'^\d{4}-\d{7}-\d$').hasMatch(id);
  }

  /// PWD ID: RR-PP-CC-NNNNNNN (2+2+2+5-7 = 11-13 digits)
  static bool _validatePWD(String id) {
    final clean = id.replaceAll('-', '');
    return RegExp(r'^\d{11,13}$').hasMatch(clean) ||
        RegExp(r'^\d{2}-\d{2}-\d{2}-\d{5,7}$').hasMatch(id);
  }

  /// Senior Citizen (OSCA): RR-PP-CC-NNNNNNN (2+2+2+5-7 = 11-13 digits)
  static bool _validateSeniorCitizen(String id) {
    final clean = id.replaceAll('-', '');
    return RegExp(r'^\d{11,13}$').hasMatch(clean) ||
        RegExp(r'^\d{2}-\d{2}-\d{2}-\d{5,7}$').hasMatch(id);
  }
}
