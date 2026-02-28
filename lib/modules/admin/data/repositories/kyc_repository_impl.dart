import 'package:autobid_mobile/core/network/network_info.dart';
import '../../domain/entities/kyc_document_entity.dart';
import '../../domain/entities/kyc_stats_entity.dart';
import '../../domain/repositories/kyc_repository.dart';
import '../datasources/kyc_supabase_datasource.dart';

class KycRepositoryImpl implements KycRepository {
  final KycSupabaseDataSource _dataSource;
  final NetworkInfo networkInfo;

  KycRepositoryImpl(this._dataSource, this.networkInfo);

  @override
  Future<KycStatsEntity> getKycStats() async {
    if (!await networkInfo.isConnected) {
      throw Exception('No internet connection');
    }
    return await _dataSource.getKycStats();
  }

  @override
  Future<List<KycDocumentEntity>> getKycSubmissions({String? status}) async {
    if (!await networkInfo.isConnected) {
      throw Exception('No internet connection');
    }
    return await _dataSource.getKycSubmissions(status: status);
  }

  @override
  Future<List<KycDocumentEntity>> getPendingKycSubmissions() async {
    if (!await networkInfo.isConnected) {
      throw Exception('No internet connection');
    }
    return await _dataSource.getPendingKycSubmissions();
  }

  @override
  Future<KycDocumentEntity> getKycDocument(String kycDocumentId) async {
    if (!await networkInfo.isConnected) {
      throw Exception('No internet connection');
    }
    return await _dataSource.getKycDocument(kycDocumentId);
  }

  @override
  Future<void> approveKyc(String kycDocumentId, {String? notes}) async {
    if (!await networkInfo.isConnected) {
      throw Exception('No internet connection');
    }
    await _dataSource.approveKyc(kycDocumentId, notes: notes);
  }

  @override
  Future<void> rejectKyc(
    String kycDocumentId,
    String reason, {
    String? notes,
  }) async {
    if (!await networkInfo.isConnected) {
      throw Exception('No internet connection');
    }
    await _dataSource.rejectKyc(kycDocumentId, reason, notes: notes);
  }

  @override
  Future<void> assignKycToAdmin(String kycDocumentId, String adminId) async {
    if (!await networkInfo.isConnected) {
      throw Exception('No internet connection');
    }
    await _dataSource.assignKycToAdmin(kycDocumentId, adminId);
  }

  @override
  Future<String> getDocumentUrl(String filePath) async {
    if (!await networkInfo.isConnected) {
      throw Exception('No internet connection');
    }
    return await _dataSource.getDocumentUrl(filePath);
  }
}
