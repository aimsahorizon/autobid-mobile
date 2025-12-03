import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../../../../app/core/controllers/theme_controller.dart';
import '../controllers/guest_controller.dart';
import '../widgets/guest_browse_tab.dart';
import '../widgets/account_status_tab.dart';

class GuestPage extends StatefulWidget {
  final GuestController controller;
  final ThemeController themeController;

  const GuestPage({
    super.key,
    required this.controller,
    required this.themeController,
  });

  @override
  State<GuestPage> createState() => _GuestPageState();
}

class _GuestPageState extends State<GuestPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    widget.controller.loadGuestAuctions();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    widget.controller.setTabIndex(_tabController.index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guest Mode'),
        actions: [
          _buildDataSourceMenu(),
          _buildThemeToggle(),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.grid_view_rounded),
              text: 'Browse',
            ),
            Tab(
              icon: Icon(Icons.verified_user_outlined),
              text: 'Account Status',
            ),
          ],
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: isDark
              ? ColorConstants.textSecondaryDark
              : ColorConstants.textSecondaryLight,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          GuestBrowseTab(controller: widget.controller),
          AccountStatusTab(controller: widget.controller),
        ],
      ),
      floatingActionButton: _buildLoginFab(theme),
    );
  }

  Widget _buildDataSourceMenu() {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          tooltip: 'Data Source Options',
          onSelected: (value) {
            if (value == 'toggle') {
              widget.controller.toggleDataSource();
              final dataSource = widget.controller.useMockData ? 'Mock Data' : 'Database';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Switched to $dataSource'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: widget.controller.useMockData
                      ? Colors.orange
                      : Colors.green,
                ),
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    widget.controller.useMockData
                        ? Icons.cloud_outlined
                        : Icons.dataset_outlined,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.controller.useMockData
                        ? 'Switch to Database'
                        : 'Switch to Mock Data',
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              enabled: false,
              child: Row(
                children: [
                  Icon(
                    widget.controller.useMockData
                        ? Icons.info_outline
                        : Icons.check_circle_outline,
                    size: 16,
                    color: widget.controller.useMockData
                        ? Colors.orange
                        : Colors.green,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Current: ${widget.controller.useMockData ? "Mock" : "Database"}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: widget.controller.useMockData
                          ? Colors.orange
                          : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemeToggle() {
    return ListenableBuilder(
      listenable: widget.themeController,
      builder: (context, _) {
        return IconButton(
          icon: Icon(
            widget.themeController.isDarkMode
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
          ),
          onPressed: widget.themeController.toggleTheme,
        );
      },
    );
  }

  Widget _buildLoginFab(ThemeData theme) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.of(context).pop();
      },
      icon: const Icon(Icons.login_rounded),
      label: const Text('Sign In'),
      backgroundColor: theme.colorScheme.primary,
    );
  }
}
