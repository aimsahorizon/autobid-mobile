import '../repositories/kyc_repository.dart';

class ApproveKycUseCase {
  final KycRepository _repository;

  ApproveKycUseCase(this._repository);

  Future<void> call(String kycDocumentId, {String? notes}) async {
    await _repository.approveKyc(kycDocumentId, notes: notes);
  }
}
