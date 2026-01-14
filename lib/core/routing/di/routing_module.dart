import 'package:flutter/widgets.dart';

import '../adapters/adapters.dart';
import '../domain/domain.dart';
import '../routes/app_routes.dart';

// ═══════════════════════════════════════════════════════════════════
// FACTORY FUNCTION (Framework Agnostic)
// ═══════════════════════════════════════════════════════════════════

/// Creates and configures the application router.
///
/// This factory function can be used with any DI framework.
/// It encapsulates all router configuration in one place.
///
/// [pageBuilder] - Function to build page widgets for routes
/// [shellBuilder] - Optional builder for shell/bottom navigation
/// [guards] - Additional route guards
/// [observers] - Navigation observers
/// [navigatorKey] - Optional navigator key for testing
AppRouter createAppRouter({
  required PageBuilder pageBuilder,
  GoRouterShellBuilder? shellBuilder,
  List<RouteGuard> guards = const [],
  List<NavigationObserver> observers = const [],
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return GoRouterAdapter(
    configuration: RouterConfiguration(
      routes: AppRoutes.all,
      initialRoute: AppRoutes.splash,
      notFoundRoute: AppRoutes.notFound,
      globalGuards: guards,
      observers: observers,
    ),
    pageBuilder: pageBuilder,
    shellBuilder: shellBuilder,
    navigatorKey: navigatorKey,
  );
}

/// Creates an in-memory router for testing.
///
/// [guards] - Optional guards to test guard behavior
/// [observers] - Optional observers to verify navigation events
InMemoryAdapter createTestRouter({
  List<RouteGuard> guards = const [],
  List<NavigationObserver> observers = const [],
}) {
  return InMemoryAdapter(
    configuration: RouterConfiguration(
      routes: AppRoutes.all,
      initialRoute: AppRoutes.splash,
      notFoundRoute: AppRoutes.notFound,
      globalGuards: guards,
      observers: observers,
    ),
  );
}
