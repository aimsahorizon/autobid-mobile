import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import 'package:autobid_mobile/core/constants/policy_constants.dart';
import 'package:autobid_mobile/core/widgets/policy_acceptance_dialog.dart';
import 'package:autobid_mobile/core/services/policy_penalty_datasource.dart';
import '../controllers/auction_detail_controller.dart';
import '../widgets/auction_detail/auction_cover_photo.dart';
import '../widgets/auction_detail/bidding_info_section.dart';
import '../widgets/auction_detail/car_photos_section.dart';
import '../widgets/auction_detail/bidding_card_section.dart';
import '../widgets/auction_detail/mystery_bidding_card.dart';
import '../widgets/auction_detail/mystery_tiebreaker_widget.dart';
import '../widgets/auction_detail/detail_tabs_section.dart';

class AuctionDetailPage extends StatefulWidget {
  final String auctionId;
  final AuctionDetailController controller;

  const AuctionDetailPage({
    super.key,
    required this.auctionId,
    required this.controller,
  });

  @override
  State<AuctionDetailPage> createState() => _AuctionDetailPageState();
}

class _AuctionDetailPageState extends State<AuctionDetailPage> {
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
                return _buildAuctionEndedState(existingAuction);
              }
              return _buildErrorState();
            }

            final auction = widget.controller.auction;
            if (auction == null) return const SizedBox.shrink();

            // Show graceful ended state when auction status is 'ended'
            if (auction.status == 'ended' || auction.hasEnded) {
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

  Widget _buildAuctionEndedState(dynamic auction) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    String formatPrice(double price) => price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );

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
