/// Main shell widget with bottom navigation for GoRouter.
library;

import 'package:flutter/material.dart';
import 'package:routing_composer/routing_composer.dart';

/// Shell widget providing bottom navigation for the main app screens.
///
/// This version is for GoRouter which uses a generic state parameter.
class MainShell extends StatefulWidget {
  final AppRouter router;
  final Widget child;

  const MainShell({
    super.key,
    required this.router,
    required this.child,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    widget.router.switchToTab(index);

    final routes = [
      AppRoutes.home,
      AppRoutes.search,
      AppRoutes.notifications,
      AppRoutes.settings,
    ];

    widget.router.goTo(routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
