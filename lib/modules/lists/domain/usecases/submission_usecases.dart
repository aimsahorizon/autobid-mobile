import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import '../entities/listing_draft_entity.dart';
import '../repositories/seller_repository.dart';

class SaveDraftUseCase {
  final SellerRepository repository;
  SaveDraftUseCase(this.repository);
  Future<Either<Failure, void>> call(ListingDraftEntity draft) => repository.saveDraft(draft);
}

class DeleteDraftUseCase {
  final SellerRepository repository;
  DeleteDraftUseCase(this.repository);
  Future<Either<Failure, void>> call(String draftId) => repository.deleteDraft(draftId);
}

class SubmitListingUseCase {
  final SellerRepository repository;
  SubmitListingUseCase(this.repository);
  Future<Either<Failure, String>> call(String draftId) => repository.submitListing(draftId);
}

class CancelListingUseCase {
  final SellerRepository repository;
  CancelListingUseCase(this.repository);
  Future<Either<Failure, void>> call(String auctionId) => repository.cancelListing(auctionId);
}
