import '../../domain/entities/account_status_entity.dart';

/// Remote data source interface for guest operations
abstract class GuestRemoteDataSource {
  /// Check account status by email or username
  Future<AccountStatusEntity?> checkAccountStatus(String identifier);

  /// Get limited auction listings for guest browse
  Future<List<Map<String, dynamic>>> getGuestAuctionListings({
    int limit = 20,
    int offset = 0,
  });

  /// Submit a KYC appeal for a rejected user
  Future<void> submitKycAppeal(String userId, String appealReason);
}
