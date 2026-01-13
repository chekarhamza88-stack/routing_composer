/// User profile page displaying user information.
library;

import 'package:flutter/material.dart';
import 'package:routing_composer/routing_composer.dart';

import '../widgets/common/common.dart';

/// User profile screen showing user details and tab navigation.
class UserProfilePage extends StatelessWidget {
  final AppRouter router;
  final String userId;
  final String? tab;

  const UserProfilePage({
    super.key,
    required this.router,
    required this.userId,
    this.tab,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile: $userId'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => router.goBack(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 50,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text('User ID: $userId', style: const TextStyle(fontSize: 18)),
            if (tab != null)
              Text('Tab: $tab', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              children: [
                TabChip(label: 'Overview', isSelected: tab == null),
                TabChip(label: 'Posts', isSelected: tab == 'posts'),
                TabChip(label: 'Likes', isSelected: tab == 'likes'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
