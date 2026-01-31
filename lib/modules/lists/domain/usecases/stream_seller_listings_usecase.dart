import '../../domain/repositories/seller_repository.dart';

class StreamSellerListingsUseCase {
  final SellerRepository repository;

  StreamSellerListingsUseCase(this.repository);

  Stream<void> call(String sellerId) {
    return repository.streamSellerListings(sellerId);
  }
}
