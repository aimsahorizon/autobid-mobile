import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/constants/policy_constants.dart';
import 'package:autobid_mobile/core/widgets/policy_acceptance_dialog.dart';
import 'package:autobid_mobile/core/services/policy_penalty_datasource.dart';
import 'package:autobid_mobile/modules/auth/auth_routes.dart';
import '../controllers/transaction_realtime_controller.dart';
import '../controllers/installment_controller.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../data/datasources/installment_supabase_datasource.dart';
import '../../data/datasources/transaction_supabase_datasource.dart';
import '../widgets/transaction_realtime/chat_realtime_tab.dart';
import '../widgets/transaction_realtime/progress_realtime_tab.dart';
import '../widgets/transaction_realtime/unified_agreement_tab.dart';
import '../widgets/transaction_realtime/installment_tracker_tab.dart';
import '../widgets/transaction_realtime/deposit_payment_tab.dart';

/// Real-time Pre-Transaction Page
/// Supports live chat and form updates between buyer and seller
class PreTransactionRealtimePage extends StatefulWidget {
  final TransactionRealtimeController controller;
  final String transactionId; // Can be transaction ID or auction ID
  final String userId;
  final String userName;
  final int initialTabIndex;

  const PreTransactionRealtimePage({
    super.key,
    required this.controller,
    required this.transactionId,
    required this.userId,
    required this.userName,
    this.initialTabIndex = 0,
  });

  @override
  State<PreTransactionRealtimePage> createState() =>
      _PreTransactionRealtimePageState();
}

class _PreTransactionRealtimePageState
    extends State<PreTransactionRealtimePage> {
  String _debugStatus = 'initializing';
  InstallmentController? _installmentController;
  bool _policyAccepted = false;
  bool _isSuspended = false;
  String? _suspensionMessage;

  @override
  void initState() {
    super.initState();
    debugPrint('[DEBUG PreTransactionRealtimePage] initState called');
    debugPrint(
      '[DEBUG PreTransactionRealtimePage] transactionId: ${widget.transactionId}',
    );
    debugPrint('[DEBUG PreTransactionRealtimePage] userId: ${widget.userId}');
    debugPrint(
      '[DEBUG PreTransactionRealtimePage] userName: ${widget.userName}',
    );
    _debugStatus = 'loading...';
    _loadWithDebug();
  }

  Future<void> _loadWithDebug() async {
    try {
      // Check suspension before loading
      final suspension = await PolicyPenaltyDatasource.instance.checkSuspension(
        widget.userId,
      );
      if (suspension.isSuspended) {
        if (mounted) {
          setState(() {
            _isSuspended = true;
            _suspensionMessage =
                'You are suspended${suspension.isPermanent ? ' permanently' : ' until ${suspension.endsAt}'}: ${suspension.reason}';
            _debugStatus = 'suspended';
          });
        }
        return;
      }

      // Check policy acceptance
      if (mounted) {
        final accepted = await PolicyAcceptanceDialog.show(
          context: context,
          policyType: PolicyConstants.transactionRules,
          contextId: widget.transactionId,
        );
        if (!accepted) {
          if (mounted) {
            setState(() {
              _policyAccepted = false;
              _debugStatus = 'policy declined';
            });
          }
          return;
        }
        if (mounted) setState(() => _policyAccepted = true);
      }

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
      debugPrint(
        '[DEBUG PreTransactionRealtimePage] Exception in loadTransaction: $e',
      );
      if (mounted) {
        setState(() => _debugStatus = 'exception: $e');
      }
    }
  }

  @override
  void dispose() {
    debugPrint('[DEBUG PreTransactionRealtimePage] dispose called');
    _installmentController?.dispose();
    widget.controller.dispose();
    super.dispose();
  }

  /// Lazily create the installment controller when needed
  InstallmentController _getInstallmentController() {
    _installmentController ??= InstallmentController(
      datasource: InstallmentSupabaseDatasource(),
    );
    return _installmentController!;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '[DEBUG PreTransactionRealtimePage] build called - $_debugStatus',
    );
    debugPrint(
      '[DEBUG PreTransactionRealtimePage] isLoading: ${widget.controller.isLoading}',
    );
    debugPrint(
      '[DEBUG PreTransactionRealtimePage] hasError: ${widget.controller.hasError}',
    );
    debugPrint(
      '[DEBUG PreTransactionRealtimePage] transaction: ${widget.controller.transaction?.id}',
    );
    debugPrint(
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
          // Report button
          IconButton(
            onPressed: () => _showReportDialog(context),
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Report',
          ),
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
                tooltip: 'Refreshed',
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          // Suspension gate
          if (_isSuspended) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.block,
                      size: 64,
                      color: ColorConstants.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _suspensionMessage ?? 'You are suspended.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Policy declined gate
          if (!_policyAccepted && _debugStatus == 'policy declined') {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.policy,
                      size: 64,
                      color: ColorConstants.warning,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'You must accept the transaction policies to proceed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loadWithDebug,
                      child: const Text('Review Policies'),
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

          // Check if user needs to pay deposit first (both buyer and seller)
          if (!widget.controller.hasDeposited) {
            return DepositPaymentTab(
              controller: widget.controller,
              userId: widget.userId,
            );
          }

          // Check if dispute was resolved by admin
          if (transaction.isDisputeResolved &&
              transaction.status == TransactionStatus.cancelled) {
            final role = widget.controller.getUserRole(widget.userId);
            final isSeller = role == FormRole.seller;
            return _buildDisputeResolvedPage(transaction, isDark, isSeller);
          }

          // Check if deal is cancelled/failed
          if (transaction.status == TransactionStatus.cancelled) {
            final role = widget.controller.getUserRole(widget.userId);
            final isSeller = role == FormRole.seller;
            final buyerCancelled = transaction.cancelledBy == 'buyer';

            // Seller sees action options ONLY when buyer cancelled
            if (isSeller && buyerCancelled) {
              return _buildSellerDealFailedOptions(transaction, isDark);
            }

            // Both parties see immutable cancelled view when they are the canceller
            // or when viewing as buyer
            return _buildBuyerCancelledView(transaction, isDark);
          }

          final showInstallment =
              transaction.showInstallmentTab ||
              (_installmentController?.hasPlan ?? false);
          final tabCount = showInstallment ? 4 : 3;
          final userRole = widget.controller.getUserRole(widget.userId);

          return DefaultTabController(
            key: ValueKey('tabs_$tabCount'),
            length: tabCount,
            initialIndex: widget.initialTabIndex.clamp(0, tabCount - 1),
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
                    onTap: (index) {
                      switch (index) {
                        case 0:
                          widget.controller.clearChatUpdateCount();
                        case 1:
                          widget.controller.clearAgreementUpdateCount();
                        case 2:
                          widget.controller.clearProgressUpdateCount();
                        case 3:
                          widget.controller.clearGivesUpdateCount();
                      }
                    },
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
                      _buildTabWithBadge(
                        'Chat',
                        widget.controller.chatUpdateCount,
                      ),
                      _buildTabWithBadge(
                        'Form',
                        widget.controller.agreementUpdateCount,
                      ),
                      _buildTabWithBadge(
                        'Progress',
                        widget.controller.progressUpdateCount,
                      ),
                      if (showInstallment)
                        _buildTabWithBadge(
                          'Gives',
                          widget.controller.givesUpdateCount,
                        ),
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
                      UnifiedAgreementTab(
                        controller: widget.controller,
                        installmentController: _getInstallmentController(),
                        transactionId: transaction.id,
                        userId: widget.userId,
                      ),
                      ProgressRealtimeTab(
                        controller: widget.controller,
                        userId: widget.userId,
                        installmentController: showInstallment
                            ? _getInstallmentController()
                            : null,
                      ),
                      if (showInstallment)
                        InstallmentTrackerTab(
                          controller: _getInstallmentController(),
                          transactionController: widget.controller,
                          transactionId: transaction.id,
                          userId: widget.userId,
                          userRole: userRole,
                          bothConfirmed: transaction.bothConfirmed,
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
    final buyerCancelled = transaction.cancelledBy == 'buyer';

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
            transaction.buyerAcceptanceStatus == BuyerAcceptanceStatus.rejected
                ? 'The buyer has rejected the delivery. You can raise a dispute if you believe this is unfair, or proceed with other options.'
                : buyerCancelled
                ? 'The buyer has cancelled this transaction. You can choose how to proceed with your listing.'
                : 'This transaction has been cancelled. You can choose how to proceed with your listing.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),

          // Show buyer rejection reason if available
          if (transaction.buyerAcceptanceStatus ==
                  BuyerAcceptanceStatus.rejected &&
              transaction.buyerRejectionReason != null &&
              transaction.buyerRejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorConstants.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: ColorConstants.error.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: ColorConstants.error,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Buyer\'s Rejection Reason',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ColorConstants.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    transaction.buyerRejectionReason!,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? ColorConstants.textSecondaryDark
                          : ColorConstants.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
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

                // Option 0: Raise Dispute (only when buyer rejected delivery)
                if (transaction.buyerAcceptanceStatus ==
                    BuyerAcceptanceStatus.rejected) ...[
                  _buildSellerOption(
                    icon: Icons.gavel,
                    title: 'Raise Dispute',
                    description:
                        'Object to the buyer\'s rejection — an admin will review',
                    color: Colors.orange,
                    isDark: isDark,
                    onTap: () => _showRaiseDisputeDialog(transaction),
                  ),
                  const SizedBox(height: 12),
                ],

                // Option 1: Proceed to next bidder
                _buildSellerOption(
                  icon: Icons.skip_next_rounded,
                  title: 'Proceed to Next Bidder',
                  description:
                      'Offer to the next highest eligible bidder (skips same user)',
                  color: ColorConstants.primary,
                  isDark: isDark,
                  onTap: () => _showAutoReselectDialog(),
                ),
                const SizedBox(height: 12),

                // Option 2: Relist auction
                _buildSellerOption(
                  icon: Icons.refresh,
                  title: 'Restart Bidding',
                  description: 'Clear all bids and start a new auction round',
                  color: ColorConstants.info,
                  isDark: isDark,
                  onTap: () => _showRestartBiddingDialog(),
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

  /// Build detailed buyer cancellation view showing transaction record
  Widget _buildBuyerCancelledView(TransactionEntity transaction, bool isDark) {
    final reason = transaction.cancellationReason;
    final cancelledByLabel = transaction.cancelledBy == 'buyer'
        ? 'You'
        : transaction.cancelledBy == 'seller'
        ? 'Seller'
        : 'Unknown';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header icon
          Icon(Icons.cancel_outlined, size: 64, color: ColorConstants.error),
          const SizedBox(height: 16),
          const Text(
            'Deal Cancelled',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Car details card
          Container(
            width: double.infinity,
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
                // Car image
                if (transaction.carImageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      transaction.carImageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.directions_car, size: 48),
                        ),
                      ),
                    ),
                  ),
                if (transaction.carImageUrl.isNotEmpty)
                  const SizedBox(height: 16),

                // Car name
                Text(
                  transaction.carName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Details rows
                _buildDetailRow(
                  icon: Icons.attach_money,
                  label: 'Agreed Price',
                  value: '₱${transaction.agreedPrice.toStringAsFixed(2)}',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  icon: Icons.person,
                  label: 'Cancelled By',
                  value: cancelledByLabel,
                  isDark: isDark,
                  valueColor: ColorConstants.error,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  icon: Icons.calendar_today,
                  label: 'Transaction Date',
                  value: _formatDate(transaction.createdAt),
                  isDark: isDark,
                ),

                // Cancellation reason
                if (reason != null && reason.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColorConstants.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: ColorConstants.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: ColorConstants.error,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Cancellation Reason',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: ColorConstants.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          reason,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? ColorConstants.textSecondaryDark
                                : ColorConstants.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: ColorConstants.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'TRANSACTION CLOSED',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: ColorConstants.error,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Go back button
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  /// Build a detail row for the buyer cancelled view
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark
              ? ColorConstants.textSecondaryDark
              : ColorConstants.textSecondaryLight,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? ColorConstants.textSecondaryDark
                : ColorConstants.textSecondaryLight,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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
      (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
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
          (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
            SnackBar(
              content: Text(
                'Transaction offered to ${selectedBidder['bidder_name']}',
              ),
              backgroundColor: ColorConstants.success,
            ),
          );
        } else {
          (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
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
          (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
            const SnackBar(
              content: Text('Auction relisted successfully'),
              backgroundColor: ColorConstants.success,
            ),
          );
          Navigator.pop(context);
        } else {
          (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
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
          (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
            const SnackBar(
              content: Text('Auction deleted successfully'),
              backgroundColor: ColorConstants.success,
            ),
          );
          Navigator.pop(context);
        } else {
          (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
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

  Future<void> _showAutoReselectDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.skip_next_rounded, color: ColorConstants.primary),
            const SizedBox(width: 12),
            const Expanded(child: Text('Proceed to Next Bidder')),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The transaction will be offered to the next highest bidder. If the same user placed multiple bids, they will be skipped.',
            ),
            SizedBox(height: 16),
            Text(
              'This process continues down the bidder list until a different eligible user is found.',
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
            style: FilledButton.styleFrom(
              backgroundColor: ColorConstants.primary,
            ),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final newTxnId = await widget.controller.autoReselectNextWinner();

      if (mounted) {
        if (newTxnId != null) {
          (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
            const SnackBar(
              content: Text('Next winner selected successfully'),
              backgroundColor: ColorConstants.success,
            ),
          );
          // Navigate to the new transaction (replace current page)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PreTransactionRealtimePage(
                controller: TransactionRealtimeController(
                  widget.controller.dataSource,
                ),
                transactionId: newTxnId,
                userId: widget.userId,
                userName: widget.userName,
              ),
            ),
          );
        } else {
          (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
            SnackBar(
              content: Text(
                widget.controller.errorMessage ??
                    'No eligible next bidder found',
              ),
              backgroundColor: ColorConstants.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _showRestartBiddingDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.refresh, color: ColorConstants.info),
            const SizedBox(width: 12),
            const Text('Restart Bidding'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will clear all existing bids and restart the auction from scratch.',
            ),
            SizedBox(height: 16),
            Text(
              'All previous bids and transaction data will be permanently removed.',
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
            style: FilledButton.styleFrom(backgroundColor: ColorConstants.info),
            child: const Text('Restart'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await widget.controller.restartAuctionBidding();

      if (mounted) {
        if (success) {
          (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
            const SnackBar(
              content: Text('Bidding restarted successfully'),
              backgroundColor: ColorConstants.success,
            ),
          );
          Navigator.pop(context);
        } else {
          (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
            SnackBar(
              content: Text(
                widget.controller.errorMessage ?? 'Failed to restart bidding',
              ),
              backgroundColor: ColorConstants.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _showSuspensionAndSignOut(SuspensionStatus suspension) async {
    final message = suspension.isPermanent
        ? 'Your account has been permanently banned due to repeated policy violations.'
        : 'Your account has been suspended until ${suspension.endsAt?.toLocal().toString().split('.').first ?? 'unknown'} for violating transaction policies.';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.block, color: ColorConstants.error),
            const SizedBox(width: 12),
            const Text('Account Suspended'),
          ],
        ),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: ColorConstants.error,
            ),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );

    if (mounted) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AuthRoutes.login, (route) => false);
      }
    }
  }

  Widget _buildTabWithBadge(String label, int updateCount) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (updateCount > 0) ...[
            const SizedBox(width: 4),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final transaction = widget.controller.transaction;
    if (transaction == null) return;

    final reasonController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedReason = 'Fraud';
    final reasons = [
      'Fraud',
      'Harassment',
      'Misrepresentation',
      'Non-payment',
      'Non-delivery',
      'Other',
    ];

    // Determine reported user
    final isSeller = transaction.sellerId == widget.userId;
    final reportedUserId = isSeller
        ? transaction.buyerId
        : transaction.sellerId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Report Transaction'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select a reason:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedReason,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: reasons
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => selectedReason = v);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Describe the issue...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (descriptionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please provide a description'),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                try {
                  final datasource = TransactionSupabaseDataSource(
                    Supabase.instance.client,
                  );
                  await datasource.submitReport(
                    transactionId: transaction.id,
                    reporterId: widget.userId,
                    reportedUserId: reportedUserId,
                    reason: selectedReason,
                    description: descriptionController.text.trim(),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Report submitted successfully'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to submit report: $e')),
                    );
                  }
                }
              },
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
    reasonController.dispose();
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
      text = 'Transaction Finalized - Proceed with delivery';
    } else if (transaction.bothFormsSubmitted && transaction.bothConfirmed) {
      bgColor = ColorConstants.warning.withValues(alpha: 0.1);
      textColor = ColorConstants.warning;
      icon = Icons.timer;
      text = 'Both confirmed - Finalizing shortly...';
    } else if (transaction.bothFormsSubmitted) {
      bgColor = ColorConstants.info.withValues(alpha: 0.1);
      textColor = ColorConstants.info;
      icon = Icons.rate_review;
      text = 'Agreement locked - Review and confirm';
    } else {
      bgColor = ColorConstants.primary.withValues(alpha: 0.1);
      textColor = ColorConstants.primary;
      icon = Icons.edit_document;
      text = 'Collaborate on the transaction agreement';
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

  /// Build page shown after admin resolves a dispute
  Widget _buildDisputeResolvedPage(
    TransactionEntity transaction,
    bool isDark,
    bool isSeller,
  ) {
    final resolution = transaction.disputeResolution;
    final isRefundBoth = resolution == 'refund_both';
    final isPenalizeSeller = resolution == 'penalize_seller';
    final isPenalizeBuyer = resolution == 'penalize_buyer';

    // Determine if current user is the penalized one
    final currentUserPenalized =
        (isSeller && isPenalizeSeller) || (!isSeller && isPenalizeBuyer);

    // Resolution header info
    String title;
    String description;
    IconData icon;
    Color color;

    if (isRefundBoth) {
      title = 'Dispute Resolved';
      description = 'Both deposits have been refunded. No party was penalized.';
      icon = Icons.handshake;
      color = Colors.blue;
    } else if (currentUserPenalized) {
      title = 'Account Suspended';
      description =
          'You were found at fault in this dispute. Your account has been suspended and both deposits were refunded.';
      icon = Icons.block;
      color = ColorConstants.error;
    } else {
      // Unpenalized party
      final faultyParty = isPenalizeSeller ? 'seller' : 'buyer';
      title = 'Dispute Resolved in Your Favor';
      description =
          'The $faultyParty was found at fault. Both deposits have been refunded.';
      icon = Icons.verified;
      color = ColorConstants.success;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, size: 64, color: color),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),

          // Admin notes
          if (transaction.disputeAdminNotes != null &&
              transaction.disputeAdminNotes!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        size: 16,
                        color: Colors.blue,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Admin Notes',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    transaction.disputeAdminNotes!,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? ColorConstants.textSecondaryDark
                          : ColorConstants.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Seller who is NOT penalized gets 3 action options
          if (isSeller && !currentUserPenalized) ...[
            const SizedBox(height: 32),
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
                  _buildSellerOption(
                    icon: Icons.skip_next_rounded,
                    title: 'Proceed to Next Bidder',
                    description: 'Offer to the next highest eligible bidder',
                    color: ColorConstants.primary,
                    isDark: isDark,
                    onTap: () => _showAutoReselectDialog(),
                  ),
                  const SizedBox(height: 12),
                  _buildSellerOption(
                    icon: Icons.refresh,
                    title: 'Restart Bidding',
                    description: 'Clear all bids and start a new auction round',
                    color: ColorConstants.info,
                    isDark: isDark,
                    onTap: () => _showRestartBiddingDialog(),
                  ),
                  const SizedBox(height: 12),
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
          ],

          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  /// Dialog for seller to raise dispute against buyer rejection
  Future<void> _showRaiseDisputeDialog(TransactionEntity transaction) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.gavel, color: Colors.orange),
            SizedBox(width: 8),
            Text('Raise Dispute'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Explain why you believe the buyer\'s rejection is unjustified. '
              'An admin will review the full conversation and evidence.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Your objection reason',
                hintText: 'Describe why the rejection is unfair...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, true);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Submit Dispute'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await widget.controller.raiseSellerObjection(
        reason: reasonController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Dispute raised. An admin will review your case.'
                  : widget.controller.errorMessage ??
                        'Failed to raise dispute. Please try again.',
            ),
            backgroundColor: success ? Colors.orange : ColorConstants.error,
          ),
        );
      }
    }

    reasonController.dispose();
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
