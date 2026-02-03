import '../repositories/seller_repository.dart';

class ValidatePlateNumberUseCase {
  final SellerRepository repository;

  ValidatePlateNumberUseCase(this.repository);

  Future<String?> call(String plateNumber, String sellerId) async {
    // 1. Format Validation (Philippine Standard - Modern)
    // STRICT FORMAT: LLL DDDD (3 Letters, Space, 4 Digits)
    // Regex explanation:
    // ^[A-Z]{3} \d{4}$ : Exactly 3 letters, MANDATORY space, Exactly 4 digits
    final formatRegex = RegExp(r'^[A-Z]{3} \d{4}$');
    
    // Normalize input: uppercase, trim
    final normalizedPlate = plateNumber.trim().toUpperCase();

    if (!formatRegex.hasMatch(normalizedPlate)) {
      return 'Invalid format. Use 3 letters and 4 digits (e.g., ABC 1234)';
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