import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import '../entities/seller_listing_entity.dart';
import '../entities/listing_draft_entity.dart';

abstract class SellerRepository {
  Future<Either<Failure, Map<ListingStatus, List<SellerListingEntity>>>> getSellerListings(String sellerId);
  Future<Either<Failure, List<ListingDraftEntity>>> getSellerDrafts(String sellerId);
  Future<Either<Failure, ListingDraftEntity?>> getDraft(String draftId);
  Future<Either<Failure, ListingDraftEntity>> createDraft(String sellerId);
  Future<Either<Failure, void>> saveDraft(ListingDraftEntity draft);
  Future<Either<Failure, void>> deleteDraft(String draftId);
  Future<Either<Failure, void>> markDraftComplete(String draftId);
  Future<Either<Failure, String>> submitListing(String draftId);
  Future<Either<Failure, String>> uploadPhoto({required String userId, required String listingId, required String category, required File imageFile});
  Future<Either<Failure, String>> uploadDeedOfSale({required String userId, required String listingId, required File documentFile});
  Future<Either<Failure, void>> deleteDeedOfSale(String documentUrl);
  Future<Either<Failure, void>> cancelListing(String auctionId);
  Stream<void> streamSellerListings(String sellerId);
}
