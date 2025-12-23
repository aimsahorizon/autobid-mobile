import '../entities/kyc_document_entity.dart';
import '../repositories/kyc_repository.dart';

class GetKycDocumentUseCase {
  final KycRepository _repository;

  GetKycDocumentUseCase(this._repository);

  Future<KycDocumentEntity> call(String kycDocumentId) async {
    return await _repository.getKycDocument(kycDocumentId);
  }
}
