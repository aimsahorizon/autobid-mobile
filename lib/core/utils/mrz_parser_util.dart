/// Utility to parse Machine Readable Zones (MRZ) from Passports
class MrzParserUtil {
  /// Parses standard TD3 MRZ (Passport)
  /// Returns a map of {lastName, firstName, idNumber, birthDate, expiryDate, sex}
  static Map<String, String?> parse(String text) {
    final lines = text
        .split('')
        .map((l) => l.trim().replaceAll(' ', '')) // Remove spaces/trim
        .where(
          (l) => l.length >= 44 && l.contains('<'),
        ) // TD3 lines are 44 chars
        .toList();

    if (lines.length < 2) return {};

    // Find the lines
    String? line1;
    String? line2;

    for (var l in lines) {
      if (l.startsWith('P'))
        line1 = l;
      else if (RegExp(r'^[A-Z0-9]').hasMatch(l) && l.contains('PHL'))
        line2 = l;
    }

    if (line1 == null || line2 == null) return {};

    try {
      return _parseTD3(line1, line2);
    } catch (e) {
      // Fallback or partial parse
      return {};
    }
  }

  static Map<String, String?> _parseTD3(String l1, String l2) {
    // Line 1: P<PHLSURNAME<<GIVEN<NAMES<<<<<<<<<<<<<<<<<
    // Strip prefix 'P<PHL' (5 chars)
    // Actually country code is index 2-5.

    // Extract Names
    // Format: P<CCC(Surname)<<(Given Names)<
    final nameSection = l1.substring(5);
    final parts = nameSection.split('<<');

    String lastName = parts[0].replaceAll('<', ' ').trim();
    String firstName = parts.length > 1
        ? parts[1].replaceAll('<', ' ').trim()
        : '';

    // Line 2: (PassportNo)C (DOB)C (Sex) (Expiry)C ...
    // Indices (TD3 standard):
    // 0-9: Passport No
    // 13-19: DOB (YYMMDD)
    // 20: Sex (M/F)
    // 21-27: Expiry (YYMMDD)

    String idNumber = l2.substring(0, 9).replaceAll('<', '');

    String dobRaw = l2.substring(13, 19);
    String dob = _formatDate(dobRaw);

    String sex = l2.substring(20, 21);

    // String expiryRaw = l2.substring(21, 27);
    // String expiry = _formatDate(expiryRaw);

    return {
      'lastName': lastName,
      'firstName': firstName,
      'idNumber': idNumber,
      'dateOfBirth': dob,
      'sex': sex,
    };
  }

  // Convert YYMMDD to YYYY-MM-DD
  static String _formatDate(String yymmdd) {
    if (yymmdd.length != 6) return yymmdd;
    try {
      int year = int.parse(yymmdd.substring(0, 2));
      String month = yymmdd.substring(2, 4);
      String day = yymmdd.substring(4, 6);

      // Pivot year 2000 assumption
      // If year > current year (last 2 digits) + 10, it's probably 19xx
      // But for DOB, it's almost always 19xx or 20xx.
      // Simple heuristic: year > 30 ? 19xx : 20xx
      int fullYear = year > 30 ? 1900 + year : 2000 + year;

      return '$fullYear-$month-$day';
    } catch (e) {
      return yymmdd;
    }
  }
}
