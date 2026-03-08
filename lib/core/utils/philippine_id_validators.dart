/// Utility class for validating Philippine Government IDs
class PhilippineIdValidator {
  
  /// Validates Philippine National ID (PhilSys ID)
  /// Format: 12 digits, often XXXX-XXXX-XXXX
  static bool validateNationalId(String idNumber) {
    // Remove hyphens and spaces for checking length and digits
    final cleanId = idNumber.replaceAll(RegExp(r'[\s-]'), '');
    
    // Must be exactly 12 digits
    if (!RegExp(r'^\d{12}$').hasMatch(cleanId)) return false;
    
    // Optional: Check if input matches strict format with hyphens if provided
    if (idNumber.contains('-')) {
      return RegExp(r'^\d{4}-\d{4}-\d{4}$').hasMatch(idNumber);
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
      return _validateUMID(cleanId); // GSIS uses UMID/CRN often
    }

    // Default fallback: non-empty and at least 5 chars
    return cleanId.length >= 5;
  }

  // --- Specific Validators ---

  /// Driver's License: L02-XX-XXXXXX or LXX-XX-XXXXXX
  /// Common pattern: 1 Letter, 2 Digits - 2 Digits - 6 Digits (LXX-XX-XXXXXX)
  static bool _validateDriversLicense(String id) {
    // Official LTO Format: LXX-XX-XXXXXX (Letter, 2 Digits, -, 2 Digits, -, 6 Digits)
    // Also supports old format: NXX-XX-XXXXXX
    // Accept with or without dashes
    final clean = id.replaceAll('-', '');
    return RegExp(r'^[A-Z]\d{2}\d{2}\d{6}$').hasMatch(clean) ||
           RegExp(r'^[A-Z]\d{2}-\d{2}-\d{6}$').hasMatch(id);
  }

  /// Passport: 
  /// New: P0000000A (Letter, 7 Digits, Letter) = 9 chars
  /// Old: XX000000 (2 Letters, 6 Digits) = 8 chars
  static bool _validatePassport(String id) {
    return RegExp(r'^[A-Z]\d{7}[A-Z]$').hasMatch(id) || 
           RegExp(r'^[A-Z]{2}\d{6}$').hasMatch(id) ||
           RegExp(r'^[A-Z]{2}\d{7}$').hasMatch(id);
  }

  /// SSS: XX-XXXXXXX-X (10 digits)
  static bool _validateSSS(String id) {
    final clean = id.replaceAll('-', '');
    return RegExp(r'^\d{10}$').hasMatch(clean) ||
           RegExp(r'^\d{2}-\d{7}-\d{1}$').hasMatch(id);
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

  /// Postal ID: 
  /// New: XXXX XXXX XXXX XXXX (16 digits)
  /// Old: XX XXXXXX X (Alpha numeric) - varied.
  /// We enforce newer card format: 16 digits (PRN)
  static bool _validatePostalId(String id) {
    final clean = id.replaceAll(RegExp(r'[\s-]'), '');
    return RegExp(r'^\d{16}$').hasMatch(clean) ||
           RegExp(r'^\d{4}[ -]?\d{4}[ -]?\d{4}[ -]?\d{4}$').hasMatch(id);
  }

  /// Voter's ID: XX-XXXX-XXXX-XXXX (19 digits approx) or varied.
  /// COMELEC varies, but standard is often region-prov-city-seq
  static bool _validateVotersId(String id) {
    // Simple check for reasonable length and numeric/dash structure
    return RegExp(r'^[\d-]{10,25}$').hasMatch(id); 
  }

  /// UMID / GSIS (CRN): 12 digits (XXXX-XXXX-XXXX)
  static bool _validateUMID(String id) {
    final clean = id.replaceAll('-', '');
    return RegExp(r'^\d{12}$').hasMatch(clean) ||
           RegExp(r'^\d{4}-\d{7}-\d{1}$').hasMatch(id) ||
           RegExp(r'^\d{4}-\d{4}-\d{4}$').hasMatch(id);
  }
}
