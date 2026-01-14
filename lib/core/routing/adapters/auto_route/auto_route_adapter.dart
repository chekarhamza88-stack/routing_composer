import 'dart:async';

import 'package:auto_route/auto_route.dart' hide NavigationFailure, PageBuilder;
import 'package:flutter/widgets.dart';

import '../../domain/domain.dart';
import '../../utils/iterable_extensions.dart';
import 'auto_route_guard_bridge.dart';
import 'auto_route_observer_bridge.dart';
import 'dynamic_auto_router.dart';
import 'dynamic_page_info.dart';

/// Shell page builder for nested navigation (AutoRoute-specific).
///
/// Uses [ShellRouteData] from domain for accessing current route state,
/// providing a consistent interface across adapters.
typedef AutoRouteShellBuilder = Widget Function(
  BuildContext context,
  ShellRouteData data,
  Widget child,
);

/// AutoRoute adapter implementing [AppRouter].
///
/// This adapter wraps AutoRoute 9.x, isolating all AutoRoute-specific code
/// and translating between AutoRoute's API and our domain abstractions.
///
/// ## Setup
///
/// ```dart
/// final router = AutoRouteAdapter(
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
class AutoRouteAdapter implements AppRouter {
  final RouterConfiguration _configuration;
  final PageBuilder _pageBuilder;
  final AutoRouteShellBuilder? _shellBuilder;
  final Map<String, AutoRouteShellBuilder> _shellBuilders;

  late final DynamicAutoRouter _autoRouter;
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

  // Tab tracking for shell navigation
  int _currentTabIndex = 0;
  final Map<int, RouteDefinition?> _tabRoutes = {};

  /// Creates an AutoRoute adapter.
  ///
  /// [configuration] - Router configuration with routes and guards
  /// [pageBuilder] - Function to build page widgets for routes
  /// [shellBuilder] - Optional builder for shell/tab navigation
  /// [shellBuilders] - Named shell builders for multiple shells
  /// [navigatorKey] - Optional navigator key for testing
  AutoRouteAdapter({
    required RouterConfiguration configuration,
    required PageBuilder pageBuilder,
    AutoRouteShellBuilder? shellBuilder,
    Map<String, AutoRouteShellBuilder> shellBuilders = const {},
    GlobalKey<NavigatorState>? navigatorKey,
  }) : _configuration = configuration,
       _pageBuilder = pageBuilder,
       _shellBuilder = shellBuilder,
       _shellBuilders = shellBuilders {
    _deepLinkHandler = DefaultDeepLinkHandler(configuration.routes);
    _initializeGuards();
    _initializeObservers();
    _autoRouter = _createAutoRouter(navigatorKey);
    _currentRoute = configuration.initialRoute;
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

  DynamicAutoRouter _createAutoRouter(
    GlobalKey<NavigatorState>? navigatorKey,
  ) {
    return DynamicAutoRouter(
      routes: _buildAutoRoutes(),
      guards: [AutoRouteGuardBridge(this, _guardRegistry)],
      initialRoute: _configuration.initialRoute.path,
      navigatorKey: navigatorKey,
    );
  }

  List<AutoRoute> _buildAutoRoutes() {
    return _configuration.routes.map(_convertRoute).toList();
  }

  AutoRoute _convertRoute(RouteDefinition route) {
    if (route is ShellRouteDefinition) {
      return _buildShellRoute(route);
    }
    return _buildAutoRoute(route);
  }

  AutoRoute _buildAutoRoute(RouteDefinition route) {
    return AutoRoute(
      path: route.path,
      page: DynamicPageInfo(
        routeName: route.name,
        pageBuilder: (data) => _buildPageWidget(data, route),
      ),
    );
  }

  AutoRoute _buildShellRoute(ShellRouteDefinition route) {
    return AutoRoute(
      path: route.path,
      page: DynamicPageInfo(
        routeName: route.name,
        pageBuilder: (data) => _buildShellWidget(data, route),
      ),
      children: route.children.map(_convertRoute).toList(),
    );
  }

  /// Builds a page widget for a route.
  Widget _buildPageWidget(RouteData data, RouteDefinition route) {
    return Builder(
      builder: (context) => _pageBuilder(
        context,
        route,
        data.pathParams.rawMap.cast<String, String>(),
        data.queryParams.rawMap.cast<String, String>(),
        data.args,
      ),
    );
  }

  /// Builds a shell widget for a shell route.
  Widget _buildShellWidget(RouteData data, ShellRouteDefinition route) {
    return Builder(
      builder: (context) {
        final shellBuilder = _shellBuilders[route.name] ?? _shellBuilder;
        if (shellBuilder != null) {
          final shellData = ShellRouteData(
            currentRoute: _currentRoute,
            pathParams: _currentPathParams,
            queryParams: _currentQueryParams,
          );
          return shellBuilder(context, shellData, const AutoRouter());
        }
        return const AutoRouter();
      },
    );
  }

  /// Whether guards should be bypassed.
  bool get bypassGuards => _bypassGuards;

  /// Finds a route definition by name.
  RouteDefinition? findRouteByName(String name) {
    return _configuration.routes.firstWhereOrNull((r) => r.name == name);
  }

  /// Notifies observers of navigation failure.
  ///
  /// Called by [AutoRouteGuardBridge] when guards reject navigation.
  void notifyNavigationFailed(RouteDefinition? route, NavigationError error) {
    _notifyNavigationFailed(route, error);
  }

  /// Updates route state from an AutoRoutePage.
  ///
  /// Called by [AutoRouteObserverBridge] to sync state.
  void updateRouteFromAutoRoutePage(AutoRoutePage page) {
    final routeData = page.routeData;
    final routeDef = findRouteByName(routeData.name);

    if (routeDef != null) {
      _currentRoute = routeDef;
      _currentPathParams
        ..clear()
        ..addAll(routeData.pathParams.rawMap.cast<String, String>());
      _currentQueryParams
        ..clear()
        ..addAll(routeData.queryParams.rawMap.cast<String, String>());
    }
  }

  /// Updates tab index and route.
  ///
  /// Called by [AutoRouteObserverBridge] on tab changes.
  void updateTabIndex(int index, String routeName) {
    _currentTabIndex = index;
    final routeDef = findRouteByName(routeName);
    _tabRoutes[index] = routeDef;
  }

  /// Builds a PageRouteInfo for navigation.
  PageRouteInfo _buildPageRouteInfo(
    RouteDefinition route,
    RouteParams? params,
  ) {
    final pathParams = params?.toPathParams() ?? {};
    final queryParams = params?.toQueryParams() ?? {};

    return DynamicPageRouteInfo(
      routeName: route.name,
      pathParams: pathParams,
      queryParams: queryParams,
      args: params,
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // AppRouter Implementation
  // ─────────────────────────────────────────────────────────────────

  @override
  RouterConfig<Object> get routerConfig => _autoRouter.config(
    navigatorObservers: () => [AutoRouteObserverBridge(this)],
    deepLinkBuilder: (deepLink) {
      final parsed = _deepLinkHandler.parse(deepLink.uri);
      if (parsed != null) {
        return DeepLink([
          _buildPageRouteInfo(parsed.route, parsed.toRouteParams()),
        ]);
      }
      return deepLink;
    },
  );

  @override
  RouteDefinition? get currentRoute => _currentRoute;

  @override
  Map<String, String> get currentPathParams =>
      Map.unmodifiable(_currentPathParams);

  @override
  Map<String, String> get currentQueryParams =>
      Map.unmodifiable(_currentQueryParams);

  @override
  Stream<NavigationEvent> get navigationStream => _navigationController.stream;

  @override
  Future<NavigationResult<void>> goTo(
    RouteDefinition route, {
    RouteParams? params,
  }) async {
    try {
      _notifyNavigationStarted(route);

      final pageInfo = _buildPageRouteInfo(route, params);
      await _autoRouter.push(pageInfo);

      _updateRouteState(route, params);
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

      final pageInfo = _buildPageRouteInfo(route, params);

      // AutoRoute's push<T>() returns Future<T?> directly.
      // Callers expecting nullable results should use goToAndAwait<T?>().
      final result = await _autoRouter.push<T>(pageInfo);

      _updateRouteState(route, params);
      _notifyNavigationCompleted(route);

      // Result can be null if the route was popped without a value.
      // Cast is safe when caller uses nullable type parameter (e.g., <bool?>).
      return NavigationSuccess(result as T);
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

      await _autoRouter.pushNamed(path);

      if (route != null) {
        _updateRouteState(route, parsed?.toRouteParams());
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

      final pageInfo = _buildPageRouteInfo(route, params);
      await _autoRouter.replace(pageInfo);

      _updateRouteState(route, params);
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

      final pageInfo = _buildPageRouteInfo(route, params);

      // AutoRoute's replaceAll clears the stack and navigates
      await _autoRouter.replaceAll([pageInfo]);

      _updateRouteState(route, params);
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
      _autoRouter.maybePop();
    }
  }

  @override
  void goBackWithResult<T>(T result) {
    _autoRouter.maybePop(result);
  }

  @override
  bool canGoBack() => _autoRouter.canPop();

  @override
  Future<bool> popUntil(bool Function(RouteDefinition route) predicate) async {
    var found = false;
    _autoRouter.popUntil((route) {
      final settings = route.settings;
      if (settings is AutoRoutePage) {
        final routeName = settings.routeData.name;
        final routeDef = findRouteByName(routeName);
        if (routeDef != null && predicate(routeDef)) {
          found = true;
          return true;
        }
      }
      return false;
    });
    return found;
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
  int get currentTabIndex => _currentTabIndex;

  @override
  void switchToTab(int index) {
    // Store current tab's route
    _tabRoutes[_currentTabIndex] = _currentRoute;

    // Switch tab index
    _currentTabIndex = index;

    // Restore previous route for new tab if exists
    if (_tabRoutes.containsKey(index)) {
      _currentRoute = _tabRoutes[index];
    }
  }

  @override
  RouteDefinition? getCurrentRouteForTab(int tabIndex) {
    if (tabIndex == _currentTabIndex) {
      return _currentRoute;
    }
    return _tabRoutes[tabIndex];
  }

  // ─────────────────────────────────────────────────────────────────
  // Internal Methods
  // ─────────────────────────────────────────────────────────────────

  void _updateRouteState(RouteDefinition route, RouteParams? params) {
    _currentRoute = route;
    _currentPathParams.clear();
    _currentQueryParams.clear();
    if (params != null) {
      _currentPathParams.addAll(params.toPathParams());
      _currentQueryParams.addAll(params.toQueryParams());
    }
  }

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
    _autoRouter.dispose();
  }
}
