import 'package:flutter/widgets.dart';

import 'go_router_adapter.dart';

/// Bridge between GoRouter's observer and our navigation tracking.
///
/// This observer listens to Flutter's navigation events and updates
/// the [GoRouterAdapter]'s internal state to keep track of the current route.
class GoRouterObserverBridge extends NavigatorObserver {
  final GoRouterAdapter adapter;

  /// Creates an observer bridge for the given adapter.
  GoRouterObserverBridge(this.adapter);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _updateRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      _updateRoute(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      _updateRoute(newRoute);
    }
  }

  void _updateRoute(Route<dynamic> route) {
    final settings = route.settings;
    if (settings.name != null) {
      adapter.updateCurrentRouteFromName(settings.name!);
    }
  }
}
