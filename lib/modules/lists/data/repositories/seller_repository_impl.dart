import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/core/network/network_info.dart';
import '../../domain/entities/seller_listing_entity.dart';
import '../../domain/entities/listing_draft_entity.dart';
import '../../domain/repositories/seller_repository.dart';
import '../datasources/listing_supabase_datasource.dart';

class SellerRepositoryImpl implements SellerRepository {
  final ListingSupabaseDataSource dataSource;
  final NetworkInfo networkInfo;

  SellerRepositoryImpl(this.dataSource, this.networkInfo);

  @override
  Future<Either<Failure, Map<ListingStatus, List<SellerListingEntity>>>>
  getSellerListings(String sellerId) async {
    if (!await networkInfo.isConnected) {
      // TODO: Implement local caching to return cached data
      return const Left(NetworkFailure('No internet connection'));
    }
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
        final activeModels = await dataSource.getActiveListings(sellerId);
        final activeEntities = activeModels
            .map((l) => l.toSellerListingEntity())
            .toList();

        // Filter expired listings from active
        final now = DateTime.now();
        final expiredListings = activeEntities.where((l) {
          return l.endTime != null && l.endTime!.isBefore(now);
        }).toList();

        // Keep only truly active listings
        result[ListingStatus.active] = activeEntities.where((l) {
          return l.endTime == null || l.endTime!.isAfter(now);
        }).toList();

        // 6. Ended
        try {
          final endedModels = await dataSource.getEndedListings(sellerId);
          final endedEntities = endedModels
              .map((l) => l.toSellerListingEntity())
              .toList();
          
          // Add DB-ended listings
          result[ListingStatus.ended] = endedEntities;

          // Add client-detected expired listings to Ended tab
          // We must create new entities with updated status
          final convertedExpired = expiredListings.map((l) {
            return SellerListingEntity(
              id: l.id,
              imageUrl: l.imageUrl,
              year: l.year,
              make: l.make,
              model: l.model,
              status: ListingStatus.ended, // Force status to ended
              startingPrice: l.startingPrice,
              startTime: l.startTime,
              currentBid: l.currentBid,
              reservePrice: l.reservePrice,
              totalBids: l.totalBids,
              watchersCount: l.watchersCount,
              viewsCount: l.viewsCount,
              createdAt: l.createdAt,
              endTime: l.endTime,
              winnerName: l.winnerName,
              soldPrice: l.soldPrice,
              sellerId: l.sellerId,
              transactionId: l.transactionId,
            );
          }).toList();

          result[ListingStatus.ended]!.addAll(convertedExpired);
          
          // Sort ended list by end time (most recent first)
          result[ListingStatus.ended]!.sort((a, b) {
            final aTime = a.endTime ?? DateTime(0);
            final bTime = b.endTime ?? DateTime(0);
            return bTime.compareTo(aTime);
          });

        } catch (e) {
          debugPrint('Error loading ended listings: $e');
          // If DB fetch fails, at least show the locally expired ones
          result[ListingStatus.ended] = expiredListings.map((l) {
             return SellerListingEntity(
              id: l.id,
              imageUrl: l.imageUrl,
              year: l.year,
              make: l.make,
              model: l.model,
              status: ListingStatus.ended,
              startingPrice: l.startingPrice,
              startTime: l.startTime,
              currentBid: l.currentBid,
              reservePrice: l.reservePrice,
              totalBids: l.totalBids,
              watchersCount: l.watchersCount,
              viewsCount: l.viewsCount,
              createdAt: l.createdAt,
              endTime: l.endTime,
              winnerName: l.winnerName,
              soldPrice: l.soldPrice,
              sellerId: l.sellerId,
              transactionId: l.transactionId,
            );
          }).toList();
        }
      } catch (e) {
        debugPrint('Error loading active listings: $e');
        result[ListingStatus.active] = [];
        // Ensure ended list is initialized if active failed entirely
        if (!result.containsKey(ListingStatus.ended)) {
           result[ListingStatus.ended] = [];
        }
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
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final drafts = await dataSource.getSellerDrafts(sellerId);
      return Right(drafts);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ListingDraftEntity?>> getDraft(String draftId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
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
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final draft = await dataSource.createDraft(sellerId);
      return Right(draft);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveDraft(ListingDraftEntity draft) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await dataSource.saveDraft(draft);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDraft(String draftId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await dataSource.deleteDraft(draftId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markDraftComplete(String draftId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await dataSource.markDraftComplete(draftId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> submitListing(String draftId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
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
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
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
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
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
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await dataSource.deleteDeedOfSale(documentUrl);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelListing(String auctionId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await dataSource.cancelListing(auctionId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<void> streamSellerListings(String sellerId) {
    // Streams might need different handling (e.g. emit error or stop)
    // But Supabase stream handles reconnection.
    // For now, let it be.
    return dataSource.streamSellerListings(sellerId);
  }

  @override
  Future<bool> isPlateNumberUnique(String sellerId, String plateNumber) async {
    if (!await networkInfo.isConnected) {
      // Cannot verify online, assume unsafe or throw?
      // Validation UseCase catches errors and returns message.
      throw Exception('No internet connection');
    }
    try {
      return await dataSource.isPlateUnique(sellerId, plateNumber);
    } catch (e) {
      rethrow;
    }
  }
}
