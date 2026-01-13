/// Main shell widget with bottom navigation for AutoRoute.
library;

import 'package:flutter/material.dart';
import 'package:routing_composer/routing_composer.dart';

/// Shell widget providing bottom navigation for the main app screens.
///
/// This version is for AutoRoute which provides [AutoRouteShellData] with
/// current route information for proper tab synchronization.
class MainShellAutoRoute extends StatefulWidget {
  final AppRouter router;
  final AutoRouteShellData shellData;
  final Widget child;

  const MainShellAutoRoute({
    super.key,
    required this.router,
    required this.shellData,
    required this.child,
  });

  @override
  State<MainShellAutoRoute> createState() => _MainShellAutoRouteState();
}

class _MainShellAutoRouteState extends State<MainShellAutoRoute> {
  int _selectedIndex = 0;

  @override
  void didUpdateWidget(MainShellAutoRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update selected index based on current route from shell data
    _updateSelectedIndex();
  }

  void _updateSelectedIndex() {
    final currentRoute = widget.shellData.currentRoute;
    if (currentRoute != null) {
      final newIndex = switch (currentRoute.name) {
        'home' => 0,
        'search' => 1,
        'notifications' => 2,
        'settings' => 3,
        _ => _selectedIndex,
      };
      if (newIndex != _selectedIndex) {
        setState(() => _selectedIndex = newIndex);
      }
    }
  }

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
