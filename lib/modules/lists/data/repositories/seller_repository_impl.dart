import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:async/async.dart';
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

        // Trigger DB update for expired listings (Lazy expiration)
        // This ensures the status in DB actually changes to 'ended'
        for (final listing in expiredListings) {
          dataSource
              .updateListingStatusByName(listing.id, 'ended')
              .then((_) {
                debugPrint(
                  '[SellerRepository] Auto-expired listing: ${listing.id}',
                );
              })
              .catchError((e) {
                debugPrint(
                  '[SellerRepository] Failed to auto-expire listing ${listing.id}: $e',
                );
              });
        }

        // Keep only truly active listings
        result[ListingStatus.active] = activeEntities.where((l) {
          return l.endTime == null || l.endTime!.isAfter(now);
        }).toList();

        // 6. Ended (Only listings awaiting seller decision)
        result[ListingStatus.ended] = [];
        try {
          final endedModels = await dataSource.getEndedListings(sellerId);
          result[ListingStatus.ended]!.addAll(
            endedModels.map((l) => l.toSellerListingEntity()),
          );

          // Add client-detected expired active listings
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

          // Deduplicate by ID
          final uniqueEnded = <String, SellerListingEntity>{};
          for (final item in result[ListingStatus.ended]!) {
            uniqueEnded[item.id] = item;
          }
          result[ListingStatus.ended] = uniqueEnded.values.toList();

          // Sort ended list by end time
          result[ListingStatus.ended]!.sort((a, b) {
            final aTime = a.endTime ?? DateTime(0);
            final bTime = b.endTime ?? DateTime(0);
            return bTime.compareTo(aTime);
          });
        } catch (e) {
          debugPrint('Error loading ended listings: $e');
        }

        // 7. In Transaction (Moved to Transactions Module)
        // Kept as empty to maintain enum compatibility if needed elsewhere
        result[ListingStatus.inTransaction] = [];
        /*
        try {
          final inTransactionModels = await dataSource.getSellerListingsByStatus(
            sellerId,
            'in_transaction',
          );
          result[ListingStatus.inTransaction] = inTransactionModels
              .map((l) => l.toSellerListingEntity())
              .toList();
        } catch (e) {
          debugPrint('Error loading in_transaction listings: $e');
          result[ListingStatus.inTransaction] = [];
        }
        */

        // 8. Sold
        try {
          final soldModels = await dataSource.getSoldListings(sellerId);
          result[ListingStatus.sold] = soldModels
              .map((l) => l.toSellerListingEntity())
              .toList();
        } catch (e) {
          debugPrint('Error loading sold listings: $e');
          result[ListingStatus.sold] = [];
        }

        // 9. Deal Failed
        try {
          final dealFailedModels = await dataSource.getSellerListingsByStatus(
            sellerId,
            'deal_failed',
          );
          result[ListingStatus.dealFailed] = dealFailedModels
              .map((l) => l.toSellerListingEntity())
              .toList();
        } catch (e) {
          debugPrint('Error loading deal_failed listings: $e');
          result[ListingStatus.dealFailed] = [];
        }
      } catch (e) {
        debugPrint('Error loading active listings: $e');
        result[ListingStatus.active] = [];
      }

      // 10. Cancelled (Pre-auction cancellations)
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
  Future<Either<Failure, void>> deleteListing(String auctionId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      // Get seller ID from current session to ensure ownership
      final sellerId = dataSource.client.auth.currentUser?.id;
      if (sellerId == null) {
        return const Left(AuthFailure('User not authenticated'));
      }

      await dataSource.deleteListing(auctionId, sellerId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<void> streamSellerListings(String sellerId) {
    // Merge streams from both auctions and drafts to trigger updates for any change
    // Skip the first emission from each .stream() since Supabase emits initial data on subscribe
    final auctionsStream = dataSource.streamSellerListings(sellerId).skip(1);
    final draftsStream = dataSource.streamSellerDrafts(sellerId).skip(1);

    return StreamGroup.merge([auctionsStream, draftsStream]);
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
