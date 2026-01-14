import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

/// Dynamic page info that wraps RouteDefinition for AutoRoute.
///
/// This class connects AutoRoute's page system to our dynamic page builder.
/// The [pageBuilder] function is called by AutoRoute when rendering pages.
class DynamicPageInfo extends PageInfo {
  /// Creates a dynamic page info.
  ///
  /// [routeName] - The name of the route for AutoRoute's internal routing
  /// [pageBuilder] - Function called to build the page widget from route data
  DynamicPageInfo({
    required String routeName,
    required Widget Function(RouteData data) pageBuilder,
  }) : super(routeName, builder: pageBuilder);
}

/// Dynamic PageRouteInfo for runtime navigation.
///
/// Used to construct navigation requests with dynamic path and query parameters.
class DynamicPageRouteInfo extends PageRouteInfo<Object?> {
  /// Creates a dynamic page route info.
  ///
  /// [routeName] - The route name to navigate to
  /// [pathParams] - Path parameters (e.g., {'id': '123'} for /user/:id)
  /// [queryParams] - Query parameters (e.g., {'tab': 'settings'})
  /// [args] - Additional arguments passed during navigation
  const DynamicPageRouteInfo({
    required String routeName,
    Map<String, String> pathParams = const {},
    Map<String, String> queryParams = const {},
    Object? args,
  }) : super(
         routeName,
         initialChildren: null,
         rawPathParams: pathParams,
         rawQueryParams: queryParams,
         args: args,
       );
}
