import '../../domain/entities/account_status_entity.dart';

/// Remote data source interface for guest operations
abstract class GuestRemoteDataSource {
  /// Check account status by email
  Future<AccountStatusEntity?> checkAccountStatus(String email);

  /// Get limited auction listings for guest browse
  Future<List<Map<String, dynamic>>> getGuestAuctionListings({
    int limit = 20,
    int offset = 0,
  });
}
