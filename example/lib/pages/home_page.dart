/// Home page displaying navigation options.
library;

import 'package:flutter/material.dart';
import 'package:routing_composer/routing_composer.dart';
import '../widgets/common/common.dart';

/// Home screen showing various navigation demonstrations.
class HomePage extends StatelessWidget {
  final AppRouter router;

  /// Optional info card configuration for adapter-specific messaging.
  final InfoCardConfig? infoCard;

  const HomePage({super.key, required this.router, this.infoCard});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (infoCard != null)
            InfoCard(
              icon: infoCard!.icon,
              title: infoCard!.title,
              description: infoCard!.description,
            ),
          if (infoCard != null) const SizedBox(height: 16),
          NavigationCard(
            title: 'User Profile',
            subtitle: 'Navigate with path params',
            icon: Icons.person,
            onTap:
                () => router.goTo(
                  AppRoutes.userProfile,
                  params: const UserProfileParams(
                    userId: 'user_123',
                    tab: 'posts',
                  ),
                ),
          ),
          NavigationCard(
            title: 'Search',
            subtitle: 'Navigate with query params',
            icon: Icons.search,
            onTap:
                () => router.goTo(
                  AppRoutes.search,
                  params: const SearchParams(
                    query: 'flutter',
                    category: 'apps',
                  ),
                ),
          ),
          NavigationCard(
            title: 'Settings',
            subtitle: 'Simple navigation',
            icon: Icons.settings,
            onTap: () => router.goTo(AppRoutes.settings),
          ),
          NavigationCard(
            title: 'Deep Link Test',
            subtitle: 'Handle /user/456?tab=likes',
            icon: Icons.link,
            onTap:
                () => router.handleDeepLink(Uri.parse('/user/456?tab=likes')),
          ),
          NavigationCard(
            title: '404 Page',
            subtitle: 'Navigate to unknown route',
            icon: Icons.error_outline,
            onTap: () => router.goToPath('/unknown/route'),
          ),
        ],
      ),
    );
  }
}

/// Configuration for the info card displayed on the home page.
class InfoCardConfig {
  final IconData icon;
  final String title;
  final String description;

  const InfoCardConfig({
    required this.icon,
    required this.title,
    required this.description,
  });
}
