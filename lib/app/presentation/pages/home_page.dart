import 'package:flutter/material.dart';
import '../../../modules/browse/browse_module.dart';
import '../../../modules/browse/presentation/pages/browse_page.dart';
import '../../../modules/bids/bids_module.dart';
import '../../../modules/bids/presentation/pages/bids_page.dart';
import '../../../modules/lists/lists_module.dart';
import '../../../modules/lists/presentation/pages/lists_page.dart';
import '../../../modules/profile/profile_module.dart';
import '../../../modules/profile/presentation/pages/profile_page.dart';
import '../../core/controllers/theme_controller.dart';
import '../../core/widgets/main_navigation.dart';

class HomePage extends StatefulWidget {
  final ThemeController themeController;

  const HomePage({
    super.key,
    required this.themeController,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      BrowsePage(
        controller: BrowseModule.instance.createBrowseController(),
      ),
      BidsPage(
        controller: BidsModule.instance.createBidsController(),
      ),
      ListsPage(controller: ListsModule.controller),
      ProfilePage(
        controller: ProfileModule.instance.createProfileController(),
        themeController: widget.themeController,
      ),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: MainNavigation(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
