import '../repositories/kyc_repository.dart';

class GetDocumentUrlUseCase {
  final KycRepository _repository;

  GetDocumentUrlUseCase(this._repository);

  Future<String> call(String filePath) async {
    return await _repository.getDocumentUrl(filePath);
  }
}
