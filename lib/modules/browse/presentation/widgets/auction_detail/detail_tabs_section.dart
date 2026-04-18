import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/modules/browse/domain/entities/auction_detail_entity.dart';
import 'package:autobid_mobile/modules/browse/domain/entities/bid_history_entity.dart';
import 'package:autobid_mobile/modules/browse/domain/entities/qa_entity.dart';
import 'package:autobid_mobile/modules/bids/domain/entities/mystery_tiebreaker_session_entity.dart';
import 'package:autobid_mobile/modules/browse/presentation/widgets/auction_detail/bid_history_tab.dart';
import 'package:autobid_mobile/modules/browse/presentation/widgets/auction_detail/car_info_tab.dart';
import 'package:autobid_mobile/modules/browse/presentation/widgets/auction_detail/qa_tab.dart';

/// Container widget managing three main tabs in auction detail page
/// Tabs: Bid History (auction timeline), Car Info (static), Q&A (interactive)
///
/// Architecture:
/// - Uses DefaultTabController for tab state management
/// - Each tab is a separate widget with its own data and loading state
/// - Bid History shows auction-specific bid timeline (not user's global bids)
/// - User's global bids (Active/Won/Lost) are in Bids module, not here
class DetailTabsSection extends StatelessWidget {
  // Auction detail data for Car Info tab
  final AuctionDetailEntity auction;

  // Bid history data - auction-specific bid timeline
  final List<BidHistoryEntity> bidHistory;
  final bool isLoadingBidHistory;

  // Q&A data
  final List<QAEntity> questions;
  final bool isLoadingQA;
  final Function(String category, String question) onAskQuestion;
  final Function(String questionId) onToggleLike;
  final bool isMystery;
  final bool isMysteryEnded;
  final List<MysteryParticipantEntity> mysteryParticipants;

  const DetailTabsSection({
    super.key,
    required this.auction,
    required this.bidHistory,
    required this.questions,
    required this.onAskQuestion,
    required this.onToggleLike,
    this.isLoadingBidHistory = false,
    this.isLoadingQA = false,
    this.isMystery = false,
    this.isMysteryEnded = false,
    this.mysteryParticipants = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? ColorConstants.surfaceDark
                  : ColorConstants.backgroundSecondaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              padding: const EdgeInsets.all(4),
              indicator: BoxDecoration(
                color: isDark ? ColorConstants.surfaceLight : Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: ColorConstants.primary,
              unselectedLabelColor: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Bid History'), // Shows auction bid timeline
                Tab(text: 'Car Info'), // Shows car specifications
                Tab(text: 'Q&A'), // Shows questions & answers
              ],
            ),
          ),
          // Tab content
          SizedBox(
            height: 500, // Fixed height for tab content
            child: TabBarView(
              children: [
                // Bid History Tab: Shows all bids on this auction
                BidHistoryTab(
                  bidHistory: bidHistory,
                  isLoading: isLoadingBidHistory,
                  isMystery: isMystery,
                  isMysteryEnded: isMysteryEnded,
                  mysteryParticipants: mysteryParticipants,
                ),
                // Car Info Tab: Static car details and specs
                CarInfoTab(auction: auction),
                // Q&A Tab: Interactive questions and answers
                QATab(
                  questions: questions,
                  isLoading: isLoadingQA,
                  onAskQuestion: onAskQuestion,
                  onToggleLike: onToggleLike,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
