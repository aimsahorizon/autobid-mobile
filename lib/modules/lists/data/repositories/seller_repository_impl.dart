import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import '../../domain/entities/seller_listing_entity.dart';
import '../../domain/entities/listing_draft_entity.dart';
import '../../domain/repositories/seller_repository.dart';
import '../datasources/listing_supabase_datasource.dart';

class SellerRepositoryImpl implements SellerRepository {
  final ListingSupabaseDataSource dataSource;

  SellerRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, Map<ListingStatus, List<SellerListingEntity>>>>
  getSellerListings(String sellerId) async {
    try {
      final Map<ListingStatus, List<SellerListingEntity>> result = {};

      // Load each status independently - if one fails, others can still load

      // 1. Drafts
      try {
        final drafts = await dataSource.getSellerDrafts(sellerId);
        result[ListingStatus.draft] = drafts
            .map(
              (d) => SellerListingEntity(
                id: d.id,
                imageUrl: d.photoUrls?.values.firstOrNull?.firstOrNull ?? '',
                year: d.year ?? 0,
                make: d.brand ?? 'Unknown',
                model: d.model ?? 'Unknown',
                status: ListingStatus.draft,
                startingPrice: d.startingPrice ?? 0,
                totalBids: 0,
                watchersCount: 0,
                viewsCount: 0,
                createdAt: d.lastSaved,
              ),
            )
            .toList();
      } catch (e) {
        debugPrint('Error loading drafts: $e');
        result[ListingStatus.draft] = [];
      }

      // 2. Pending
      try {
        final pending = await dataSource.getPendingListings(sellerId);
        result[ListingStatus.pending] = pending
            .map((l) => l.toSellerListingEntity())
            .toList();
      } catch (e) {
        debugPrint('Error loading pending listings: $e');
        result[ListingStatus.pending] = [];
      }

      // 3. Approved
      try {
        final approved = await dataSource.getApprovedListings(sellerId);
        result[ListingStatus.approved] = approved
            .map((l) => l.toSellerListingEntity())
            .toList();
      } catch (e) {
        debugPrint('Error loading approved listings: $e');
        result[ListingStatus.approved] = [];
      }

      // 4. Scheduled
      try {
        final scheduled = await dataSource.getScheduledListings(sellerId);
        result[ListingStatus.scheduled] = scheduled
            .map((l) => l.toSellerListingEntity())
            .toList();
      } catch (e) {
        debugPrint('Error loading scheduled listings: $e');
        result[ListingStatus.scheduled] = [];
      }

      // 5. Active
      try {
        final active = await dataSource.getActiveListings(sellerId);
        result[ListingStatus.active] = active
            .map((l) => l.toSellerListingEntity())
            .toList();
      } catch (e) {
        debugPrint('Error loading active listings: $e');
        result[ListingStatus.active] = [];
      }

      // 6. Ended
      try {
        final ended = await dataSource.getEndedListings(sellerId);
        result[ListingStatus.ended] = ended
            .map((l) => l.toSellerListingEntity())
            .toList();
      } catch (e) {
        debugPrint('Error loading ended listings: $e');
        result[ListingStatus.ended] = [];
      }

      // 7. Cancelled
      try {
        final cancelled = await dataSource.getCancelledListings(sellerId);
        result[ListingStatus.cancelled] = cancelled
            .map((l) => l.toSellerListingEntity())
            .toList();
      } catch (e) {
        debugPrint('Error loading cancelled listings: $e');
        result[ListingStatus.cancelled] = [];
      }

      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ListingDraftEntity>>> getSellerDrafts(
    String sellerId,
  ) async {
    try {
      final drafts = await dataSource.getSellerDrafts(sellerId);
      return Right(drafts);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ListingDraftEntity?>> getDraft(String draftId) async {
    try {
      final draft = await dataSource.getDraft(draftId);
      return Right(draft);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ListingDraftEntity>> createDraft(
    String sellerId,
  ) async {
    try {
      final draft = await dataSource.createDraft(sellerId);
      return Right(draft);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveDraft(ListingDraftEntity draft) async {
    try {
      await dataSource.saveDraft(draft);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDraft(String draftId) async {
    try {
      await dataSource.deleteDraft(draftId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markDraftComplete(String draftId) async {
    try {
      await dataSource.markDraftComplete(draftId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> submitListing(String draftId) async {
    try {
      final auctionId = await dataSource.submitListing(draftId);
      return Right(auctionId);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadPhoto({
    required String userId,
    required String listingId,
    required String category,
    required File imageFile,
  }) async {
    try {
      final url = await dataSource.uploadPhoto(
        userId: userId,
        listingId: listingId,
        category: category,
        imageFile: imageFile,
      );
      return Right(url);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadDeedOfSale({
    required String userId,
    required String listingId,
    required File documentFile,
  }) async {
    try {
      final url = await dataSource.uploadDeedOfSale(
        userId: userId,
        listingId: listingId,
        documentFile: documentFile,
      );
      return Right(url);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDeedOfSale(String documentUrl) async {
    try {
      await dataSource.deleteDeedOfSale(documentUrl);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelListing(String auctionId) async {
    try {
      await dataSource.cancelListing(auctionId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<void> streamSellerListings(String sellerId) {
    return dataSource.streamSellerListings(sellerId);
  }
}
