import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../controllers/admin_controller.dart';
import '../controllers/kyc_controller.dart';
import '../controllers/admin_transaction_controller.dart';
import '../../admin_module.dart';
import 'admin_dashboard_page.dart';
import 'admin_listings_page.dart';
import 'admin_users_page.dart';
import 'admin_kyc_page.dart';
import 'admin_auction_monitor_page.dart';
import 'admin_transactions_page.dart';

/// Main admin page with tabs for different admin functions
class AdminMainPage extends StatefulWidget {
  final AdminController controller;
  final KycController kycController;

  const AdminMainPage({
    super.key,
    required this.controller,
    required this.kycController,
  });

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AdminTransactionController? _transactionController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _initTransactionController();
  }

  void _initTransactionController() {
    try {
      // Ensure module is initialized
      AdminModule.instance.initialize();
      _transactionController = AdminModule.instance.transactionController;
      print('[AdminMainPage] Transaction controller initialized successfully');
    } catch (e) {
      print('[AdminMainPage] Error initializing transaction controller: $e');
      // Try again with setState to trigger rebuild
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            try {
              AdminModule.instance.initialize();
              _transactionController =
                  AdminModule.instance.transactionController;
            } catch (e2) {
              print('[AdminMainPage] Retry failed: $e2');
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleBackNavigation() {
    final supabase = Supabase.instance.client;
    final isAuthenticated = supabase.auth.currentUser != null;

    if (isAuthenticated) {
      // User is authenticated, navigate back to home/main screen
      Navigator.pop(context);
    } else {
      // User is not authenticated, navigate to login
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  void _handleLogout() async {
    try {
      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout from admin panel?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Sign out from Supabase
      final supabase = Supabase.instance.client;
      await supabase.auth.signOut();

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to login page - clear all routes
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      if (!mounted) return;

      // Close loading if open
      Navigator.pop(context);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: ColorConstants.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back),
        //   onPressed: _handleBackNavigation,
        //   tooltip: 'Exit Admin Panel',
        // ),
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, size: 24),
            SizedBox(width: 8),
            Text('Admin Panel'),
          ],
        ),
        backgroundColor: ColorConstants.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => widget.controller.refresh(),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.list_alt), text: 'Listings'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.verified_user), text: 'KYC'),
            Tab(icon: Icon(Icons.gavel), text: 'Bid Monitor'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Transactions'),
            Tab(icon: Icon(Icons.analytics), text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AdminDashboardPage(controller: widget.controller),
          AdminListingsPage(controller: widget.controller),
          AdminUsersPage(controller: widget.controller),
          AdminKycPage(controller: widget.kycController),
          AuctionMonitorPage(
            controller: AdminModule.instance.monitorController,
          ),
          _transactionController != null
              ? AdminTransactionsPage(controller: _transactionController!)
              : _buildTransactionErrorTab(),
          _buildComingSoonTab('Reports & Analytics'),
        ],
      ),
    );
  }

  Widget _buildComingSoonTab(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: ColorConstants.textSecondaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: TextStyle(
              fontSize: 16,
              color: ColorConstants.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionErrorTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: ColorConstants.error),
          const SizedBox(height: 16),
          const Text(
            'Transaction Module',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to initialize. Tap to retry.',
            style: TextStyle(
              fontSize: 16,
              color: ColorConstants.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              setState(() {
                _initTransactionController();
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
