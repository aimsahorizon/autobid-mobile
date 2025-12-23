import '../repositories/kyc_repository.dart';

class RejectKycUseCase {
  final KycRepository _repository;

  RejectKycUseCase(this._repository);

  Future<void> call(
    String kycDocumentId,
    String reason, {
    String? notes,
  }) async {
    await _repository.rejectKyc(kycDocumentId, reason, notes: notes);
  }
}
