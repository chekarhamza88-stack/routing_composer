import 'dart:async';

import 'package:flutter/widgets.dart';

import '../domain/domain.dart';

/// In-memory router adapter for testing.
///
/// This adapter provides a complete [AppRouter] implementation that
/// operates entirely in memory, without any Flutter dependencies.
/// Perfect for unit testing navigation logic.
///
/// ## Features
///
/// - Full navigation history tracking
/// - Guard simulation
/// - Deep link injection
/// - Result awaiting support
/// - No BuildContext required
///
/// ## Usage
///
/// ```dart
/// void main() {
///   test('navigates to profile', () async {
///     final router = InMemoryAdapter(
///       configuration: RouterConfiguration(
///         routes: [AppRoutes.home, AppRoutes.profile],
///         initialRoute: AppRoutes.home,
///       ),
///     );
///
///     await router.goTo(AppRoutes.profile, params: ProfileParams(userId: '123'));
///
///     expect(router.currentRoute, equals(AppRoutes.profile));
///     expect(router.currentPathParams['id'], equals('123'));
///     expect(router.navigationHistory.length, equals(2));
///   });
/// }
/// ```
class InMemoryAdapter implements AppRouter {
  final RouterConfiguration _configuration;
  final DefaultDeepLinkHandler _deepLinkHandler;
  final GuardRegistry _guardRegistry = GuardRegistry();
  final List<NavigationObserver> _observers = [];
  NavigationErrorHandler? _errorHandler;
  bool _bypassGuards = false;

  /// Navigation stack for testing assertions.
  final List<_NavigationEntry> _navigationStack = [];

  /// Complete navigation history including pops.
  final List<NavigationEvent> _navigationHistory = [];

  /// Tab-specific stacks for shell navigation.
  final Map<int, List<_NavigationEntry>> _tabStacks = {};
  int _currentTabIndex = 0;

  final StreamController<NavigationEvent> _navigationController =
      StreamController<NavigationEvent>.broadcast();

  final Map<String, Completer<dynamic>> _pendingResults = {};

  /// Creates an in-memory adapter for testing.
  InMemoryAdapter({
    required RouterConfiguration configuration,
  })  : _configuration = configuration,
        _deepLinkHandler = DefaultDeepLinkHandler(configuration.routes) {
    _initializeGuards();
    _initializeObservers();
    _pushInitialRoute();
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

  void _pushInitialRoute() {
    _navigationStack.add(_NavigationEntry(
      route: _configuration.initialRoute,
      pathParams: {},
      queryParams: {},
    ));

    _notifyNavigationCompleted(
      _configuration.initialRoute,
      pathParams: {},
      queryParams: {},
    );
  }

  /// Returns the navigation stack for testing assertions.
  List<RouteDefinition> get navigationStack =>
      _navigationStack.map((e) => e.route).toList();

  /// Returns the complete navigation history.
  List<NavigationEvent> get navigationHistory =>
      List.unmodifiable(_navigationHistory);

  /// Clears navigation history (useful between tests).
  void clearHistory() {
    _navigationHistory.clear();
  }

  /// Resets to initial state.
  void reset() {
    _navigationStack.clear();
    _navigationHistory.clear();
    _tabStacks.clear();
    _currentTabIndex = 0;
    _bypassGuards = false;
    _pushInitialRoute();
  }

  // ─────────────────────────────────────────────────────────────────
  // AppRouter Implementation
  // ─────────────────────────────────────────────────────────────────

  @override
  RouterConfig<Object> get routerConfig {
    // In-memory adapter doesn't provide a real RouterConfig
    // This is only used for MaterialApp.router() which isn't needed in tests
    throw UnsupportedError(
      'InMemoryAdapter does not provide RouterConfig. '
      'Use GoRouterAdapter for real Flutter apps.',
    );
  }

  @override
  RouteDefinition? get currentRoute =>
      _navigationStack.isNotEmpty ? _navigationStack.last.route : null;

  @override
  Map<String, String> get currentPathParams =>
      _navigationStack.isNotEmpty ? _navigationStack.last.pathParams : {};

  @override
  Map<String, String> get currentQueryParams =>
      _navigationStack.isNotEmpty ? _navigationStack.last.queryParams : {};

  @override
  Stream<NavigationEvent> get navigationStream => _navigationController.stream;

  @override
  Future<NavigationResult<void>> goTo(
    RouteDefinition route, {
    RouteParams? params,
  }) async {
    final guardResult = await _evaluateGuards(route, params);
    if (guardResult != null) return guardResult;

    final pathParams = params?.toPathParams() ?? {};
    final queryParams = params?.toQueryParams() ?? {};

    _notifyNavigationStarted(route);

    _navigationStack.add(_NavigationEntry(
      route: route,
      pathParams: pathParams,
      queryParams: queryParams,
    ));

    _notifyNavigationCompleted(
      route,
      pathParams: pathParams,
      queryParams: queryParams,
    );

    return const NavigationSuccess(null);
  }

  @override
  Future<NavigationResult<T>> goToAndAwait<T>(
    RouteDefinition route, {
    RouteParams? params,
  }) async {
    final guardResult = await _evaluateGuards(route, params);
    if (guardResult != null) {
      return NavigationFailure(guardResult.errorOrNull!);
    }

    final pathParams = params?.toPathParams() ?? {};
    final queryParams = params?.toQueryParams() ?? {};
    final key = '${route.name}_${DateTime.now().millisecondsSinceEpoch}';

    _notifyNavigationStarted(route);

    final completer = Completer<T>();
    _pendingResults[key] = completer;

    _navigationStack.add(_NavigationEntry(
      route: route,
      pathParams: pathParams,
      queryParams: queryParams,
      resultKey: key,
    ));

    _notifyNavigationCompleted(
      route,
      pathParams: pathParams,
      queryParams: queryParams,
    );

    final result = await completer.future;
    return NavigationSuccess(result);
  }

  @override
  Future<NavigationResult<void>> goToPath(String path) async {
    final parsed = _deepLinkHandler.parseString(path);
    if (parsed == null) {
      final error = RouteNotFoundError(path: path);
      _notifyNavigationFailed(null, error);
      return NavigationFailure(error);
    }

    return goTo(parsed.route, params: parsed.toRouteParams());
  }

  @override
  Future<NavigationResult<void>> replaceWith(
    RouteDefinition route, {
    RouteParams? params,
  }) async {
    final guardResult = await _evaluateGuards(route, params);
    if (guardResult != null) return guardResult;

    final pathParams = params?.toPathParams() ?? {};
    final queryParams = params?.toQueryParams() ?? {};

    _notifyNavigationStarted(route, isReplacement: true);

    if (_navigationStack.isNotEmpty) {
      _navigationStack.removeLast();
    }

    _navigationStack.add(_NavigationEntry(
      route: route,
      pathParams: pathParams,
      queryParams: queryParams,
    ));

    _notifyNavigationCompleted(
      route,
      pathParams: pathParams,
      queryParams: queryParams,
      isReplacement: true,
    );

    return const NavigationSuccess(null);
  }

  @override
  Future<NavigationResult<void>> clearStackAndGoTo(
    RouteDefinition route, {
    RouteParams? params,
  }) async {
    final guardResult = await _evaluateGuards(route, params);
    if (guardResult != null) return guardResult;

    final pathParams = params?.toPathParams() ?? {};
    final queryParams = params?.toQueryParams() ?? {};

    _notifyNavigationStarted(route);

    _navigationStack.clear();

    _navigationStack.add(_NavigationEntry(
      route: route,
      pathParams: pathParams,
      queryParams: queryParams,
    ));

    _notifyNavigationCompleted(
      route,
      pathParams: pathParams,
      queryParams: queryParams,
    );

    return const NavigationSuccess(null);
  }

  @override
  void goBack() {
    if (!canGoBack()) return;

    final popped = _navigationStack.removeLast();

    _notifyNavigationCompleted(
      _navigationStack.last.route,
      pathParams: _navigationStack.last.pathParams,
      queryParams: _navigationStack.last.queryParams,
      isPop: true,
    );

    // Complete any pending result
    if (popped.resultKey != null) {
      final completer = _pendingResults.remove(popped.resultKey);
      if (completer != null && !completer.isCompleted) {
        completer.completeError(
          const NavigationCancelledError(reason: 'Navigation was popped'),
        );
      }
    }
  }

  @override
  void goBackWithResult<T>(T result) {
    if (!canGoBack()) return;

    final popped = _navigationStack.removeLast();

    if (popped.resultKey != null) {
      final completer = _pendingResults.remove(popped.resultKey);
      if (completer != null && !completer.isCompleted) {
        (completer as Completer<T>).complete(result);
      }
    }

    _notifyNavigationCompleted(
      _navigationStack.last.route,
      pathParams: _navigationStack.last.pathParams,
      queryParams: _navigationStack.last.queryParams,
      isPop: true,
    );
  }

  @override
  bool canGoBack() => _navigationStack.length > 1;

  @override
  Future<bool> popUntil(bool Function(RouteDefinition route) predicate) async {
    while (canGoBack()) {
      if (predicate(currentRoute!)) {
        return true;
      }
      goBack();
    }
    return predicate(currentRoute!);
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
    if (index == _currentTabIndex) return;

    // Save current stack for current tab
    _tabStacks[_currentTabIndex] = List.from(_navigationStack);

    // Restore or initialize stack for new tab
    if (_tabStacks.containsKey(index)) {
      _navigationStack
        ..clear()
        ..addAll(_tabStacks[index]!);
    }

    _currentTabIndex = index;
  }

  @override
  RouteDefinition? getCurrentRouteForTab(int tabIndex) {
    if (tabIndex == _currentTabIndex) {
      return currentRoute;
    }
    final tabStack = _tabStacks[tabIndex];
    return tabStack?.isNotEmpty == true ? tabStack!.last.route : null;
  }

  // ─────────────────────────────────────────────────────────────────
  // Testing Utilities
  // ─────────────────────────────────────────────────────────────────

  /// Injects a deep link for testing.
  Future<NavigationResult<void>> injectDeepLink(String uriString) {
    return handleDeepLink(Uri.parse(uriString));
  }

  /// Simulates guard behavior for testing.
  ///
  /// Call this to manually trigger guard evaluation without navigation.
  Future<GuardResult?> simulateGuardCheck(
    RouteDefinition route, {
    RouteParams? params,
  }) async {
    if (_bypassGuards) return const GuardAllow();

    final guards = _guardRegistry.getGuardsFor(route);
    if (guards.isEmpty) return const GuardAllow();

    final context = GuardContext(
      destination: route,
      currentRoute: currentRoute,
      pathParams: params?.toPathParams() ?? {},
      queryParams: params?.toQueryParams() ?? {},
    );

    for (final guard in guards) {
      final result = await guard.canActivate(context);
      if (result is! GuardAllow) {
        return result;
      }
    }

    return const GuardAllow();
  }

  /// Asserts that the current route matches expected.
  void assertCurrentRoute(RouteDefinition expected) {
    assert(
      currentRoute == expected,
      'Expected current route to be ${expected.name}, but was ${currentRoute?.name}',
    );
  }

  /// Asserts navigation stack length.
  void assertStackLength(int expected) {
    assert(
      _navigationStack.length == expected,
      'Expected stack length $expected, but was ${_navigationStack.length}',
    );
  }

  /// Asserts that navigation history contains a route.
  void assertHistoryContains(RouteDefinition route) {
    final contains = _navigationHistory.any((e) => e.route == route);
    assert(
      contains,
      'Expected navigation history to contain ${route.name}',
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Internal Methods
  // ─────────────────────────────────────────────────────────────────

  Future<NavigationResult<void>?> _evaluateGuards(
    RouteDefinition route,
    RouteParams? params,
  ) async {
    if (_bypassGuards) return null;

    final guards = _guardRegistry.getGuardsFor(route);
    if (guards.isEmpty) return null;

    final context = GuardContext(
      destination: route,
      currentRoute: currentRoute,
      pathParams: params?.toPathParams() ?? {},
      queryParams: params?.toQueryParams() ?? {},
    );

    for (final guard in guards) {
      final result = await guard.canActivate(context);

      switch (result) {
        case GuardAllow():
          continue;
        case GuardRedirect(:final redirectTo, :final params):
          final error = GuardRejectedError(
            route: route,
            redirectTo: redirectTo,
            guardName: guard.name,
          );
          _notifyNavigationFailed(route, error);
          // Navigate to redirect destination
          await goTo(redirectTo, params: params);
          return NavigationFailure(error);
        case GuardReject(:final reason):
          final error = GuardRejectedError(
            route: route,
            guardName: guard.name,
            message: reason,
          );
          _notifyNavigationFailed(route, error);
          return NavigationFailure(error);
      }
    }

    return null;
  }

  void _notifyNavigationStarted(
    RouteDefinition? route, {
    bool isReplacement = false,
  }) {
    final event = NavigationEvent(
      route: route,
      previousRoute: currentRoute,
      isReplacement: isReplacement,
    );

    for (final observer in _observers) {
      observer.onNavigationStarted(event);
    }
  }

  void _notifyNavigationCompleted(
    RouteDefinition route, {
    Map<String, String> pathParams = const {},
    Map<String, String> queryParams = const {},
    bool isReplacement = false,
    bool isPop = false,
  }) {
    final event = NavigationEvent(
      route: route,
      previousRoute:
          _navigationHistory.isNotEmpty ? _navigationHistory.last.route : null,
      pathParams: pathParams,
      queryParams: queryParams,
      isReplacement: isReplacement,
      isPop: isPop,
    );

    _navigationHistory.add(event);
    _navigationController.add(event);

    for (final observer in _observers) {
      observer.onNavigationCompleted(event);
    }
  }

  void _notifyNavigationFailed(RouteDefinition? route, NavigationError error) {
    final event = NavigationEvent(
      route: route,
      previousRoute: currentRoute,
    );

    for (final observer in _observers) {
      observer.onNavigationFailed(event, error);
    }

    _errorHandler?.call(error, route);
  }

  /// Disposes resources.
  void dispose() {
    _navigationController.close();
    _pendingResults.clear();
  }
}

/// Internal navigation entry for stack tracking.
class _NavigationEntry {
  final RouteDefinition route;
  final Map<String, String> pathParams;
  final Map<String, String> queryParams;
  final String? resultKey;

  const _NavigationEntry({
    required this.route,
    required this.pathParams,
    required this.queryParams,
    this.resultKey,
  });
}
