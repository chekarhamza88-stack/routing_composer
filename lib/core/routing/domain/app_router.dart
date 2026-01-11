import 'package:flutter/widgets.dart';

import 'deep_link_handler.dart';
import 'navigation_observer.dart';
import 'navigation_result.dart';
import 'route_definition.dart';
import 'route_guard.dart';
import 'route_params.dart';

/// Callback for handling navigation errors globally.
typedef NavigationErrorHandler = void Function(
  NavigationError error,
  RouteDefinition? route,
);

/// Main navigation interface for the application.
///
/// This is the primary abstraction that feature code depends on.
/// All routing operations go through this interface, ensuring
/// complete decoupling from underlying routing packages.
///
/// ## Design Principles
///
/// - **Business-oriented API**: Methods like `goToHome()` instead of `push()`
/// - **No BuildContext**: All operations work without Flutter context
/// - **Type-safe**: Strongly typed parameters and results
/// - **Testable**: InMemoryAdapter for unit testing
///
/// ## Usage
///
/// ```dart
/// // Inject via DI
/// class ProfileViewModel {
///   final AppRouter _router;
///
///   ProfileViewModel(this._router);
///
///   Future<void> onLogout() async {
///     final result = await _router.clearStackAndGoTo(AppRoutes.login);
///     result.fold(
///       onSuccess: (_) => print('Logged out'),
///       onFailure: (e) => print('Logout navigation failed: $e'),
///     );
///   }
/// }
/// ```
abstract interface class AppRouter {
  /// Configuration for MaterialApp.router().
  ///
  /// Provides routerConfig or routerDelegate/routeInformationParser
  /// depending on the adapter implementation.
  RouterConfig<Object> get routerConfig;

  /// The current route, if known.
  RouteDefinition? get currentRoute;

  /// Current route's path parameters.
  Map<String, String> get currentPathParams;

  /// Current route's query parameters.
  Map<String, String> get currentQueryParams;

  /// Stream of navigation events.
  ///
  /// Subscribe to receive updates on route changes.
  Stream<NavigationEvent> get navigationStream;

  // ─────────────────────────────────────────────────────────────────
  // Core Navigation Methods
  // ─────────────────────────────────────────────────────────────────

  /// Navigates to a route definition.
  ///
  /// This is the primary navigation method. Use for any route
  /// that doesn't have a dedicated typed method.
  ///
  /// [route] - The destination route
  /// [params] - Optional typed parameters
  ///
  /// Returns a [NavigationResult] indicating success or failure.
  Future<NavigationResult<void>> goTo(
    RouteDefinition route, {
    RouteParams? params,
  });

  /// Navigates to a route and waits for a result.
  ///
  /// The destination screen can return a value using `goBackWithResult`.
  ///
  /// Example:
  /// ```dart
  /// final result = await router.goToAndAwait<bool>(AppRoutes.confirmDialog);
  /// if (result.valueOrNull == true) {
  ///   // User confirmed
  /// }
  /// ```
  Future<NavigationResult<T>> goToAndAwait<T>(
    RouteDefinition route, {
    RouteParams? params,
  });

  /// Navigates by URI path.
  ///
  /// Useful for handling deep links or dynamic navigation.
  /// The path is matched against registered routes.
  ///
  /// [path] - URI path with optional query string
  Future<NavigationResult<void>> goToPath(String path);

  // ─────────────────────────────────────────────────────────────────
  // Stack Operations
  // ─────────────────────────────────────────────────────────────────

  /// Replaces the current route without adding to history.
  ///
  /// The back button will go to the route before the replaced one.
  Future<NavigationResult<void>> replaceWith(
    RouteDefinition route, {
    RouteParams? params,
  });

  /// Clears the navigation stack and navigates to a route.
  ///
  /// The destination becomes the only route in the stack.
  /// Useful for logout flows or onboarding completion.
  Future<NavigationResult<void>> clearStackAndGoTo(
    RouteDefinition route, {
    RouteParams? params,
  });

  /// Goes back to the previous route.
  ///
  /// Does nothing if there's no previous route.
  void goBack();

  /// Goes back and returns a result to the previous route.
  ///
  /// Used with [goToAndAwait] to pass data back.
  void goBackWithResult<T>(T result);

  /// Returns whether there's a route to go back to.
  bool canGoBack();

  /// Pops routes until the predicate returns true.
  ///
  /// [predicate] receives each route definition during stack traversal.
  /// Returns false if no matching route was found.
  Future<bool> popUntil(bool Function(RouteDefinition route) predicate);

  // ─────────────────────────────────────────────────────────────────
  // Configuration
  // ─────────────────────────────────────────────────────────────────

  /// Registers a global navigation error handler.
  ///
  /// Called when any navigation operation fails.
  void setErrorHandler(NavigationErrorHandler handler);

  /// Adds a navigation observer.
  void addObserver(NavigationObserver observer);

  /// Removes a navigation observer.
  void removeObserver(NavigationObserver observer);

  /// Registers a guard for a specific route.
  void addGuardForRoute(RouteDefinition route, RouteGuard guard);

  /// Registers a global guard applied to all routes.
  void addGlobalGuard(RouteGuard guard);

  /// Sets whether guards are bypassed (for testing).
  void setBypassGuards(bool bypass);

  // ─────────────────────────────────────────────────────────────────
  // Deep Linking
  // ─────────────────────────────────────────────────────────────────

  /// Handles an incoming deep link.
  ///
  /// Parses the URI and navigates to the matched route.
  Future<NavigationResult<void>> handleDeepLink(Uri uri);

  /// Gets the deep link handler.
  DeepLinkHandler get deepLinkHandler;

  // ─────────────────────────────────────────────────────────────────
  // Tab/Shell Navigation
  // ─────────────────────────────────────────────────────────────────

  /// Gets the currently active tab index for shell navigation.
  int get currentTabIndex;

  /// Switches to a tab by index.
  ///
  /// Only applicable when using shell/tab navigation.
  void switchToTab(int index);

  /// Gets the current route within a specific tab.
  RouteDefinition? getCurrentRouteForTab(int tabIndex);
}

/// Extension methods for convenient navigation.
extension AppRouterExtensions on AppRouter {
  /// Navigates to home route (convenience method).
  Future<NavigationResult<void>> goToHome() => goToPath('/');

  /// Checks if currently on a specific route.
  bool isOnRoute(RouteDefinition route) => currentRoute?.name == route.name;

  /// Builds a full URI for a route with parameters.
  String buildUri(RouteDefinition route, {RouteParams? params}) {
    if (params == null) return route.path;
    return route.buildUri(
      pathParams: params.toPathParams(),
      queryParams: params.toQueryParams(),
    );
  }
}

/// Configuration for initializing the router.
///
/// Pass to adapter constructors to configure routing behavior.
class RouterConfiguration {
  /// All route definitions.
  final List<RouteDefinition> routes;

  /// Initial route to display.
  final RouteDefinition initialRoute;

  /// Route to show when no match is found.
  final RouteDefinition? notFoundRoute;

  /// Global guards applied to all routes.
  final List<RouteGuard> globalGuards;

  /// Deep link configuration.
  final DeepLinkConfig deepLinkConfig;

  /// Navigation observers.
  final List<NavigationObserver> observers;

  /// Creates router configuration.
  const RouterConfiguration({
    required this.routes,
    required this.initialRoute,
    this.notFoundRoute,
    this.globalGuards = const [],
    this.deepLinkConfig = const DeepLinkConfig(),
    this.observers = const [],
  });
}
