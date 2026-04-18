import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import 'package:autobid_mobile/core/constants/policy_constants.dart';
import 'package:autobid_mobile/core/widgets/policy_acceptance_dialog.dart';
import 'package:autobid_mobile/core/services/policy_penalty_datasource.dart';
import 'package:autobid_mobile/modules/bids/data/datasources/user_bids_supabase_datasource.dart';
import 'package:autobid_mobile/modules/bids/domain/entities/mystery_tiebreaker_session_entity.dart';
import 'package:autobid_mobile/modules/browse/presentation/controllers/auction_detail_controller.dart';
import 'package:autobid_mobile/modules/browse/domain/entities/auction_detail_entity.dart';
import 'package:autobid_mobile/modules/browse/presentation/widgets/auction_detail/auction_cover_photo.dart';
import 'package:autobid_mobile/modules/browse/presentation/widgets/auction_detail/bidding_info_section.dart';
import 'package:autobid_mobile/modules/browse/presentation/widgets/auction_detail/car_photos_section.dart';
import 'package:autobid_mobile/modules/browse/presentation/widgets/auction_detail/bidding_card_section.dart';
import 'package:autobid_mobile/modules/browse/presentation/widgets/auction_detail/mystery_bidding_card.dart';
import 'package:autobid_mobile/modules/browse/presentation/widgets/auction_detail/mystery_tiebreaker_widget.dart';
import 'package:autobid_mobile/modules/browse/presentation/widgets/auction_detail/detail_tabs_section.dart';

class AuctionDetailPage extends StatefulWidget {
  final String auctionId;
  final AuctionDetailController controller;
  final bool showLostBanner;

  const AuctionDetailPage({
    super.key,
    required this.auctionId,
    required this.controller,
    this.showLostBanner = false,
  });

  @override
  State<AuctionDetailPage> createState() => _AuctionDetailPageState();
}

class _AuctionDetailPageState extends State<AuctionDetailPage> {
  bool _standbyJoined = false;
  bool _standbyLoading = false;

  @override
  void initState() {
    super.initState();
    widget.controller.loadAuctionDetail(widget.auctionId);
  }

  void _handleRaiseHand() async {
    // Policy & suspension check before joining bid queue
    final userId = SupabaseConfig.currentUser?.id;
    if (userId != null) {
      final suspension = await PolicyPenaltyDatasource.instance.checkSuspension(
        userId,
      );
      if (suspension.isSuspended) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You are suspended${suspension.isPermanent ? ' permanently' : ' until ${suspension.endsAt}'}: ${suspension.reason}',
            ),
            backgroundColor: ColorConstants.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }
    if (!mounted) return;
    final accepted = await PolicyAcceptanceDialog.show(
      context: context,
      policyType: PolicyConstants.biddingRules,
      contextId: widget.auctionId,
    );
    if (!accepted || !mounted) return;

    final success = await widget.controller.raiseHand();
    if (!mounted) return;

    if (success) {
      (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('✋', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Hand raised! You\'re in the queue. When it\'s your turn, you\'ll have 60 seconds to place your bid.',
                ),
              ),
            ],
          ),
          backgroundColor: ColorConstants.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else if (widget.controller.errorMessage != null) {
      (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
        SnackBar(
          content: Text(widget.controller.errorMessage!),
          backgroundColor: ColorConstants.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      widget.controller.clearError();
    }
  }

  void _handleSubmitTurnBid(double amount) async {
    final success = await widget.controller.submitTurnBid(bidAmount: amount);
    if (!mounted) return;

    if (success) {
      (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.gavel, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bid of ₱${amount.toStringAsFixed(0)} placed successfully!',
                ),
              ),
            ],
          ),
          backgroundColor: ColorConstants.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else if (widget.controller.errorMessage != null) {
      (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
        SnackBar(
          content: Text(widget.controller.errorMessage!),
          backgroundColor: ColorConstants.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      widget.controller.clearError();
    }
  }

  void _handleLowerHand() async {
    final success = await widget.controller.lowerHand();
    if (!mounted) return;

    if (success) {
      (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.pan_tool_alt, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Hand lowered — you have withdrawn from the queue.'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else if (widget.controller.errorMessage != null) {
      (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
        SnackBar(
          content: Text(widget.controller.errorMessage!),
          backgroundColor: ColorConstants.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      widget.controller.clearError();
    }
  }

  void _handleBid(double amount) async {
    // Get current user ID
    final userId = SupabaseConfig.currentUser?.id;

    // Policy & suspension check before placing bid
    if (userId != null) {
      final suspension = await PolicyPenaltyDatasource.instance.checkSuspension(
        userId,
      );
      if (suspension.isSuspended) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You are suspended${suspension.isPermanent ? ' permanently' : ' until ${suspension.endsAt}'}: ${suspension.reason}',
            ),
            backgroundColor: ColorConstants.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }
    if (!mounted) return;
    final accepted = await PolicyAcceptanceDialog.show(
      context: context,
      policyType: PolicyConstants.biddingRules,
      contextId: widget.auctionId,
    );
    if (!accepted || !mounted) return;

    // Place bid with user ID
    final success = await widget.controller.placeBid(amount, userId: userId);

    if (!mounted) return;

    if (success) {
      (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Bid of ₱${amount.toStringAsFixed(0)} placed!'),
            ],
          ),
          backgroundColor: ColorConstants.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else if (widget.controller.errorMessage != null) {
      // Show error message
      (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
        SnackBar(
          content: Text(widget.controller.errorMessage!),
          backgroundColor: ColorConstants.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      widget.controller.clearError();
    }
  }

  void _handleMysteryBid(double amount) async {
    // Policy & suspension check
    final userId = SupabaseConfig.currentUser?.id;
    if (userId != null) {
      final suspension = await PolicyPenaltyDatasource.instance.checkSuspension(
        userId,
      );
      if (suspension.isSuspended) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You are suspended${suspension.isPermanent ? ' permanently' : ' until ${suspension.endsAt}'}: ${suspension.reason}',
            ),
            backgroundColor: ColorConstants.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }
    if (!mounted) return;
    final accepted = await PolicyAcceptanceDialog.show(
      context: context,
      policyType: PolicyConstants.biddingRules,
      contextId: widget.auctionId,
    );
    if (!accepted || !mounted) return;

    final success = await widget.controller.placeMysteryBid(amount);
    if (!mounted) return;

    if (success) {
      (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sealed bid of ₱${amount.toStringAsFixed(0)} placed!',
                ),
              ),
            ],
          ),
          backgroundColor: ColorConstants.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else if (widget.controller.errorMessage != null) {
      (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
        SnackBar(
          content: Text(widget.controller.errorMessage!),
          backgroundColor: ColorConstants.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      widget.controller.clearError();
    }
  }

  void _handleAutoBidToggle(
    bool isActive,
    double? maxBid,
    double increment,
  ) async {
    final success = await widget.controller.setAutoBid(
      isActive,
      maxBid,
      increment,
    );
    if (!mounted) return;

    if (success && isActive && maxBid != null) {
      (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.auto_mode, color: Colors.white),
              const SizedBox(width: 8),
              Text('Auto-bid enabled up to ₱${maxBid.toStringAsFixed(0)}'),
            ],
          ),
          backgroundColor: ColorConstants.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else if (success && !isActive) {
      (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
        const SnackBar(
          content: Text('Auto-bid deactivated'),
          backgroundColor: ColorConstants.warning,
        ),
      );
    } else if (!success && widget.controller.errorMessage != null) {
      (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
        SnackBar(
          content: Text(widget.controller.errorMessage!),
          backgroundColor: ColorConstants.error,
        ),
      );
      widget.controller.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          (isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
              .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            if (widget.controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (widget.controller.hasError) {
              // Check if it's an auction-ended scenario
              final existingAuction = widget.controller.auction;
              if (existingAuction != null && existingAuction.hasEnded) {
                if (widget.showLostBanner) {
                  return _buildLostAuctionDetail(existingAuction);
                }
                return _buildAuctionEndedState(existingAuction);
              }
              return _buildErrorState();
            }

            final auction = widget.controller.auction;
            if (auction == null) return const SizedBox.shrink();

            // Show graceful ended state when auction status is 'ended'
            if (auction.status == 'ended' || auction.hasEnded) {
              if (widget.showLostBanner) {
                return _buildLostAuctionDetail(auction);
              }
              return _buildAuctionEndedState(auction);
            }

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 250,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: AuctionCoverPhoto(
                      imageUrl: auction.carImageUrl,
                      carName: auction.carName,
                      status: auction.status,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: widget.controller.isLoading
                          ? null
                          : () => widget.controller.loadAuctionDetail(
                              widget.auctionId,
                            ),
                      tooltip: 'Refresh auction details',
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      BiddingInfoSection(
                        endTime: auction.endTime,
                        currentBid: auction.currentBid,
                        reservePrice: auction.reservePrice,
                        isReserveMet: auction.isReserveMet,
                        showReservePrice: auction.showReservePrice,
                        totalBids: auction.totalBids,
                        watchersCount: auction.watchersCount,
                        isMystery: widget.controller.isMysteryAuction,
                        mysteryBidCount:
                            widget.controller.mysteryBidStatus?.bidCount,
                        startingPrice: auction.minimumBid,
                      ),
                      CarPhotosSection(photos: auction.photos),
                      const SizedBox(height: 16),
                      if (widget.controller.isMysteryAuction)
                        MysteryBiddingCard(
                          minimumBid: auction.minimumBid,
                          isProcessing: widget.controller.isProcessing,
                          mysteryStatus: widget.controller.mysteryBidStatus,
                          isLoadingStatus:
                              widget.controller.isLoadingMysteryStatus,
                          onPlaceMysteryBid: _handleMysteryBid,
                        )
                      else
                        BiddingCardSection(
                          minimumBid: auction.minimumBid,
                          currentBid: auction.currentBid,
                          minBidIncrement: auction.minBidIncrement,
                          enableIncrementalBidding:
                              auction.enableIncrementalBidding,
                          onPlaceBid: _handleBid,
                          onAutoBidToggle: _handleAutoBidToggle,
                          isProcessing: widget.controller.isProcessing,
                          isAutoBidActive: widget.controller.isAutoBidActive,
                          maxAutoBid: widget.controller.maxAutoBid,
                          bidIncrement: widget.controller.bidIncrement,
                          queueStatus: widget.controller.queueStatus,
                          hasRaisedHand: widget.controller.hasRaisedHand,
                          isMyTurn: widget.controller.isMyTurn,
                          turnRemainingMs: widget.controller.turnRemainingMs,
                          onRaiseHand: _handleRaiseHand,
                          onLowerHand: _handleLowerHand,
                          onSubmitTurnBid: _handleSubmitTurnBid,
                          queuePosition: widget.controller.queuePosition,
                        ),
                      // Tiebreaker widget for mystery auctions with ties
                      if (widget.controller.isMysteryAuction &&
                          widget.controller.mysteryBidStatus?.tiebreaker !=
                              null) ...[
                        const SizedBox(height: 16),
                        MysteryTiebreakerWidget(
                          tiebreaker:
                              widget.controller.mysteryBidStatus!.tiebreaker!,
                          auctionId: widget.auctionId,
                          currentUserId: SupabaseConfig.currentUser?.id,
                          isReplay:
                              widget.controller.mysteryBidStatus!.auctionEnded,
                        ),
                      ],
                      const SizedBox(height: 24),
                      DetailTabsSection(
                        auction: widget.controller.auction!,
                        bidHistory: widget.controller.bidHistory,
                        questions: widget.controller.questions,
                        isLoadingBidHistory:
                            widget.controller.isLoadingBidHistory,
                        isLoadingQA: widget.controller.isLoadingQA,
                        onAskQuestion: widget.controller.askQuestion,
                        onToggleLike: widget.controller.toggleQuestionLike,
                        isMystery: widget.controller.isMysteryAuction,
                        isMysteryEnded:
                            widget.controller.mysteryBidStatus?.auctionEnded ??
                            false,
                        mysteryParticipants:
                            widget.controller.mysteryParticipants,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLostAuctionDetail(dynamic auction) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 250,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: AuctionCoverPhoto(
              imageUrl: auction.carImageUrl,
              carName: auction.carName,
              status: auction.status,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              // Lost banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: ColorConstants.error.withValues(alpha: 0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: ColorConstants.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You lost this auction',
                            style: TextStyle(
                              color: ColorConstants.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 28),
                      child: Text(
                        'If the winner cancels the deal, you may still get a chance.',
                        style: TextStyle(
                          color: ColorConstants.error.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Standby opt-in button
              _buildStandbyOptIn(auction),
              BiddingInfoSection(
                endTime: auction.endTime,
                currentBid: auction.currentBid,
                reservePrice: auction.reservePrice,
                isReserveMet: auction.isReserveMet,
                showReservePrice: auction.showReservePrice,
                totalBids: auction.totalBids,
                watchersCount: auction.watchersCount,
                isMystery: false,
                startingPrice: auction.minimumBid,
              ),
              CarPhotosSection(photos: auction.photos),
              const SizedBox(height: 24),
              DetailTabsSection(
                auction: auction,
                bidHistory: widget.controller.bidHistory,
                questions: widget.controller.questions,
                isLoadingBidHistory: widget.controller.isLoadingBidHistory,
                isLoadingQA: widget.controller.isLoadingQA,
                onAskQuestion: widget.controller.askQuestion,
                onToggleLike: widget.controller.toggleQuestionLike,
                isMystery: false,
                isMysteryEnded: false,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStandbyOptIn(dynamic auction) {
    if (_standbyJoined) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: ColorConstants.warning.withValues(alpha: 0.1),
        child: Row(
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
              size: 20,
              color: ColorConstants.warning,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'You are on standby for this auction. You\'ll be notified if selected.',
                style: TextStyle(
                  color: ColorConstants.warning,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _standbyLoading ? null : _handleJoinStandby,
          icon: _standbyLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.hourglass_empty_rounded),
          label: Text(
            _standbyLoading ? 'Joining...' : 'Stand By for This Auction',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: ColorConstants.warning,
            side: BorderSide(color: ColorConstants.warning),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Future<void> _handleJoinStandby() async {
    setState(() => _standbyLoading = true);
    try {
      final ds = UserBidsSupabaseDataSource(SupabaseConfig.client);
      final success = await ds.joinStandbyQueue(widget.auctionId);
      if (mounted) {
        setState(() {
          _standbyJoined = success;
          _standbyLoading = false;
        });
        if (success) {
          (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
            SnackBar(
              content: const Text('You are now on standby for this auction!'),
              backgroundColor: ColorConstants.success,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) setState(() => _standbyLoading = false);
    }
  }

  Widget _buildAuctionEndedState(dynamic auction) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    String formatPrice(double price) => price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );

    final isWinner = widget.controller.isCurrentUserWinner;
    final hasBid = widget.controller.hasUserBid;

    // Seller tiebreaker pending state
    if (widget.controller.mysteryBidStatus?.isSeller == true &&
        auction is AuctionDetailEntity &&
        auction.biddingType == 'mystery') {
      return _buildSellerTiebreakerState(auction, theme, isDark);
    }

    // Won state
    if (isWinner) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: ColorConstants.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_outlined,
                  size: 40,
                  color: ColorConstants.success,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Congratulations!',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.success,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You won the auction for',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark
                      ? ColorConstants.textSecondaryDark
                      : ColorConstants.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${auction.carName}',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Winning Bid: ₱${formatPrice(auction.currentBid)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: ColorConstants.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Go to My Bids'),
              ),
            ],
          ),
        ),
      );
    }

    // Lost state (user bid but didn't win)
    if (hasBid) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: ColorConstants.warning.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sentiment_neutral_outlined,
                  size: 40,
                  color: ColorConstants.warning,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Auction Has Ended',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${auction.carName}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (auction is AuctionDetailEntity &&
                  auction.biddingType == 'mystery')
                Text(
                  'Starting Price: ₱${formatPrice(auction.minimumBid)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Text(
                  'Final Bid: ₱${formatPrice(auction.currentBid)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: ColorConstants.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Unfortunately, you were outbid this time. But don\'t lose hope — if the winner cancels, you may still get a chance!',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? ColorConstants.textSecondaryDark
                      : ColorConstants.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Browse'),
              ),
            ],
          ),
        ),
      );
    }

    // Default state (user didn't bid, just viewing)
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: ColorConstants.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.timer_off_outlined,
                size: 40,
                color: ColorConstants.warning,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Auction Has Ended',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${auction.carName}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            if (auction is AuctionDetailEntity &&
                auction.biddingType == 'mystery')
              Text(
                'Starting Price: ₱${formatPrice(auction.minimumBid)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Text(
                'Final Bid: ₱${formatPrice(auction.currentBid)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: ColorConstants.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Browse'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerTiebreakerState(
    AuctionDetailEntity auction,
    ThemeData theme,
    bool isDark,
  ) {
    final session = widget.controller.tiebreakerSession;
    final isLoading = widget.controller.isLoadingMysteryStatus;

    String statusLabel(String? status) {
      switch (status) {
        case 'waiting_ready':
          return 'Waiting for participants to ready up';
        case 'rps_in_progress':
          return 'Rock-Paper-Scissors in progress';
        case 'wheel_in_progress':
          return 'Wheel of Names spinning';
        case 'completed':
          return 'Resolved — transaction opening soon';
        case 'dq_all':
          return 'All participants disqualified — cascading';
        default:
          return 'Tiebreaker pending';
      }
    }

    String typeLabel(String? type) =>
        type == 'rps' ? 'Rock-Paper-Scissors (2-way)' : 'Wheel of Names (3+)';

    Color statusColor(String? status) {
      switch (status) {
        case 'completed':
          return ColorConstants.success;
        case 'dq_all':
          return ColorConstants.error;
        default:
          return ColorConstants.warning;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auction Ended'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: isLoading
                ? null
                : () => widget.controller.loadAuctionDetail(widget.auctionId),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.deepPurple.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.hourglass_top_rounded,
                    size: 48,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Mystery Tiebreaker in Progress',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    auction.carName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? ColorConstants.textSecondaryDark
                          : ColorConstants.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (isLoading && session == null)
              const Center(child: CircularProgressIndicator())
            else if (session == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Bidding has ended. Waiting for tiebreaker data…\nPull to refresh.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              )
            else ...[
              // Type chip
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.games, size: 16),
                    label: Text(typeLabel(session.type.name)),
                    backgroundColor: Colors.deepPurple.withValues(alpha: 0.12),
                    labelStyle: const TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  Chip(
                    label: Text(statusLabel(session.status.name)),
                    backgroundColor: statusColor(
                      session.status.name,
                    ).withValues(alpha: 0.12),
                    labelStyle: TextStyle(
                      color: statusColor(session.status.name),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Info cards
              _buildInfoRow(
                theme,
                isDark,
                icon: Icons.group,
                label: 'Tied Participants',
                value: '${session.initialTiedCount}',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                theme,
                isDark,
                icon: Icons.check_circle_outline,
                label: 'Ready',
                value:
                    '${session.readyAliases.length} / ${session.initialTiedCount}',
              ),
              ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                theme,
                isDark,
                icon: Icons.timer_outlined,
                label: 'Ready Deadline',
                value: _formatDeadline(session.readyDeadline),
              ),
            ],
              if (session.type == TiebreakerType.rps &&
                  session.rpsCurrentRound > 0) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  theme,
                  isDark,
                  icon: Icons.repeat,
                  label: 'RPS Rounds Played',
                  value: '${session.rpsCurrentRound}',
                ),
              ],
              const SizedBox(height: 20),
            ],

            // Notice
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ColorConstants.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ColorConstants.success.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: ColorConstants.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The transaction will open automatically once the tiebreaker is resolved. You don\'t need to do anything right now.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: ColorConstants.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.deepPurple),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final diff = deadline.difference(now);
    if (diff.isNegative) return 'Expired';
    if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m left';
    }
    if (diff.inMinutes > 0) return '${diff.inMinutes}m left';
    return '${diff.inSeconds}s left';
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: ColorConstants.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: ColorConstants.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.controller.errorMessage ??
                  'Unable to load auction details',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () =>
                  widget.controller.loadAuctionDetail(widget.auctionId),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
