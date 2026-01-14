/// Notifications page displaying a list of notifications.
library;

import 'package:flutter/material.dart';
import 'package:routing_composer/routing_composer.dart';

/// Notifications screen showing a list of notification items.
class NotificationsPage extends StatelessWidget {
  final AppRouter router;

  const NotificationsPage({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) => ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.notifications,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          title: Text('Notification ${index + 1}'),
          subtitle: const Text('Tap to view user details'),
          onTap: () => router.goTo(
            AppRoutes.userProfile,
            params: UserProfileParams(userId: 'user_${index + 1}'),
          ),
        ),
      ),
    );
  }
}
