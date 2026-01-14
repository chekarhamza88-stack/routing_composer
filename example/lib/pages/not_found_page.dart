/// 404 Not Found page.
library;

import 'package:flutter/material.dart';
import 'package:routing_composer/routing_composer.dart';

/// 404 error screen shown when a route is not found.
class NotFoundPage extends StatelessWidget {
  final AppRouter router;

  const NotFoundPage({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Not Found'),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            const Text('404 - Page Not Found', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            const Text(
              'The page you requested could not be found.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => router.clearStackAndGoTo(AppRoutes.home),
              icon: const Icon(Icons.home),
              label: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
