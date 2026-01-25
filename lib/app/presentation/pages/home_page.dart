import 'package:flutter/material.dart';
import '../../../modules/browse/presentation/pages/browse_page.dart';
import '../../../modules/browse/presentation/controllers/browse_controller.dart';
import '../../../modules/bids/presentation/pages/bids_page.dart';
import '../../../modules/bids/presentation/controllers/bids_controller.dart';
import '../../../modules/transactions/presentation/pages/transactions_status_page.dart';
import '../../../modules/transactions/presentation/controllers/buyer_seller_transactions_controller.dart';
import '../../../modules/lists/presentation/pages/lists_page.dart';
import '../../../modules/lists/presentation/controllers/lists_controller.dart';
import '../../../modules/notifications/presentation/controllers/notification_controller.dart';
import '../../../modules/profile/presentation/pages/profile_page.dart';
import '../../../modules/profile/presentation/controllers/profile_controller.dart';
import '../../../modules/profile/presentation/controllers/pricing_controller.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/controllers/theme_controller.dart';
import '../../../core/widgets/main_navigation.dart';
import '../../di/app_module.dart';

class HomePage extends StatefulWidget {
  final ThemeController themeController;

  const HomePage({super.key, required this.themeController});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // Initialize notification controller and load initial data
    _initializeNotifications();

    _pages = [
      BrowsePage(controller: sl<BrowseController>()),
      BidsPage(controller: sl<BidsController>()),
      TransactionsStatusPage(
        controller: sl<BuyerSellerTransactionsController>(),
      ),
      ListsPage(controller: sl<ListsController>()),
      ProfilePage(
        controller: sl<ProfileController>(),
        pricingController: sl<PricingController>(),
        themeController: widget.themeController,
      ),
    ];
  }

  /// Initialize notifications and load initial data
  void _initializeNotifications() {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId != null) {
      final notificationController = sl<NotificationController>();
      notificationController.loadNotifications(userId);
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: MainNavigation(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
