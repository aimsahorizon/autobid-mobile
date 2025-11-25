import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../controllers/transaction_controller.dart';
import '../controllers/seller_transaction_demo_controller.dart';
import '../widgets/transaction/chat_tab.dart';
import '../widgets/transaction/my_form_tab.dart';
import '../widgets/transaction/buyer_form_tab.dart';
import '../widgets/transaction/progress_tab.dart';

class PreTransactionPage extends StatefulWidget {
  final TransactionController controller;
  final String transactionId;
  final String userId;
  final String userName;

  const PreTransactionPage({
    super.key,
    required this.controller,
    required this.transactionId,
    required this.userId,
    required this.userName,
  });

  @override
  State<PreTransactionPage> createState() => _PreTransactionPageState();
}

class _PreTransactionPageState extends State<PreTransactionPage> {
  late SellerTransactionDemoController _demoController;

  @override
  void initState() {
    super.initState();
    _demoController = SellerTransactionDemoController(
      widget.controller,
      widget.userId,
      widget.userName,
    );
    widget.controller.loadTransaction(widget.transactionId, widget.userId);
  }

  @override
  void dispose() {
    _demoController.dispose();
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pre-Transaction'),
                if (transaction != null)
                  Text(
                    transaction.carName,
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
          // Demo auto-play button
          ListenableBuilder(
            listenable: _demoController,
            builder: (context, _) {
              return IconButton(
                onPressed: _demoController.isPlaying ? null : () => _demoController.startDemo(),
                icon: _demoController.isPlaying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_circle_outline),
                tooltip: _demoController.isPlaying ? _demoController.currentStep : 'Demo Auto-Play',
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (widget.controller.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(widget.controller.errorMessage ?? 'An error occurred'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => widget.controller.loadTransaction(
                      widget.transactionId,
                      widget.userId,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final transaction = widget.controller.transaction;
          if (transaction == null) {
            return const Center(child: Text('Transaction not found'));
          }

          return DefaultTabController(
            length: 4,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
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
                      fontSize: 13,
                    ),
                    tabs: const [
                      Tab(text: 'Chat'),
                      Tab(text: 'My Form'),
                      Tab(text: 'Buyer Form'),
                      Tab(text: 'Progress'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      ChatTab(
                        controller: widget.controller,
                        userId: widget.userId,
                        userName: widget.userName,
                      ),
                      MyFormTab(
                        controller: widget.controller,
                        userId: widget.userId,
                      ),
                      BuyerFormTab(
                        controller: widget.controller,
                        userId: widget.userId,
                      ),
                      ProgressTab(controller: widget.controller),
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
}
