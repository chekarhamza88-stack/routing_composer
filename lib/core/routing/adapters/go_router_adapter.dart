import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart' as go;

import '../domain/domain.dart';

/// Page builder function type for creating pages from routes.
typedef PageBuilder =
    Widget Function(
      BuildContext context,
      RouteDefinition route,
      Map<String, String> pathParams,
      Map<String, String> queryParams,
      Object? extra,
    );

/// Shell page builder for nested navigation.
typedef ShellPageBuilder =
    Widget Function(BuildContext context, go.GoRouterState state, Widget child);

/// GoRouter adapter implementing [AppRouter].
///
/// This adapter wraps GoRouter, isolating all GoRouter-specific code
/// and translating between GoRouter's API and our domain abstractions.
///
/// ## Setup
///
/// ```dart
/// final router = GoRouterAdapter(
///   configuration: RouterConfiguration(
///     routes: AppRoutes.all,
///     initialRoute: AppRoutes.home,
///   ),
///   pageBuilder: (context, route, pathParams, queryParams, extra) {
///     return switch (route.name) {
///       'home' => const HomePage(),
///       'userProfile' => UserProfilePage(userId: pathParams['id']!),
///       _ => const NotFoundPage(),
///     };
///   },
/// );
/// ```
class GoRouterAdapter implements AppRouter {
  final RouterConfiguration _configuration;
  final PageBuilder _pageBuilder;
  final ShellPageBuilder? _shellBuilder;
  final Map<String, ShellPageBuilder> _shellBuilders;

  late final go.GoRouter _goRouter;
  late final DefaultDeepLinkHandler _deepLinkHandler;
  final GuardRegistry _guardRegistry = GuardRegistry();
  final List<NavigationObserver> _observers = [];
  NavigationErrorHandler? _errorHandler;
  bool _bypassGuards = false;

  final StreamController<NavigationEvent> _navigationController =
      StreamController<NavigationEvent>.broadcast();

  RouteDefinition? _currentRoute;
  final Map<String, String> _currentPathParams = {};
  final Map<String, String> _currentQueryParams = {};

  // Completer for awaiting navigation results
  final Map<String, Completer<dynamic>> _pendingResults = {};

  /// Creates a GoRouter adapter.
  ///
  /// [configuration] - Router configuration with routes and guards
  /// [pageBuilder] - Function to build page widgets for routes
  /// [shellBuilder] - Optional builder for shell/tab navigation
  /// [shellBuilders] - Named shell builders for multiple shells
  /// [navigatorKey] - Optional navigator key for testing
  GoRouterAdapter({
    required RouterConfiguration configuration,
    required PageBuilder pageBuilder,
    ShellPageBuilder? shellBuilder,
    Map<String, ShellPageBuilder> shellBuilders = const {},
    GlobalKey<NavigatorState>? navigatorKey,
  }) : _configuration = configuration,
       _pageBuilder = pageBuilder,
       _shellBuilder = shellBuilder,
       _shellBuilders = shellBuilders {
    _deepLinkHandler = DefaultDeepLinkHandler(configuration.routes);
    _initializeGuards();
    _initializeObservers();
    _goRouter = _createGoRouter(navigatorKey);
  }

  void _initializeGuards() {
    for (final guard in _configuration.globalGuards) {
      _guardRegistry.registerGlobal(guard);
    }
  }

  void _initializeObservers() {
    for (final observer in _configuration.observers) {
      _observers.add(observer);
    }
  }

  go.GoRouter _createGoRouter(GlobalKey<NavigatorState>? navigatorKey) {
    return go.GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: _configuration.initialRoute.path,
      routes: _buildGoRoutes(),
      redirect: _handleRedirect,
      errorBuilder: _buildErrorPage,
      observers: [_GoRouterObserverBridge(this)],
    );
  }

  List<go.RouteBase> _buildGoRoutes() {
    return _configuration.routes.map(_convertRoute).toList();
  }

  go.RouteBase _convertRoute(RouteDefinition route) {
    if (route is ShellRouteDefinition) {
      return _buildShellRoute(route);
    }
    return _buildGoRoute(route);
  }

  go.GoRoute _buildGoRoute(RouteDefinition route) {
    return go.GoRoute(
      path: route.path,
      name: route.name,
      builder:
          (context, state) => _pageBuilder(
            context,
            route,
            state.pathParameters,
            state.uri.queryParameters,
            state.extra,
          ),
    );
  }

  go.ShellRoute _buildShellRoute(ShellRouteDefinition route) {
    final builder = _shellBuilders[route.name] ?? _shellBuilder;

    return go.ShellRoute(
      builder:
          builder != null
              ? (context, state, child) => builder(context, state, child)
              : null,
      routes: route.children.map(_convertRoute).toList(),
    );
  }

  Future<String?> _handleRedirect(
    BuildContext context,
    go.GoRouterState state,
  ) async {
    if (_bypassGuards) return null;

    final route = _findRouteByPath(state.uri.path);
    if (route == null) return null;

    final guards = _guardRegistry.getGuardsFor(route);
    if (guards.isEmpty) return null;

    final guardContext = GuardContext(
      destination: route,
      currentRoute: _currentRoute,
      pathParams: state.pathParameters,
      queryParams: state.uri.queryParameters,
      uri: state.uri,
    );

    for (final guard in guards) {
      final result = await guard.canActivate(guardContext);

      switch (result) {
        case GuardAllow():
          continue;
        case GuardRedirect(:final redirectTo, :final params):
          _notifyNavigationFailed(
            route,
            GuardRejectedError(
              route: route,
              redirectTo: redirectTo,
              guardName: guard.name,
            ),
          );
          return redirectTo.buildUri(
            pathParams: params?.toPathParams() ?? {},
            queryParams: params?.toQueryParams() ?? {},
          );
        case GuardReject(:final reason):
          _notifyNavigationFailed(
            route,
            GuardRejectedError(
              route: route,
              guardName: guard.name,
              message: reason,
            ),
          );
          // Reject without redirect - stay on current route
          return _currentRoute?.path ?? '/';
      }
    }

    return null;
  }

  Widget _buildErrorPage(BuildContext context, go.GoRouterState state) {
    final notFoundRoute = _configuration.notFoundRoute;
    if (notFoundRoute != null) {
      return _pageBuilder(
        context,
        notFoundRoute,
        state.pathParameters,
        state.uri.queryParameters,
        state.extra,
      );
    }

    // Default error widget
    return Center(child: Text('Route not found: ${state.uri.path}'));
  }

  RouteDefinition? _findRouteByPath(String path) {
    return _deepLinkHandler.parse(Uri.parse(path))?.route;
  }

  RouteDefinition? _findRouteByName(String name) {
    return _configuration.routes.firstWhereOrNull((r) => r.name == name);
  }

  // ─────────────────────────────────────────────────────────────────
  // AppRouter Implementation
  // ─────────────────────────────────────────────────────────────────

  @override
  RouterConfig<Object> get routerConfig => _goRouter;

  @override
  RouteDefinition? get currentRoute => _currentRoute;

  @override
  Map<String, String> get currentPathParams => _currentPathParams;

  @override
  Map<String, String> get currentQueryParams => _currentQueryParams;

  @override
  Stream<NavigationEvent> get navigationStream => _navigationController.stream;

  @override
  Future<NavigationResult<void>> goTo(
    RouteDefinition route, {
    RouteParams? params,
  }) async {
    try {
      _notifyNavigationStarted(route);

      final uri = route.buildUri(
        pathParams: params?.toPathParams() ?? {},
        queryParams: params?.toQueryParams() ?? {},
      );

      // Use push() to maintain navigation stack for goBack() support
      _goRouter.push(uri, extra: params);
      _notifyNavigationCompleted(route);

      return const NavigationSuccess(null);
    } catch (e, stack) {
      final error = UnknownNavigationError(
        message: e.toString(),
        cause: e,
        stackTrace: stack,
      );
      _notifyNavigationFailed(route, error);
      return NavigationFailure(error);
    }
  }

  @override
  Future<NavigationResult<T>> goToAndAwait<T>(
    RouteDefinition route, {
    RouteParams? params,
  }) async {
    try {
      _notifyNavigationStarted(route);

      final completer = Completer<T>();
      final key = '${route.name}_${DateTime.now().millisecondsSinceEpoch}';
      _pendingResults[key] = completer;

      final uri = route.buildUri(
        pathParams: params?.toPathParams() ?? {},
        queryParams: params?.toQueryParams() ?? {},
      );

      _goRouter.push(uri, extra: (params, key));

      final result = await completer.future;
      _pendingResults.remove(key);
      _notifyNavigationCompleted(route);

      return NavigationSuccess(result);
    } catch (e, stack) {
      final error = UnknownNavigationError(
        message: e.toString(),
        cause: e,
        stackTrace: stack,
      );
      _notifyNavigationFailed(route, error);
      return NavigationFailure(error);
    }
  }

  @override
  Future<NavigationResult<void>> goToPath(String path) async {
    try {
      final parsed = _deepLinkHandler.parseString(path);
      final route = parsed?.route;

      _notifyNavigationStarted(route);
      _goRouter.go(path);

      if (route != null) {
        _notifyNavigationCompleted(route);
      }

      return const NavigationSuccess(null);
    } catch (e, stack) {
      final error = UnknownNavigationError(
        message: e.toString(),
        cause: e,
        stackTrace: stack,
      );
      _notifyNavigationFailed(null, error);
      return NavigationFailure(error);
    }
  }

  @override
  Future<NavigationResult<void>> replaceWith(
    RouteDefinition route, {
    RouteParams? params,
  }) async {
    try {
      _notifyNavigationStarted(route, isReplacement: true);

      final uri = route.buildUri(
        pathParams: params?.toPathParams() ?? {},
        queryParams: params?.toQueryParams() ?? {},
      );

      _goRouter.replace(uri, extra: params);
      _notifyNavigationCompleted(route, isReplacement: true);

      return const NavigationSuccess(null);
    } catch (e, stack) {
      final error = UnknownNavigationError(
        message: e.toString(),
        cause: e,
        stackTrace: stack,
      );
      _notifyNavigationFailed(route, error);
      return NavigationFailure(error);
    }
  }

  @override
  Future<NavigationResult<void>> clearStackAndGoTo(
    RouteDefinition route, {
    RouteParams? params,
  }) async {
    try {
      _notifyNavigationStarted(route);

      final uri = route.buildUri(
        pathParams: params?.toPathParams() ?? {},
        queryParams: params?.toQueryParams() ?? {},
      );

      // GoRouter's go() replaces the entire stack
      _goRouter.go(uri);
      _notifyNavigationCompleted(route);

      return const NavigationSuccess(null);
    } catch (e, stack) {
      final error = UnknownNavigationError(
        message: e.toString(),
        cause: e,
        stackTrace: stack,
      );
      _notifyNavigationFailed(route, error);
      return NavigationFailure(error);
    }
  }

  @override
  void goBack() {
    if (canGoBack()) {
      _goRouter.pop();
    }
  }

  @override
  void goBackWithResult<T>(T result) {
    // Find and complete pending result
    if (_pendingResults.isNotEmpty) {
      final entry = _pendingResults.entries.last;
      (entry.value as Completer<T>).complete(result);
    }
    _goRouter.pop(result);
  }

  @override
  bool canGoBack() => _goRouter.canPop();

  @override
  Future<bool> popUntil(bool Function(RouteDefinition route) predicate) async {
    // GoRouter doesn't have direct popUntil, so we simulate it
    while (canGoBack()) {
      final current = _currentRoute;
      if (current != null && predicate(current)) {
        return true;
      }
      goBack();
      // Give time for navigation to settle
      await Future.delayed(const Duration(milliseconds: 50));
    }
    return false;
  }

  @override
  void setErrorHandler(NavigationErrorHandler handler) {
    _errorHandler = handler;
  }

  @override
  void addObserver(NavigationObserver observer) {
    _observers.add(observer);
  }

  @override
  void removeObserver(NavigationObserver observer) {
    _observers.remove(observer);
  }

  @override
  void addGuardForRoute(RouteDefinition route, RouteGuard guard) {
    _guardRegistry.registerForRoute(route, guard);
  }

  @override
  void addGlobalGuard(RouteGuard guard) {
    _guardRegistry.registerGlobal(guard);
  }

  @override
  void setBypassGuards(bool bypass) {
    _bypassGuards = bypass;
  }

  @override
  Future<NavigationResult<void>> handleDeepLink(Uri uri) async {
    final parsed = _deepLinkHandler.parse(uri);
    if (parsed == null) {
      final error = DeepLinkError(
        message: 'No route matches URI: $uri',
        uri: uri,
      );
      return NavigationFailure(error);
    }

    return goTo(parsed.route, params: parsed.toRouteParams());
  }

  @override
  DeepLinkHandler get deepLinkHandler => _deepLinkHandler;

  @override
  int get currentTabIndex => 0; // TODO: Implement tab tracking

  @override
  void switchToTab(int index) {
    // TODO: Implement shell tab switching
  }

  @override
  RouteDefinition? getCurrentRouteForTab(int tabIndex) {
    // TODO: Implement per-tab route tracking
    return _currentRoute;
  }

  // ─────────────────────────────────────────────────────────────────
  // Internal Methods
  // ─────────────────────────────────────────────────────────────────

  void _notifyNavigationStarted(
    RouteDefinition? route, {
    bool isReplacement = false,
  }) {
    final event = NavigationEvent(
      route: route,
      previousRoute: _currentRoute,
      isReplacement: isReplacement,
    );

    for (final observer in _observers) {
      observer.onNavigationStarted(event);
    }
  }

  void _notifyNavigationCompleted(
    RouteDefinition route, {
    bool isReplacement = false,
    bool isPop = false,
  }) {
    final previousRoute = _currentRoute;
    _currentRoute = route;

    final event = NavigationEvent(
      route: route,
      previousRoute: previousRoute,
      pathParams: _currentPathParams,
      queryParams: _currentQueryParams,
      isReplacement: isReplacement,
      isPop: isPop,
    );

    _navigationController.add(event);

    for (final observer in _observers) {
      observer.onNavigationCompleted(event);
    }
  }

  void _notifyNavigationFailed(RouteDefinition? route, NavigationError error) {
    final event = NavigationEvent(route: route, previousRoute: _currentRoute);

    for (final observer in _observers) {
      observer.onNavigationFailed(event, error);
    }

    _errorHandler?.call(error, route);
  }

  /// Disposes resources.
  void dispose() {
    _navigationController.close();
    _goRouter.dispose();
  }
}

/// Bridge between GoRouter's observer and our navigation tracking.
class _GoRouterObserverBridge extends NavigatorObserver {
  final GoRouterAdapter _adapter;

  _GoRouterObserverBridge(this._adapter);

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
      final routeDef = _adapter._findRouteByName(settings.name!);
      if (routeDef != null) {
        _adapter._currentRoute = routeDef;
      }
    }
  }
}

/// Extension to add firstWhereOrNull to Iterable.
extension _IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
