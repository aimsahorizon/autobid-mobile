import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../../../../app/core/config/supabase_config.dart';
import '../../domain/entities/transaction_status_entity.dart';
import '../controllers/transactions_status_controller.dart';
import '../pages/pre_transaction_page.dart';
import '../../../lists/presentation/widgets/listings_grid.dart';
import '../../../lists/domain/entities/seller_listing_entity.dart';
import '../../transactions_module.dart';

/// Page for status-based transactions (in_transaction, sold, deal_failed)
/// Displays in the Transactions bottom nav tab
class TransactionsStatusPage extends StatefulWidget {
  final TransactionsStatusController controller;

  const TransactionsStatusPage({super.key, required this.controller});

  @override
  State<TransactionsStatusPage> createState() => _TransactionsStatusPageState();
}

class _TransactionsStatusPageState extends State<TransactionsStatusPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    TransactionStatus.inTransaction,
    TransactionStatus.sold,
    TransactionStatus.dealFailed,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    widget.controller.loadTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Transactions'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((status) {
            return ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                final count = widget.controller.getCountByStatus(status);
                return _TabWithBadge(
                  label: status.tabLabel,
                  count: count,
                  color: _getStatusColor(status),
                );
              },
            );
          }).toList(),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (widget.controller.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: ColorConstants.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading transactions',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.controller.error!,
                    style: TextStyle(color: ColorConstants.textSecondaryLight),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => widget.controller.refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: _tabs.map((status) {
              final transactions = widget.controller.getTransactionsByStatus(
                status,
              );

              if (transactions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getEmptyIcon(status),
                        size: 64,
                        color: ColorConstants.textSecondaryLight,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getEmptyTitle(status),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getEmptySubtitle(status),
                        style: TextStyle(
                          color: ColorConstants.textSecondaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: widget.controller.refresh,
                child: ListingsGrid(
                  listings: transactions,
                  isGridView: false,
                  isLoading: false,
                  emptyTitle: _getEmptyTitle(status),
                  emptySubtitle: _getEmptySubtitle(status),
                  emptyIcon: _getEmptyIcon(status),
                  onListingUpdated: () => widget.controller.refresh(),
                  onTransactionCardTap: _handleTransactionCardTap,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.inTransaction:
        return ColorConstants.info;
      case TransactionStatus.sold:
        return ColorConstants.success;
      case TransactionStatus.dealFailed:
        return ColorConstants.error;
    }
  }

  IconData _getEmptyIcon(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.inTransaction:
        return Icons.handshake_outlined;
      case TransactionStatus.sold:
        return Icons.check_circle_outline;
      case TransactionStatus.dealFailed:
        return Icons.cancel_outlined;
    }
  }

  String _getEmptyTitle(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.inTransaction:
        return 'No active transactions';
      case TransactionStatus.sold:
        return 'No completed transactions';
      case TransactionStatus.dealFailed:
        return 'No failed transactions';
    }
  }

  String _getEmptySubtitle(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.inTransaction:
        return 'Active negotiations will appear here';
      case TransactionStatus.sold:
        return 'Successfully sold listings will appear here';
      case TransactionStatus.dealFailed:
        return 'Cancelled transactions will appear here';
    }
  }

  /// Handle transaction card tap - opens PreTransactionPage with proper controller
  Future<void> _handleTransactionCardTap(
    BuildContext context,
    SellerListingEntity listing,
  ) async {
    // Create transaction controller for this specific auction
    final transactionController = TransactionsModule.instance
        .createTransactionController(useMockData: false);

    final userId = SupabaseConfig.client.auth.currentUser?.id ?? '';
    final userName =
        SupabaseConfig.client.auth.currentUser?.userMetadata?['full_name'] ??
        'Seller';

    // Open PreTransactionPage with 4 subtabs (Chat, My Form, Buyer Form, Progress)
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => PreTransactionPage(
          controller: transactionController,
          transactionId: listing.id, // Pass auction ID as transaction ID
          userId: userId,
          userName: userName,
        ),
      ),
    );

    // Refresh transactions after returning
    await widget.controller.refresh();
  }
}

class _TabWithBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _TabWithBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
