import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../controllers/transaction_realtime_controller.dart';
import '../../domain/entities/transaction_entity.dart';
import '../widgets/transaction_realtime/chat_realtime_tab.dart';
import '../widgets/transaction_realtime/my_form_realtime_tab.dart';
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
  @override
  void initState() {
    super.initState();
    widget.controller.loadTransaction(widget.transactionId, widget.userId);
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading transaction...'),
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
                      MyFormRealtimeTab(
                        controller: widget.controller,
                        userId: widget.userId,
                      ),
                      OtherFormRealtimeTab(
                        controller: widget.controller,
                        userId: widget.userId,
                      ),
                      ProgressRealtimeTab(controller: widget.controller),
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

  Widget _buildStatusBanner(TransactionEntity transaction, bool isDark) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String text;

    if (transaction.adminApproved) {
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
