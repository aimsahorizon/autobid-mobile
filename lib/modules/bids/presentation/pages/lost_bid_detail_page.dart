import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../domain/entities/bid_detail_entity.dart';
import '../../data/datasources/bid_detail_mock_datasource.dart';
import '../widgets/lost_bid/lost_bid_header.dart';
import '../widgets/lost_bid/lost_bid_info_section.dart';
import '../widgets/lost_bid/lost_bid_winner_section.dart';
import '../widgets/active_bid/car_info_section.dart';
import '../widgets/active_bid/bid_history_section.dart';

class LostBidDetailPage extends StatefulWidget {
  final String auctionId;

  const LostBidDetailPage({
    super.key,
    required this.auctionId,
  });

  @override
  State<LostBidDetailPage> createState() => _LostBidDetailPageState();
}

class _LostBidDetailPageState extends State<LostBidDetailPage> {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Auction Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_bidDetail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Auction Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: ColorConstants.error),
              const SizedBox(height: 16),
              Text('Auction not found', style: theme.textTheme.titleLarge),
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
        title: const Text('Lost Auction'),
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
              LostBidHeader(bidDetail: _bidDetail!),
              const SizedBox(height: 12),
              LostBidInfoSection(bidDetail: _bidDetail!),
              const SizedBox(height: 12),
              LostBidWinnerSection(bidDetail: _bidDetail!),
              const SizedBox(height: 12),
              BidHistorySection(bidDetail: _bidDetail!),
              const SizedBox(height: 12),
              CarInfoSection(bidDetail: _bidDetail!),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
