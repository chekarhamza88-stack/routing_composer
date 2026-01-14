import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

import 'auto_route_adapter.dart';

/// Bridge between AutoRoute navigation and our state tracking.
///
/// This observer listens to AutoRoute's navigation events and updates
/// the [AutoRouteAdapter]'s internal state to keep track of the current route.
class AutoRouteObserverBridge extends AutoRouterObserver {
  final AutoRouteAdapter adapter;

  /// Creates an observer bridge for the given adapter.
  AutoRouteObserverBridge(this.adapter);

  @override
  void didPush(Route route, Route? previousRoute) {
    _updateRoute(route);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    if (previousRoute != null) {
      _updateRoute(previousRoute);
    }
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (newRoute != null) {
      _updateRoute(newRoute);
    }
  }

  @override
  void didChangeTabRoute(TabPageRoute route, TabPageRoute previousRoute) {
    adapter.updateTabIndex(route.index, route.name);
  }

  void _updateRoute(Route route) {
    final settings = route.settings;
    if (settings is AutoRoutePage) {
      adapter.updateRouteFromAutoRoutePage(settings);
    }
  }
}
