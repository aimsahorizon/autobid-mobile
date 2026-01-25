import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import '../entities/seller_listing_entity.dart';
import '../repositories/seller_repository.dart';

class GetSellerListingsUseCase {
  final SellerRepository repository;

  GetSellerListingsUseCase(this.repository);

  Future<Either<Failure, Map<ListingStatus, List<SellerListingEntity>>>> call(String sellerId) {
    return repository.getSellerListings(sellerId);
  }
}
