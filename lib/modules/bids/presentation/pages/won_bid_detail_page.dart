import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../../domain/entities/buyer_transaction_entity.dart';
import '../../data/datasources/buyer_transaction_mock_datasource.dart';
import '../controllers/buyer_transaction_controller.dart';
import '../controllers/transaction_demo_controller.dart';
import '../widgets/won_bid/transaction_header.dart';
import '../widgets/won_bid/transaction_chat_tab.dart';
import '../widgets/won_bid/transaction_my_form_tab.dart';
import '../widgets/won_bid/transaction_seller_form_tab.dart';
import '../widgets/won_bid/transaction_progress_tab.dart';

class WonBidDetailPage extends StatefulWidget {
  final String auctionId;

  const WonBidDetailPage({
    super.key,
    required this.auctionId,
  });

  @override
  State<WonBidDetailPage> createState() => _WonBidDetailPageState();
}

class _WonBidDetailPageState extends State<WonBidDetailPage>
    with SingleTickerProviderStateMixin {
  late BuyerTransactionController _controller;
  late TransactionDemoController _demoController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controller = BuyerTransactionController(BuyerTransactionMockDataSource());
    _demoController = TransactionDemoController(_controller);
    _tabController = TabController(length: 4, vsync: this);
    _controller.loadTransaction(widget.auctionId, 'buyer_current');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _demoController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Won Auction'),
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
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.transaction == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: ColorConstants.error),
                  const SizedBox(height: 16),
                  Text('Transaction not found', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              TransactionHeader(transaction: _controller.transaction!),
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? ColorConstants.backgroundDark
                      : ColorConstants.backgroundSecondaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  padding: const EdgeInsets.all(4),
                  indicator: BoxDecoration(
                    color: isDark ? ColorConstants.surfaceDark : Colors.white,
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
                    Tab(text: 'Seller Form'),
                    Tab(text: 'Progress'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    TransactionChatTab(controller: _controller),
                    TransactionMyFormTab(controller: _controller),
                    TransactionSellerFormTab(controller: _controller),
                    TransactionProgressTab(controller: _controller),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
