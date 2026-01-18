import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import '../../domain/entities/transaction_status_entity.dart';
import '../controllers/buyer_seller_transactions_controller.dart';
import '../pages/pre_transaction_realtime_page.dart';
import '../../../lists/presentation/widgets/listings_grid.dart';
import '../../../lists/domain/entities/seller_listing_entity.dart';
import '../../transactions_module.dart';
import '../../data/datasources/transaction_supabase_datasource.dart';

/// Page for status-based transactions with buyer/seller perspective
/// Displays in the Transactions bottom nav tab
/// Features two main tabs: "As a Buyer" and "As a Seller"
/// Each has sub-tabs for transaction status (In Transaction, Sold, Failed)
class TransactionsStatusPage extends StatefulWidget {
  const TransactionsStatusPage({super.key});

  @override
  State<TransactionsStatusPage> createState() => _TransactionsStatusPageState();
}

class _TransactionsStatusPageState extends State<TransactionsStatusPage>
    with TickerProviderStateMixin {
  late TabController _mainTabController; // Buyer/Seller tabs
  late TabController _statusTabController; // Status tabs
  late BuyerSellerTransactionsController _controller;
  bool _initialized = false;

  static const _statusTabs = [
    TransactionStatus.inTransaction,
    TransactionStatus.sold,
    TransactionStatus.dealFailed,
  ];

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _statusTabController = TabController(
      length: _statusTabs.length,
      vsync: this,
    );

    // Initialize controller with transaction datasource only
    final dataSource = TransactionSupabaseDataSource(SupabaseConfig.client);
    final userId = SupabaseConfig.client.auth.currentUser?.id ?? '';

    _controller = BuyerSellerTransactionsController(
      dataSource,
      null, // No longer need separate buyer datasource
      userId,
    );

    _controller.loadTransactions();
    _initialized = true;
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _statusTabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _controller.isLoading ? null : _controller.refresh,
            tooltip: 'Refresh transactions',
          ),
        ],
        bottom: TabBar(
          controller: _mainTabController,
          tabs: const [
            Tab(text: 'As a Buyer'),
            Tab(text: 'As a Seller'),
          ],
          onTap: (_) {
            _statusTabController.index = 0;
          },
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.error != null) {
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
                    _controller.error!,
                    style: TextStyle(color: ColorConstants.textSecondaryLight),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _controller.refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _mainTabController,
            children: [
              // Buyer tab
              _buildBuyerTransactionsView(),
              // Seller tab
              _buildSellerTransactionsView(),
            ],
          );
        },
      ),
    );
  }

  /// Build buyer transactions view with status sub-tabs
  Widget _buildBuyerTransactionsView() {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: TabBar(
          controller: _statusTabController,
          tabs: _statusTabs.map((status) {
            return ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                final count = _controller.getBuyerCountByStatus(status);
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
      body: TabBarView(
        controller: _statusTabController,
        children: _statusTabs.map((status) {
          return ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final transactions = _controller.getBuyerTransactionsByStatus(
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
                        _getEmptyBuyerTitle(status),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getEmptyBuyerSubtitle(status),
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
                onRefresh: _controller.refresh,
                child: ListingsGrid(
                  listings: transactions,
                  isGridView: false,
                  isLoading: false,
                  emptyTitle: _getEmptyBuyerTitle(status),
                  emptySubtitle: _getEmptyBuyerSubtitle(status),
                  emptyIcon: _getEmptyIcon(status),
                  onListingUpdated: () => _controller.refresh(),
                  onTransactionCardTap: _handleBuyerTransactionTap,
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  /// Build seller transactions view with status sub-tabs
  Widget _buildSellerTransactionsView() {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: TabBar(
          controller: _statusTabController,
          tabs: _statusTabs.map((status) {
            return ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                final count = _controller.getSellerCountByStatus(status);
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
      body: TabBarView(
        controller: _statusTabController,
        children: _statusTabs.map((status) {
          return ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final transactions = _controller.getSellerTransactionsByStatus(
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
                        _getEmptySellerTitle(status),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getEmptySellerSubtitle(status),
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
                onRefresh: _controller.refresh,
                child: ListingsGrid(
                  listings: transactions,
                  isGridView: false,
                  isLoading: false,
                  emptyTitle: _getEmptySellerTitle(status),
                  emptySubtitle: _getEmptySellerSubtitle(status),
                  emptyIcon: _getEmptyIcon(status),
                  onListingUpdated: () => _controller.refresh(),
                  onTransactionCardTap: _handleSellerTransactionTap,
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  /// Handle buyer transaction tap
  Future<void> _handleBuyerTransactionTap(
    BuildContext context,
    SellerListingEntity listing,
  ) async {
    print('[DEBUG] _handleBuyerTransactionTap called');
    print('[DEBUG] Listing ID: ${listing.id}');
    print('[DEBUG] Listing status: ${listing.status}');
    print('[DEBUG] Listing make/model: ${listing.make} ${listing.model}');

    final transactionController = TransactionsModule.instance
        .createRealtimeTransactionController();
    final userId = SupabaseConfig.client.auth.currentUser?.id ?? '';
    final userName =
        SupabaseConfig.client.auth.currentUser?.userMetadata?['full_name'] ??
        SupabaseConfig.client.auth.currentUser?.userMetadata?['display_name'] ??
        'Buyer';

    print('[DEBUG] User ID: $userId');
    print('[DEBUG] User name: $userName');
    print('[DEBUG] Navigating to PreTransactionRealtimePage...');

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => PreTransactionRealtimePage(
          controller: transactionController,
          transactionId: listing.id, // Use listing ID to find the transaction
          userId: userId,
          userName: userName,
        ),
      ),
    );

    print('[DEBUG] Returned from PreTransactionRealtimePage');
    await _controller.refresh();
  }

  /// Handle seller transaction tap
  Future<void> _handleSellerTransactionTap(
    BuildContext context,
    SellerListingEntity listing,
  ) async {
    print('[DEBUG] _handleSellerTransactionTap called');
    print('[DEBUG] Listing ID: ${listing.id}');
    print('[DEBUG] Listing status: ${listing.status}');
    print('[DEBUG] Listing make/model: ${listing.make} ${listing.model}');

    // Show debug snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Opening: ${listing.id.substring(0, 8)}... status=${listing.status}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    final transactionController = TransactionsModule.instance
        .createRealtimeTransactionController();

    final userId = SupabaseConfig.client.auth.currentUser?.id ?? '';
    final userName =
        SupabaseConfig.client.auth.currentUser?.userMetadata?['full_name'] ??
        SupabaseConfig.client.auth.currentUser?.userMetadata?['display_name'] ??
        'Seller';

    print('[DEBUG] User ID: $userId');
    print('[DEBUG] User name: $userName');
    print('[DEBUG] Navigating to PreTransactionRealtimePage...');

    try {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (context) => PreTransactionRealtimePage(
            controller: transactionController,
            transactionId: listing.id,
            userId: userId,
            userName: userName,
          ),
        ),
      );
      print('[DEBUG] Returned from PreTransactionRealtimePage normally');
    } catch (e, stack) {
      print('[DEBUG] ❌ Navigation error: $e');
      print('[DEBUG] Stack: $stack');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }

    await _controller.refresh();
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

  String _getEmptyBuyerTitle(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.inTransaction:
        return 'No active purchases';
      case TransactionStatus.sold:
        return 'No completed purchases';
      case TransactionStatus.dealFailed:
        return 'No failed purchases';
    }
  }

  String _getEmptyBuyerSubtitle(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.inTransaction:
        return 'Your won auctions will appear here';
      case TransactionStatus.sold:
        return 'Completed purchases will appear here';
      case TransactionStatus.dealFailed:
        return 'Cancelled purchases will appear here';
    }
  }

  String _getEmptySellerTitle(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.inTransaction:
        return 'No active sales';
      case TransactionStatus.sold:
        return 'No completed sales';
      case TransactionStatus.dealFailed:
        return 'No failed sales';
    }
  }

  String _getEmptySellerSubtitle(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.inTransaction:
        return 'Active negotiations will appear here';
      case TransactionStatus.sold:
        return 'Successfully sold listings will appear here';
      case TransactionStatus.dealFailed:
        return 'Cancelled transactions will appear here';
    }
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
