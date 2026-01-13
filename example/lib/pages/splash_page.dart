/// Splash page shown during app initialization.
library;

import 'package:flutter/material.dart';
import 'package:routing_composer/routing_composer.dart';
import '../core/services/auth_service.dart';

/// Splash screen that checks authentication state and redirects accordingly.
class SplashPage extends StatefulWidget {
  final AppRouter router;
  final ExampleAuthService authService;

  const SplashPage({
    super.key,
    required this.router,
    required this.authService,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));

    if (widget.authService.isAuthenticated) {
      await widget.router.goTo(AppRoutes.home);
    } else {
      await widget.router.goTo(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Routing Composer'),
            Text('Loading...', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
