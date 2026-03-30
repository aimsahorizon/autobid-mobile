import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/account_status_entity.dart';

/// Repository interface for guest mode operations
abstract class GuestRepository {
  /// Check account status by email or username
  /// Returns status if user exists and has submitted KYC
  Future<Either<Failure, AccountStatusEntity?>> checkAccountStatus(
    String identifier,
  );

  /// Get limited auction listings for guest browse
  /// Returns auctions without sensitive bidder information
  Future<Either<Failure, List<Map<String, dynamic>>>> getGuestAuctionListings({
    int limit = 20,
    int offset = 0,
  });

  /// Submit a KYC appeal for a rejected user
  Future<Either<Failure, void>> submitKycAppeal(
    String userId,
    String appealReason,
  );
}
