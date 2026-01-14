import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

/// Dynamic router that builds routes from RouteDefinitions at runtime.
///
/// Unlike code-generated AutoRoute routers, this router accepts route
/// configurations dynamically, enabling the adapter pattern where routes
/// are defined in the domain layer without AutoRoute dependencies.
class DynamicAutoRouter extends RootStackRouter {
  final List<AutoRoute> _routes;
  final List<AutoRouteGuard> _guards;
  final String _initialRoute;
  final GlobalKey<NavigatorState>? _navigatorKey;

  /// Creates a dynamic auto router.
  ///
  /// [routes] - List of AutoRoute configurations built from RouteDefinitions
  /// [guards] - List of AutoRoute guards (typically includes the guard bridge)
  /// [initialRoute] - The path to navigate to on startup
  /// [navigatorKey] - Optional navigator key for testing or external control
  DynamicAutoRouter({
    required List<AutoRoute> routes,
    required List<AutoRouteGuard> guards,
    required String initialRoute,
    GlobalKey<NavigatorState>? navigatorKey,
  }) : _routes = routes,
       _guards = guards,
       _initialRoute = initialRoute,
       _navigatorKey = navigatorKey;

  @override
  List<AutoRoute> get routes => _routes;

  @override
  List<AutoRouteGuard> get guards => _guards;

  /// The initial route path for this router.
  String get initialRoute => _initialRoute;

  @override
  GlobalKey<NavigatorState> get navigatorKey {
    return _navigatorKey ?? super.navigatorKey;
  }

  @override
  RouteType get defaultRouteType => const RouteType.material();
}
