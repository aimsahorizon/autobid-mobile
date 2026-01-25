import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import '../../domain/entities/seller_listing_entity.dart';
import 'listing_card.dart';
import '../../data/datasources/listing_detail_mock_datasource.dart';
import '../controllers/listing_draft_controller.dart';
import '../pages/active_listing_detail_page.dart';
import '../pages/pending_listing_detail_page.dart';
import '../pages/approved_listing_detail_page.dart';
import '../pages/draft_listing_detail_page.dart';
import '../pages/ended_listing_detail_page.dart';
import '../pages/cancelled_listing_detail_page.dart';
import 'package:get_it/get_it.dart';
import '../../../transactions/presentation/controllers/transaction_controller.dart';
import '../../../transactions/presentation/pages/pre_transaction_page.dart';
import '../../../transactions/presentation/pages/pre_transaction_realtime_page.dart';
import '../../../transactions/transactions_module.dart';

class ListingsGrid extends StatelessWidget {
  final List<SellerListingEntity> listings;
  final bool isGridView;
  final bool isLoading;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;
  final bool enableNavigation;
  final ListingDraftController? draftController;
  final String? sellerId;
  final VoidCallback? onListingUpdated;
  final Future<void> Function(BuildContext, SellerListingEntity)?
  onTransactionCardTap;

  const ListingsGrid({
    super.key,
    required this.listings,
    required this.isGridView,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyIcon,
    this.isLoading = false,
    this.enableNavigation = true,
    this.draftController,
    this.sellerId,
    this.onListingUpdated,
    this.onTransactionCardTap,
  });

  void _navigateToDetail(
    BuildContext context,
    SellerListingEntity listing,
  ) async {
    if (!enableNavigation) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Convert to ListingDetailEntity
    final datasource = ListingDetailMockDataSource();
    final detailEntity = await datasource.convertToDetailEntity(listing);

    if (!context.mounted) return;
    Navigator.pop(context); // Close loading dialog

    // Navigate to appropriate detail page based on status
    Widget detailPage;
    switch (listing.status) {
      case ListingStatus.active:
        detailPage = ActiveListingDetailPage(listing: detailEntity);
        break;
      case ListingStatus.pending:
        detailPage = PendingListingDetailPage(listing: detailEntity);
        break;
      case ListingStatus.approved:
        detailPage = ApprovedListingDetailPage(listing: detailEntity);
        break;
      case ListingStatus.scheduled:
        // Scheduled listings are treated like approved listings for details
        detailPage = ApprovedListingDetailPage(listing: detailEntity);
        break;
      case ListingStatus.draft:
        if (draftController == null || sellerId == null) return;
        detailPage = DraftListingDetailPage(
          listing: detailEntity,
          controller: draftController!,
          sellerId: sellerId!,
        );
        break;
      case ListingStatus.ended:
        detailPage = EndedListingDetailPage(listing: detailEntity);
        break;
      case ListingStatus.cancelled:
        // Check if this cancelled listing has an associated failed transaction
        // If so, route to the transaction page with options to handle the failed deal
        if (listing.transactionId != null) {
          // Has a transaction - route to transaction page for deal failed options
          // (next highest bidder, relist, delete)
          if (!context.mounted) return;
          final realtimeController = TransactionsModule.instance
              .createRealtimeTransactionController();

          final userId = SupabaseConfig.client.auth.currentUser?.id ?? '';
          final userName =
              SupabaseConfig
                  .client
                  .auth
                  .currentUser
                  ?.userMetadata?['full_name'] ??
              'Seller';

          await Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (context) => PreTransactionRealtimePage(
                controller: realtimeController,
                transactionId: listing.transactionId!,
                userId: userId,
                userName: userName,
              ),
            ),
          );

          // Reload listings after returning from transaction page
          if (onListingUpdated != null) {
            onListingUpdated!();
          }
          return;
        }

        // No transaction - regular cancelled listing page
        // Controller and sellerId are optional - page handles null gracefully
        detailPage = CancelledListingDetailPage(
          listing: detailEntity,
          controller: draftController,
          sellerId: sellerId,
        );
        break;
      case ListingStatus.inTransaction:
      case ListingStatus.sold:
      case ListingStatus.dealFailed:
        // Transaction statuses MUST use callback or open pre-transaction page
        // Never navigate to a listings detail page for transactions
        if (onTransactionCardTap != null) {
          await onTransactionCardTap!(context, listing);
          return;
        }

        // Fallback: open pre-transaction page directly
        if (!context.mounted) return;
        final transactionController = GetIt.I<TransactionController>();

        final userId = SupabaseConfig.client.auth.currentUser?.id ?? '';
        final userName =
            SupabaseConfig
                .client
                .auth
                .currentUser
                ?.userMetadata?['full_name'] ??
            'Seller';

        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (context) => PreTransactionPage(
              controller: transactionController,
              transactionId: listing.id,
              userId: userId,
              userName: userName,
            ),
          ),
        );
        return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => detailPage),
    );

    // Reload listings if there was an update (delete/submit)
    if (result != null && onListingUpdated != null) {
      onListingUpdated!();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (listings.isEmpty) {
      return _EmptyState(
        title: emptyTitle,
        subtitle: emptySubtitle,
        icon: emptyIcon,
      );
    }

    if (isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.62,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: listings.length,
        itemBuilder: (context, index) => ListingCard(
          listing: listings[index],
          isGridView: true,
          onTap: () => _navigateToDetail(context, listings[index]),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: listings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => ListingCard(
        listing: listings[index],
        isGridView: false,
        onTap: () => _navigateToDetail(context, listings[index]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: isDark
                  ? ColorConstants.textSecondaryDark.withValues(alpha: 0.5)
                  : ColorConstants.textSecondaryLight.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
