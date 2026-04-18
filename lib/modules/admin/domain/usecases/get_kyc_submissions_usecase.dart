import 'package:autobid_mobile/modules/admin/domain/entities/kyc_document_entity.dart';
import 'package:autobid_mobile/modules/admin/domain/repositories/kyc_repository.dart';

class GetKycSubmissionsUseCase {
  final KycRepository _repository;

  GetKycSubmissionsUseCase(this._repository);

  Future<List<KycDocumentEntity>> call({String? status}) async {
    return await _repository.getKycSubmissions(status: status);
  }
}
