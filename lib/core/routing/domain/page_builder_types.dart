import 'package:flutter/widgets.dart';

import 'route_definition.dart';

/// Page builder function type for creating pages from routes.
///
/// This typedef defines the contract for building page widgets based on
/// route information. It's used by both GoRouter and AutoRoute adapters.
///
/// - [context] - The build context
/// - [route] - The route definition being navigated to
/// - [pathParams] - Path parameters extracted from the URL (e.g., `/user/:id`)
/// - [queryParams] - Query parameters from the URL (e.g., `?tab=settings`)
/// - [extra] - Additional data passed during navigation
typedef PageBuilder = Widget Function(
  BuildContext context,
  RouteDefinition route,
  Map<String, String> pathParams,
  Map<String, String> queryParams,
  Object? extra,
);

/// Data passed to shell builders for accessing route state.
///
/// This class provides a unified way to access route information within
/// shell/tab navigation patterns, independent of the underlying router.
class ShellRouteData {
  /// The current route definition within the shell.
  final RouteDefinition? currentRoute;

  /// Path parameters from the current route.
  final Map<String, String> pathParams;

  /// Query parameters from the current route.
  final Map<String, String> queryParams;

  /// Creates shell route data.
  const ShellRouteData({
    this.currentRoute,
    this.pathParams = const {},
    this.queryParams = const {},
  });
}
