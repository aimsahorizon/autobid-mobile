import '../repositories/seller_repository.dart';

class ValidatePlateNumberUseCase {
  final SellerRepository repository;

  ValidatePlateNumberUseCase(this.repository);

  Future<String?> call(String plateNumber, String sellerId) async {
    // 1. Format Validation (Philippine Standard)
    // STRICT FORMAT: LLL DDD or LLL DDDD or LL DDDD (With Space)
    // Regex explanation:
    // ^[A-Z]{2,3} \d{3,4}$ : 2-3 letters, MANDATORY space, 3-4 digits
    final formatRegex = RegExp(r'^[A-Z]{2,3} \d{3,4}$');
    
    // Normalize input: uppercase, trim (internal space preserved if present)
    final normalizedPlate = plateNumber.trim().toUpperCase();

    if (!formatRegex.hasMatch(normalizedPlate)) {
      return 'Invalid format. Use LLL DDD or LLL DDDD (e.g., ABC 1234)';
    }

    // 2. Uniqueness Check via Repository
    try {
      final isUnique = await repository.isPlateNumberUnique(sellerId, normalizedPlate);
      if (!isUnique) {
        return 'This plate number is already listed in your account.';
      }
    } catch (e) {
      // In case of network error, fail safe or return error message?
      // For now, let's treat it as a warning but blocking strictly might be better
      return 'Could not verify plate uniqueness: ${e.toString()}';
    }

    return null; // Valid
  }
}