import '../entities/kyc_stats_entity.dart';
import '../repositories/kyc_repository.dart';

class GetKycStatsUseCase {
  final KycRepository _repository;

  GetKycStatsUseCase(this._repository);

  Future<KycStatsEntity> call() async {
    return await _repository.getKycStats();
  }
}
