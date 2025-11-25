import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../../domain/entities/listing_detail_entity.dart';
import '../widgets/detail_sections/listing_cover_section.dart';
import '../widgets/detail_sections/listing_info_section.dart';
import '../widgets/detail_sections/auction_stats_section.dart';
import '../widgets/detail_sections/qa_section.dart';

class ActiveListingDetailPage extends StatelessWidget {
  final ListingDetailEntity listing;

  const ActiveListingDetailPage({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Auction'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      backgroundColor: isDark ? ColorConstants.backgroundDark : ColorConstants.backgroundLight,
      body: ListView(
        children: [
          ListingCoverSection(listing: listing),
          const SizedBox(height: 16),
          AuctionStatsSection(listing: listing),
          const SizedBox(height: 16),
          ListingInfoSection(listing: listing),
          const SizedBox(height: 16),
          QASection(listingId: listing.id),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
