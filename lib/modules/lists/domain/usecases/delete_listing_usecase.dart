import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/lists/domain/repositories/seller_repository.dart';

class DeleteListingUseCase {
  final SellerRepository repository;

  DeleteListingUseCase(this.repository);

  Future<Either<Failure, void>> call(String auctionId) {
    return repository.deleteListing(auctionId);
  }
}
