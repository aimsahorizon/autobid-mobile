import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../domain/entities/bid_detail_entity.dart';
import '../../data/datasources/bid_detail_mock_datasource.dart';
import '../widgets/active_bid/bid_header_section.dart';
import '../widgets/active_bid/bid_info_section.dart';
import '../widgets/active_bid/car_info_section.dart';
import '../widgets/active_bid/bid_history_section.dart';
import '../widgets/active_bid/place_bid_bottom_sheet.dart';

class ActiveBidDetailPage extends StatefulWidget {
  final String auctionId;

  const ActiveBidDetailPage({
    super.key,
    required this.auctionId,
  });

  @override
  State<ActiveBidDetailPage> createState() => _ActiveBidDetailPageState();
}

class _ActiveBidDetailPageState extends State<ActiveBidDetailPage> {
  final _datasource = BidDetailMockDataSource();
  BidDetailEntity? _bidDetail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBidDetail();
  }

  Future<void> _loadBidDetail() async {
    setState(() => _isLoading = true);
    final detail = await _datasource.getBidDetail(widget.auctionId);
    setState(() {
      _bidDetail = detail;
      _isLoading = false;
    });
  }

  void _showPlaceBidSheet() {
    if (_bidDetail == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlaceBidBottomSheet(
        currentBid: _bidDetail!.currentBid ?? _bidDetail!.startingPrice,
        minBidIncrement: 5000,
        onBidPlaced: (amount) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bid placed: ₱${amount.toStringAsFixed(0)}'),
              backgroundColor: ColorConstants.success,
            ),
          );
          _loadBidDetail();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bid Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_bidDetail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bid Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: ColorConstants.error),
              const SizedBox(height: 16),
              Text('Bid not found', style: theme.textTheme.titleLarge),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Bid'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBidDetail,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBidDetail,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              BidHeaderSection(bidDetail: _bidDetail!),
              const SizedBox(height: 12),
              BidInfoSection(bidDetail: _bidDetail!),
              const SizedBox(height: 12),
              BidHistorySection(bidDetail: _bidDetail!),
              const SizedBox(height: 12),
              CarInfoSection(bidDetail: _bidDetail!),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: isDark ? ColorConstants.surfaceDark : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Bid',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? ColorConstants.textSecondaryDark
                          : ColorConstants.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₱${(_bidDetail!.currentBid ?? _bidDetail!.startingPrice).toStringAsFixed(0)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _bidDetail!.hasEnded ? null : _showPlaceBidSheet,
              icon: const Icon(Icons.gavel),
              label: Text(_bidDetail!.isUserHighestBidder ? 'Increase Bid' : 'Place Bid'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
