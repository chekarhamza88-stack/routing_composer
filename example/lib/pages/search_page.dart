/// Search page for query-based navigation demo.
library;

import 'package:flutter/material.dart';
import 'package:routing_composer/routing_composer.dart';

/// Search screen demonstrating query parameter handling.
class SearchPage extends StatelessWidget {
  final AppRouter router;
  final String? query;

  const SearchPage({super.key, required this.router, this.query});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            if (query != null)
              Text(
                'Searching for: $query',
                style: const TextStyle(fontSize: 18),
              )
            else
              const Text(
                'Enter a search query',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
