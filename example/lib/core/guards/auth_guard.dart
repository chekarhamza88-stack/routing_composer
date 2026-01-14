/// Shared authentication guard for the example application.
library;

import 'package:routing_composer/routing_composer.dart';
import '../services/auth_service.dart';

/// Authentication guard that protects routes requiring authentication.
///
/// Routes with `requiresAuth: true` will be redirected to login if
/// the user is not authenticated.
class ExampleAuthGuard implements RouteGuard {
  final ExampleAuthService _authService;

  ExampleAuthGuard(this._authService);

  @override
  String get name => 'ExampleAuthGuard';

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    // Allow public routes
    if (!context.destination.requiresAuth) {
      return const GuardAllow();
    }

    // Check authentication
    if (_authService.isAuthenticated) {
      return const GuardAllow();
    }

    // Redirect to login
    return const GuardRedirect(AppRoutes.login);
  }
}
