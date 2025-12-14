import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../../../../app/core/config/supabase_config.dart';
import '../../domain/entities/listing_detail_entity.dart';
import '../widgets/detail_sections/listing_cover_section.dart';
import '../widgets/detail_sections/listing_info_section.dart';
import '../widgets/detail_sections/auction_stats_section.dart';
import '../widgets/detail_sections/qa_section.dart';
import '../../data/datasources/listing_supabase_datasource.dart';

class ActiveListingDetailPage extends StatefulWidget {
  final ListingDetailEntity listing;

  const ActiveListingDetailPage({super.key, required this.listing});

  @override
  State<ActiveListingDetailPage> createState() =>
      _ActiveListingDetailPageState();
}

class _ActiveListingDetailPageState extends State<ActiveListingDetailPage> {
  late final ListingSupabaseDataSource _datasource = ListingSupabaseDataSource(
    SupabaseConfig.client,
  );
  late ListingDetailEntity _listing;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _listing = widget.listing;
  }

  Future<void> _refreshListing() async {
    setState(() => _isLoading = true);
    try {
      // Note: You may need to fetch the updated listing from datasource
      // For now, this shows the refresh loading state
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: $e'),
            backgroundColor: ColorConstants.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _endAuction(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Auction'),
        content: const Text(
          'Are you sure you want to end this auction now? '
          'Current bids will be preserved and you can complete the transaction or cancel.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: ColorConstants.warning,
            ),
            child: const Text('End Auction'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _datasource.endAuction(_listing.id);

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading
      Navigator.pop(context, true); // Return to trigger reload

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auction ended. Check the Ended tab for next steps.'),
          backgroundColor: ColorConstants.success,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to end auction: $e'),
          backgroundColor: ColorConstants.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Auction'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshListing,
            tooltip: 'Refresh listing details',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      backgroundColor: isDark
          ? ColorConstants.backgroundDark
          : ColorConstants.backgroundLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListingCoverSection(listing: _listing),
                const SizedBox(height: 16),
                AuctionStatsSection(listing: _listing),
                const SizedBox(height: 16),
                ListingInfoSection(listing: _listing),
                const SizedBox(height: 16),
                QASection(listingId: _listing.id),
                const SizedBox(height: 16),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? ColorConstants.surfaceDark
              : ColorConstants.surfaceLight,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: () => _endAuction(context),
              style: FilledButton.styleFrom(
                backgroundColor: ColorConstants.warning,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.flag),
              label: const Text(
                'End Auction',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
