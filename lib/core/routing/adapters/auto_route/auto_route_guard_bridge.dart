import 'package:auto_route/auto_route.dart';

import '../../domain/domain.dart';
import 'auto_route_adapter.dart';
import 'dynamic_page_info.dart';

/// Bridge between our RouteGuard and AutoRoute's AutoRouteGuard.
///
/// This class adapts our domain-level [RouteGuard] interface to work with
/// AutoRoute's navigation system, handling guard evaluation and redirects.
class AutoRouteGuardBridge extends AutoRouteGuard {
  final AutoRouteAdapter adapter;
  final GuardRegistry guardRegistry;

  /// Creates a guard bridge.
  ///
  /// [adapter] - The AutoRoute adapter for state access and notifications
  /// [guardRegistry] - Registry containing global and route-specific guards
  AutoRouteGuardBridge(this.adapter, this.guardRegistry);

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) async {
    // Skip guards if bypassed
    if (adapter.bypassGuards) {
      resolver.next(true);
      return;
    }

    // Find our RouteDefinition from the AutoRoute route
    final routeName = resolver.route.name;
    final route = adapter.findRouteByName(routeName);

    if (route == null) {
      resolver.next(true);
      return;
    }

    // Get all guards for this route (global + route-specific)
    final guards = guardRegistry.getGuardsFor(route);
    if (guards.isEmpty) {
      resolver.next(true);
      return;
    }

    // Build GuardContext
    final guardContext = GuardContext(
      destination: route,
      currentRoute: adapter.currentRoute,
      pathParams: resolver.route.pathParams.rawMap.cast<String, String>(),
      queryParams: resolver.route.queryParams.rawMap.cast<String, String>(),
      uri: Uri.tryParse(resolver.route.stringMatch),
    );

    // Evaluate guards sequentially
    for (final guard in guards) {
      final result = await guard.canActivate(guardContext);

      switch (result) {
        case GuardAllow():
          continue;

        case GuardRedirect(:final redirectTo, :final params):
          adapter.notifyNavigationFailed(
            route,
            GuardRejectedError(
              route: route,
              redirectTo: redirectTo,
              guardName: guard.name,
            ),
          );
          // Use AutoRoute's redirect mechanism
          final redirectPageInfo = DynamicPageRouteInfo(
            routeName: redirectTo.name,
            pathParams: params?.toPathParams() ?? {},
            queryParams: params?.toQueryParams() ?? {},
            args: params,
          );
          resolver.redirect(redirectPageInfo);
          return;

        case GuardReject(:final reason):
          adapter.notifyNavigationFailed(
            route,
            GuardRejectedError(
              route: route,
              guardName: guard.name,
              message: reason,
            ),
          );
          resolver.next(false);
          return;
      }
    }

    // All guards passed
    resolver.next(true);
  }
}
