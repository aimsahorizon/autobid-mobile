import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import '../entities/listing_draft_entity.dart';
import '../repositories/seller_repository.dart';

class GetSellerDraftsUseCase {
  final SellerRepository repository;
  GetSellerDraftsUseCase(this.repository);
  Future<Either<Failure, List<ListingDraftEntity>>> call(String sellerId) =>
      repository.getSellerDrafts(sellerId);
}

class GetDraftUseCase {
  final SellerRepository repository;
  GetDraftUseCase(this.repository);
  Future<Either<Failure, ListingDraftEntity?>> call(String draftId) =>
      repository.getDraft(draftId);
}

class CreateDraftUseCase {
  final SellerRepository repository;
  CreateDraftUseCase(this.repository);
  Future<Either<Failure, ListingDraftEntity>> call(String sellerId) =>
      repository.createDraft(sellerId);
}

class MarkDraftCompleteUseCase {
  final SellerRepository repository;
  MarkDraftCompleteUseCase(this.repository);
  Future<Either<Failure, void>> call(String draftId) =>
      repository.markDraftComplete(draftId);
}
