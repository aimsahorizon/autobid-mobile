import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/lists/domain/entities/seller_listing_entity.dart';
import 'package:autobid_mobile/modules/lists/domain/repositories/seller_repository.dart';

class GetSellerListingsUseCase {
  final SellerRepository repository;

  GetSellerListingsUseCase(this.repository);

  Future<Either<Failure, Map<ListingStatus, List<SellerListingEntity>>>> call(String sellerId) {
    return repository.getSellerListings(sellerId);
  }
}
