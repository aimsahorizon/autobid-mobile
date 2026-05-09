import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import 'package:autobid_mobile/modules/lists/domain/entities/listing_detail_entity.dart';
import 'package:autobid_mobile/modules/lists/presentation/widgets/detail_sections/listing_cover_section.dart';
import 'package:autobid_mobile/modules/lists/presentation/widgets/detail_sections/listing_info_section.dart';
import 'package:autobid_mobile/modules/lists/presentation/widgets/detail_sections/auction_stats_section.dart';
import 'package:autobid_mobile/modules/lists/presentation/widgets/detail_sections/qa_section.dart';
import 'package:autobid_mobile/modules/lists/presentation/widgets/detail_sections/seller_bid_history_section.dart';
import 'package:autobid_mobile/modules/lists/presentation/widgets/detail_sections/bid_queue_live_section.dart';
import 'package:autobid_mobile/modules/lists/data/datasources/listing_supabase_datasource.dart';
import 'package:autobid_mobile/modules/lists/presentation/widgets/invite_management_dialog.dart';
import 'package:autobid_mobile/modules/lists/presentation/controllers/lists_controller.dart';

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
  List<Map<String, dynamic>> _bids = [];
  bool _isLoading = false;
  bool _isLoadingBids = false;
  bool _isDevTestModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _listing = widget.listing;
    _loadBids();
  }

  void _showInviteManagement(BuildContext context) {
    final controller = GetIt.instance<ListsController>();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InviteManagementDialog(
          controller: controller,
          auctionId: _listing.id,
          carName: _listing.carName,
        ),
      ),
    );
  }

  Future<void> _loadBids() async {
    setState(() => _isLoadingBids = true);
    try {
      final bids = await _datasource.getBids(_listing.id);
      if (mounted) {
        setState(() {
          _bids = bids;
        });
      }
    } catch (e) {
      debugPrint('Error loading bids: $e');
      if (mounted) {
        (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
          SnackBar(
            content: Text('Failed to load bid history: $e'),
            backgroundColor: ColorConstants.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingBids = false);
      }
    }
  }

  Future<void> _refreshListing() async {
    setState(() => _isLoading = true);
    try {
      // Refresh both listing details and bids
      await _loadBids();
      // TODO: Ideally fetch fresh listing details here too
      // _listing = await _datasource.getListing(_listing.id);
    } catch (e) {
      if (mounted) {
        (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
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

  Future<void> _updateEndTime(
    BuildContext context, {
    bool devMode = false,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _listing.endTime ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (picked == null || !context.mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _listing.endTime ?? DateTime.now().add(const Duration(hours: 1)),
      ),
    );

    if (pickedTime == null || !context.mounted) return;

    final localDateTime = DateTime(
      picked.year,
      picked.month,
      picked.day,
      pickedTime.hour,
      pickedTime.minute,
      59,
    );

    final newEndTime = localDateTime.toUtc();

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (devMode) {
        await _datasource.updateAuctionEndTimeDev(_listing.id, newEndTime);
      } else {
        await _datasource.updateAuctionEndTime(_listing.id, newEndTime);
      }

      if (context.mounted) {
        navigator.pop(); // Close loading
        navigator.pop(true); // Return to refresh

        (messenger..clearSnackBars()).showSnackBar(
          SnackBar(
            content: Text(
              devMode
                  ? 'Dev mode: Auction end time updated successfully'
                  : 'Auction end time updated successfully',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        navigator.pop(); // Close loading
        (messenger..clearSnackBars()).showSnackBar(
          SnackBar(
            content: Text('Failed to update end time: $e'),
            backgroundColor: ColorConstants.error,
            duration: const Duration(seconds: 3),
          ),
        );
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

      (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
        const SnackBar(
          content: Text('Auction ended. Check the Ended tab for next steps.'),
          backgroundColor: ColorConstants.success,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
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
                BidQueueLiveSection(
                  auctionId: _listing.id,
                  supabase: SupabaseConfig.client,
                ),
                const SizedBox(height: 16),
                SellerBidHistorySection(bids: _bids, isLoading: _isLoadingBids),
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
            child: Row(
              children: [
                if (_listing.visibility == 'private') ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showInviteManagement(context),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Invite'),
                      style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (!_isDevTestModeEnabled)
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _isDevTestModeEnabled = true);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.purple,
                        side: const BorderSide(color: Colors.purple),
                      ),
                      icon: const Icon(Icons.science, size: 18),
                      label: const Text(
                        'Enable Dev Test Mode',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (_isDevTestModeEnabled)
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: () => _updateEndTime(context, devMode: true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorConstants.primary,
                      ),
                      icon: const Icon(Icons.access_time, size: 18),
                      label: const Text(
                        'Dev: Update Time',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (_isDevTestModeEnabled) const SizedBox(width: 8),
                if (_isDevTestModeEnabled)
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () => _endAuction(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: ColorConstants.warning,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.flag),
                      label: const Text(
                        'Dev: End Auction',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
