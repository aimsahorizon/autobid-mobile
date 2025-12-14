import 'package:flutter/material.dart';
import '../../../modules/browse/browse_module.dart';
import '../../../modules/browse/presentation/pages/browse_page.dart';
import '../../../modules/bids/bids_module.dart';
import '../../../modules/bids/presentation/pages/bids_page.dart';
import '../../../modules/transactions/transactions_module.dart';
import '../../../modules/transactions/presentation/pages/transactions_status_page.dart';
import '../../../modules/lists/lists_module.dart';
import '../../../modules/lists/presentation/pages/lists_page.dart';
import '../../../modules/notifications/notifications_module.dart';
import '../../../modules/profile/profile_module.dart';
import '../../../modules/profile/presentation/pages/profile_page.dart';
import '../../core/config/supabase_config.dart';
import '../../core/controllers/theme_controller.dart';
import '../../core/widgets/main_navigation.dart';

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
      BrowsePage(controller: BrowseModule.instance.createBrowseController()),
      BidsPage(controller: BidsModule.instance.createBidsController()),
      const TransactionsStatusPage(),
      ListsPage(controller: ListsModule.controller),
      ProfilePage(
        controller: ProfileModule.instance.controller,
        pricingController: ProfileModule.instance.createPricingController(),
        themeController: widget.themeController,
      ),
    ];
  }

  /// Initialize notifications and load initial data
  void _initializeNotifications() {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId != null) {
      final notificationController = NotificationsModule.instance.controller;
      notificationController.loadNotifications(userId);
      notificationController.loadUnreadCount(userId);
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
