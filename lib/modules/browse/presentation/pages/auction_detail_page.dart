import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import '../../domain/entities/payment_entity.dart';
import '../controllers/auction_detail_controller.dart';
import '../widgets/auction_detail/auction_cover_photo.dart';
import '../widgets/auction_detail/bidding_info_section.dart';
import '../widgets/auction_detail/car_photos_section.dart';
import '../widgets/auction_detail/bidding_card_section.dart';
import '../widgets/auction_detail/detail_tabs_section.dart';
import '../widgets/payment/gcash_payment_form.dart';
import '../widgets/payment/maya_payment_form.dart';
import '../widgets/payment/card_payment_form.dart';
import '../widgets/payment/payment_success_sheet.dart';
import 'deposit_payment_page.dart';

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
  bool _isPaymentProcessing = false;

  @override
  void initState() {
    super.initState();
    widget.controller.loadAuctionDetail(widget.auctionId);
  }

  Future<void> _handleDeposit() async {
    final auction = widget.controller.auction;
    if (auction == null) return;

    // Get current user ID
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to participate in auction'),
          backgroundColor: ColorConstants.error,
        ),
      );
      return;
    }

    // Get deposit amount from auction configuration
    final depositAmount = auction.depositAmount > 0 ? auction.depositAmount : 5000.0;

    // Navigate to PayMongo deposit payment page
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DepositPaymentPage(
          auctionId: auction.id,
          userId: userId,
          depositAmount: depositAmount,
          onSuccess: () {
            // Reload auction to update deposit status
            widget.controller.loadAuctionDetail(auction.id);
          },
        ),
      ),
    );

    if (result == true && mounted) {
      // Deposit successful - show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Deposit successful! You can now place bids on this auction.',
          ),
          backgroundColor: ColorConstants.success,
        ),
      );
    }
  }

  Widget _buildPaymentForm(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.gcash:
        return GCashPaymentForm(
          amount: 10000,
          isProcessing: _isPaymentProcessing,
          onCancel: () => Navigator.pop(context),
          onSubmit: (phone) => _processPayment(method, phone),
        );
      case PaymentMethod.maya:
        return MayaPaymentForm(
          amount: 10000,
          isProcessing: _isPaymentProcessing,
          onCancel: () => Navigator.pop(context),
          onSubmit: (phone) => _processPayment(method, phone),
        );
      case PaymentMethod.card:
        return CardPaymentForm(
          amount: 10000,
          isProcessing: _isPaymentProcessing,
          onCancel: () => Navigator.pop(context),
          onSubmit: (card, expiry, cvv, name) => _processPayment(method, card),
        );
    }
  }

  Future<void> _processPayment(PaymentMethod method, String details) async {
    setState(() => _isPaymentProcessing = true);

    if (!mounted) return;
    Navigator.pop(context);

    // Process deposit through controller
    await widget.controller.processDeposit();

    if (!mounted) return;
    setState(() => _isPaymentProcessing = false);

    // Show success sheet
    _showPaymentSuccess(method);
  }

  void _showPaymentSuccess(PaymentMethod method) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentSuccessSheet(
        amount: 10000,
        paymentMethod: method.label,
        onContinue: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _handleBid(double amount) async {
    // Get current user ID
    final userId = SupabaseConfig.currentUser?.id;

    // Place bid with user ID
    final success = await widget.controller.placeBid(amount, userId: userId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
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
      ScaffoldMessenger.of(context).showSnackBar(
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

  void _handleAutoBidToggle(bool isActive, double? maxBid, double increment) {
    widget.controller.setAutoBid(isActive, maxBid, increment);
    if (isActive && maxBid != null) {
      ScaffoldMessenger.of(context).showSnackBar(
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (widget.controller.hasError) {
            return _buildErrorState();
          }

          final auction = widget.controller.auction;
          if (auction == null) return const SizedBox.shrink();

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
                    ),
                    CarPhotosSection(photos: auction.photos),
                    const SizedBox(height: 16),
                    BiddingCardSection(
                      hasDeposited: auction.hasUserDeposited,
                      minimumBid: auction.minimumBid,
                      currentBid: auction.currentBid,
                      minBidIncrement: auction.minBidIncrement,
                      depositAmount: auction.depositAmount > 0 ? auction.depositAmount : 5000.0,
                      enableIncrementalBidding:
                          auction.enableIncrementalBidding,
                      onDeposit: _handleDeposit,
                      onPlaceBid: _handleBid,
                      onAutoBidToggle: _handleAutoBidToggle,
                      isProcessing: widget.controller.isProcessing,
                      isAutoBidActive: widget.controller.isAutoBidActive,
                      maxAutoBid: widget.controller.maxAutoBid,
                    ),
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
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          );
        },
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
