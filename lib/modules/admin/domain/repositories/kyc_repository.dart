import '../entities/kyc_document_entity.dart';
import '../entities/kyc_stats_entity.dart';

abstract class KycRepository {
  Future<KycStatsEntity> getKycStats();

  Future<List<KycDocumentEntity>> getKycSubmissions({String? status});

  Future<List<KycDocumentEntity>> getPendingKycSubmissions();

  Future<KycDocumentEntity> getKycDocument(String kycDocumentId);

  Future<void> approveKyc(String kycDocumentId, {String? notes});

  Future<void> rejectKyc(String kycDocumentId, String reason, {String? notes});

  Future<void> assignKycToAdmin(String kycDocumentId, String adminId);

  Future<String> getDocumentUrl(String filePath);
}
