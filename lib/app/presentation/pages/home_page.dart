import 'package:flutter/material.dart';
import '../../../modules/browse/presentation/pages/browse_page.dart';
import '../../../modules/bids/presentation/pages/bids_page.dart';
import '../../../modules/lists/presentation/pages/lists_page.dart';
import '../../../modules/profile/presentation/pages/profile_page.dart';
import '../../core/widgets/main_navigation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const BrowsePage(),
    const BidsPage(),
    const ListsPage(),
    const ProfilePage(),
  ];

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
