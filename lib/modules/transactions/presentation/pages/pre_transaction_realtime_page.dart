import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../controllers/transaction_realtime_controller.dart';
import '../../domain/entities/transaction_entity.dart';
import '../widgets/transaction_realtime/chat_realtime_tab.dart';
import '../widgets/transaction_realtime/seller_form_tab.dart';
import '../widgets/transaction_realtime/buyer_form_tab.dart';
import '../widgets/transaction_realtime/other_form_realtime_tab.dart';
import '../widgets/transaction_realtime/progress_realtime_tab.dart';

/// Real-time Pre-Transaction Page
/// Supports live chat and form updates between buyer and seller
class PreTransactionRealtimePage extends StatefulWidget {
  final TransactionRealtimeController controller;
  final String transactionId; // Can be transaction ID or auction ID
  final String userId;
  final String userName;

  const PreTransactionRealtimePage({
    super.key,
    required this.controller,
    required this.transactionId,
    required this.userId,
    required this.userName,
  });

  @override
  State<PreTransactionRealtimePage> createState() =>
      _PreTransactionRealtimePageState();
}

class _PreTransactionRealtimePageState
    extends State<PreTransactionRealtimePage> {
  String _debugStatus = 'initializing';

  @override
  void initState() {
    super.initState();
    print('[DEBUG PreTransactionRealtimePage] initState called');
    print(
      '[DEBUG PreTransactionRealtimePage] transactionId: ${widget.transactionId}',
    );
    print('[DEBUG PreTransactionRealtimePage] userId: ${widget.userId}');
    print('[DEBUG PreTransactionRealtimePage] userName: ${widget.userName}');
    _debugStatus = 'loading...';
    _loadWithDebug();
  }

  Future<void> _loadWithDebug() async {
    try {
      setState(() => _debugStatus = 'calling loadTransaction...');
      await widget.controller.loadTransaction(
        widget.transactionId,
        widget.userId,
      );
      if (mounted) {
        setState(() {
          if (widget.controller.hasError) {
            _debugStatus = 'error: ${widget.controller.errorMessage}';
          } else if (widget.controller.transaction == null) {
            _debugStatus = 'transaction is null';
          } else {
            _debugStatus = 'loaded: ${widget.controller.transaction!.status}';
          }
        });
      }
    } catch (e) {
      print(
        '[DEBUG PreTransactionRealtimePage] Exception in loadTransaction: $e',
      );
      if (mounted) {
        setState(() => _debugStatus = 'exception: $e');
      }
    }
  }

  @override
  void dispose() {
    print('[DEBUG PreTransactionRealtimePage] dispose called');
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('[DEBUG PreTransactionRealtimePage] build called - $_debugStatus');
    print(
      '[DEBUG PreTransactionRealtimePage] isLoading: ${widget.controller.isLoading}',
    );
    print(
      '[DEBUG PreTransactionRealtimePage] hasError: ${widget.controller.hasError}',
    );
    print(
      '[DEBUG PreTransactionRealtimePage] transaction: ${widget.controller.transaction?.id}',
    );
    print(
      '[DEBUG PreTransactionRealtimePage] transaction status: ${widget.controller.transaction?.status}',
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final transaction = widget.controller.transaction;
            final role = widget.controller.getUserRole(widget.userId);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaction',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (transaction != null)
                  Text(
                    '${transaction.carName} • ${role == FormRole.seller ? "Selling" : "Buying"}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? ColorConstants.textSecondaryDark
                          : ColorConstants.textSecondaryLight,
                    ),
                  ),
              ],
            );
          },
        ),
        actions: [
          // Refresh button
          ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              return IconButton(
                onPressed: widget.controller.isLoading
                    ? null
                    : () => widget.controller.refresh(),
                icon: widget.controller.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Refresh',
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Loading transaction...'),
                  const SizedBox(height: 8),
                  Text(
                    'Debug: $_debugStatus',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    'ID: ${widget.transactionId.substring(0, 8)}...',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (widget.controller.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
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
                      widget.controller.errorMessage ?? 'An error occurred',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark
                            ? ColorConstants.textSecondaryDark
                            : ColorConstants.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => widget.controller.loadTransaction(
                        widget.transactionId,
                        widget.userId,
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          final transaction = widget.controller.transaction;
          if (transaction == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.hourglass_empty,
                    size: 64,
                    color: ColorConstants.warning,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Waiting for transaction',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The seller has not started the transaction yet.',
                    style: TextStyle(
                      color: isDark
                          ? ColorConstants.textSecondaryDark
                          : ColorConstants.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          // Check if deal is cancelled/failed
          if (transaction.status == TransactionStatus.cancelled) {
            final role = widget.controller.getUserRole(widget.userId);
            final isSeller = role == FormRole.seller;

            // Seller sees options to handle failed deal
            if (isSeller) {
              return _buildSellerDealFailedOptions(transaction, isDark);
            }

            // Buyer just sees cancellation info
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cancel_outlined,
                      size: 80,
                      color: ColorConstants.error,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Deal Cancelled',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This transaction has been cancelled and is no longer active.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark
                            ? ColorConstants.textSecondaryDark
                            : ColorConstants.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          final role = widget.controller.getUserRole(widget.userId);
          final otherRoleLabel = role == FormRole.seller ? 'Buyer' : 'Seller';

          return DefaultTabController(
            length: 4,
            child: Column(
              children: [
                // Transaction status banner
                _buildStatusBanner(transaction, isDark),

                // Tab bar
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? ColorConstants.surfaceDark
                        : ColorConstants.backgroundSecondaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    padding: const EdgeInsets.all(4),
                    indicator: BoxDecoration(
                      color: isDark
                          ? ColorConstants.surfaceLight
                          : Colors.white,
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
                      fontSize: 12,
                    ),
                    tabs: [
                      const Tab(text: 'Chat'),
                      const Tab(text: 'My Form'),
                      Tab(text: '$otherRoleLabel Form'),
                      const Tab(text: 'Progress'),
                    ],
                  ),
                ),

                // Tab content
                Expanded(
                  child: TabBarView(
                    children: [
                      ChatRealtimeTab(
                        controller: widget.controller,
                        userId: widget.userId,
                        userName: widget.userName,
                      ),
                      // Role-specific form: Seller sees SellerFormTab, Buyer sees BuyerFormTab
                      role == FormRole.seller
                          ? SellerFormTab(
                              controller: widget.controller,
                              userId: widget.userId,
                            )
                          : BuyerFormTab(
                              controller: widget.controller,
                              userId: widget.userId,
                            ),
                      OtherFormRealtimeTab(
                        controller: widget.controller,
                        userId: widget.userId,
                      ),
                      ProgressRealtimeTab(
                        controller: widget.controller,
                        userId: widget.userId,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSellerDealFailedOptions(
    TransactionEntity transaction,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header
          Icon(Icons.cancel_outlined, size: 80, color: ColorConstants.error),
          const SizedBox(height: 24),
          const Text(
            'Deal Failed',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'The buyer has cancelled this transaction. You can choose how to proceed with your listing.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 32),

          // Options Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? ColorConstants.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? ColorConstants.surfaceLight.withValues(alpha: 0.2)
                    : Colors.grey.shade300,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What would you like to do?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                // Option 1: Choose next highest bidder
                _buildSellerOption(
                  icon: Icons.person_search,
                  title: 'Choose Next Highest Bidder',
                  description:
                      'Offer the vehicle to the next highest bidder from the auction',
                  color: ColorConstants.success,
                  isDark: isDark,
                  onTap: () => _showNextBidderDialog(),
                ),
                const SizedBox(height: 12),

                // Option 2: Reauction
                _buildSellerOption(
                  icon: Icons.refresh,
                  title: 'Relist Auction',
                  description:
                      'Start a new auction round with fresh bidding (7 days)',
                  color: ColorConstants.info,
                  isDark: isDark,
                  onTap: () => _showRelistDialog(),
                ),
                const SizedBox(height: 12),

                // Option 3: Delete
                _buildSellerOption(
                  icon: Icons.delete_forever,
                  title: 'Delete Auction',
                  description: 'Permanently remove this listing',
                  color: ColorConstants.error,
                  isDark: isDark,
                  onTap: () => _showDeleteAuctionDialog(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Go back button
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerOption({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: widget.controller.isProcessing ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: widget.controller.isProcessing ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? ColorConstants.textSecondaryDark
                            : ColorConstants.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showNextBidderDialog() async {
    // Show loading dialog while fetching bidders
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Fetch all bidders
    final bidders = await widget.controller.getAuctionBidders();

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    // Filter eligible bidders
    final eligibleBidders = bidders
        .where((b) => b['is_eligible'] == true)
        .toList();

    if (bidders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No bidders found for this auction'),
          backgroundColor: ColorConstants.error,
        ),
      );
      return;
    }

    // Show bidders selection dialog
    final selectedBidder = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _BiddersSelectionDialog(
        bidders: bidders,
        eligibleBidders: eligibleBidders,
      ),
    );

    if (selectedBidder != null && mounted) {
      final bidderId = selectedBidder['bidder_id'] as String;
      final bidAmount = selectedBidder['bid_amount'] as double;

      final success = await widget.controller.offerToSpecificBidder(
        bidderId,
        bidAmount,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Transaction offered to ${selectedBidder['bidder_name']}',
              ),
              backgroundColor: ColorConstants.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.controller.errorMessage ?? 'Failed to reassign',
              ),
              backgroundColor: ColorConstants.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _showRelistDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.refresh, color: ColorConstants.info),
            const SizedBox(width: 12),
            const Text('Relist Auction'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will start a new auction round with fresh bidding.'),
            SizedBox(height: 16),
            Text(
              'The auction will be active for 7 days and all previous bids will be cleared.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: ColorConstants.info),
            child: const Text('Relist'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await widget.controller.relistAuction();

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Auction relisted successfully'),
              backgroundColor: ColorConstants.success,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.controller.errorMessage ?? 'Failed to relist auction',
              ),
              backgroundColor: ColorConstants.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _showDeleteAuctionDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: ColorConstants.error),
            const SizedBox(width: 12),
            const Text('Delete Auction'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to permanently delete this listing?'),
            SizedBox(height: 16),
            Text(
              'This action cannot be undone. The listing will be removed from your account.',
              style: TextStyle(fontSize: 13, color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: ColorConstants.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await widget.controller.deleteAuction();

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Auction deleted successfully'),
              backgroundColor: ColorConstants.success,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.controller.errorMessage ?? 'Failed to delete auction',
              ),
              backgroundColor: ColorConstants.error,
            ),
          );
        }
      }
    }
  }

  Widget _buildStatusBanner(TransactionEntity transaction, bool isDark) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String text;

    if (transaction.status == TransactionStatus.cancelled) {
      bgColor = ColorConstants.error.withValues(alpha: 0.1);
      textColor = ColorConstants.error;
      icon = Icons.cancel;
      text = 'Deal Cancelled - This transaction is no longer active';
    } else if (transaction.adminApproved) {
      bgColor = ColorConstants.success.withValues(alpha: 0.1);
      textColor = ColorConstants.success;
      icon = Icons.verified;
      text = 'Admin Approved - Proceed with delivery';
    } else if (transaction.bothFormsSubmitted && transaction.bothConfirmed) {
      bgColor = ColorConstants.info.withValues(alpha: 0.1);
      textColor = ColorConstants.info;
      icon = Icons.hourglass_bottom;
      text = 'Ready for admin review';
    } else if (transaction.bothFormsSubmitted) {
      bgColor = ColorConstants.warning.withValues(alpha: 0.1);
      textColor = ColorConstants.warning;
      icon = Icons.rate_review;
      text = 'Review and confirm each other\'s forms';
    } else {
      bgColor = ColorConstants.primary.withValues(alpha: 0.1);
      textColor = ColorConstants.primary;
      icon = Icons.edit_document;
      text = 'Submit your transaction form';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog to display all bidders and allow seller to select one
class _BiddersSelectionDialog extends StatelessWidget {
  final List<Map<String, dynamic>> bidders;
  final List<Map<String, dynamic>> eligibleBidders;

  const _BiddersSelectionDialog({
    required this.bidders,
    required this.eligibleBidders,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.people, color: ColorConstants.primary),
          const SizedBox(width: 12),
          const Text('All Bidders'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a bidder to offer the vehicle to:',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            if (eligibleBidders.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorConstants.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: ColorConstants.warning),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'No eligible bidders available. All other bids have been marked as lost or refunded.',
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: bidders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final bidder = bidders[index];
                  return _BidderCard(
                    bidder: bidder,
                    isDark: isDark,
                    onSelect: bidder['is_eligible'] == true
                        ? () => Navigator.pop(context, bidder)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// Card displaying a single bidder's info
class _BidderCard extends StatelessWidget {
  final Map<String, dynamic> bidder;
  final bool isDark;
  final VoidCallback? onSelect;

  const _BidderCard({
    required this.bidder,
    required this.isDark,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentBuyer = bidder['is_current_buyer'] == true;
    final isEligible = bidder['is_eligible'] == true;
    final bidAmount = bidder['bid_amount'] as double;
    final bidderName = bidder['bidder_name'] as String? ?? 'Unknown';
    final status = bidder['status_display'] as String? ?? bidder['status'];

    Color cardColor;
    Color borderColor;
    if (isCurrentBuyer) {
      cardColor = ColorConstants.error.withValues(alpha: 0.1);
      borderColor = ColorConstants.error.withValues(alpha: 0.3);
    } else if (isEligible) {
      cardColor = ColorConstants.success.withValues(alpha: 0.05);
      borderColor = ColorConstants.success.withValues(alpha: 0.3);
    } else {
      cardColor = isDark
          ? ColorConstants.surfaceDark
          : ColorConstants.backgroundSecondaryLight;
      borderColor = Colors.grey.withValues(alpha: 0.3);
    }

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: isEligible ? 1.0 : 0.6,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: ColorConstants.primary.withValues(alpha: 0.2),
                child: Text(
                  bidderName.isNotEmpty ? bidderName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: ColorConstants.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Bidder info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            bidderName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentBuyer)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: ColorConstants.error,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'CANCELLED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '₱${_formatAmount(bidAmount)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isEligible
                                ? ColorConstants.success
                                : isDark
                                ? ColorConstants.textSecondaryDark
                                : ColorConstants.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              bidder['status'] as String?,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 10,
                              color: _getStatusColor(
                                bidder['status'] as String?,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Select button
              if (isEligible)
                Icon(Icons.chevron_right, color: ColorConstants.success),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'won':
      case 'winning':
        return ColorConstants.success;
      case 'active':
        return ColorConstants.info;
      case 'outbid':
        return ColorConstants.warning;
      case 'lost':
      case 'refunded':
        return ColorConstants.error;
      default:
        return Colors.grey;
    }
  }
}
