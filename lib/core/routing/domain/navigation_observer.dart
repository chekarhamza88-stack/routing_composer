import 'route_definition.dart';

/// Information about a navigation event.
///
/// Provided to observers during route lifecycle events.
class NavigationEvent {
  /// The route being navigated to.
  final RouteDefinition? route;

  /// The route being navigated from.
  final RouteDefinition? previousRoute;

  /// Path parameters for the navigation.
  final Map<String, String> pathParams;

  /// Query parameters for the navigation.
  final Map<String, String> queryParams;

  /// The full URI of the navigation.
  final Uri? uri;

  /// Timestamp of the navigation event.
  final DateTime timestamp;

  /// Whether this is a replacement navigation (no back stack entry).
  final bool isReplacement;

  /// Whether this is a pop navigation (going back).
  final bool isPop;

  /// Creates a navigation event.
  NavigationEvent({
    this.route,
    this.previousRoute,
    this.pathParams = const {},
    this.queryParams = const {},
    this.uri,
    DateTime? timestamp,
    this.isReplacement = false,
    this.isPop = false,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() =>
      'NavigationEvent(route: ${route?.name}, from: ${previousRoute?.name}, isPop: $isPop)';
}

/// Abstract observer interface for navigation lifecycle events.
///
/// Implement this to track navigation for analytics, logging,
/// state management, or any other cross-cutting concerns.
///
/// Example:
/// ```dart
/// class AnalyticsObserver implements NavigationObserver {
///   final AnalyticsService _analytics;
///
///   AnalyticsObserver(this._analytics);
///
///   @override
///   void onNavigationStarted(NavigationEvent event) {
///     _analytics.trackScreenView(event.route?.name ?? 'unknown');
///   }
///
///   @override
///   void onNavigationCompleted(NavigationEvent event) {}
///
///   @override
///   void onNavigationFailed(NavigationEvent event, Object error) {
///     _analytics.trackError('navigation_failed', error.toString());
///   }
/// }
/// ```
abstract interface class NavigationObserver {
  /// Called when navigation is about to start.
  ///
  /// This is called before guards are evaluated.
  void onNavigationStarted(NavigationEvent event);

  /// Called when navigation completes successfully.
  ///
  /// The destination route is now active.
  void onNavigationCompleted(NavigationEvent event);

  /// Called when navigation fails.
  ///
  /// [error] contains the reason for failure.
  void onNavigationFailed(NavigationEvent event, Object error);
}

/// Base implementation of [NavigationObserver] with no-op methods.
///
/// Extend this to implement only the callbacks you need.
abstract class NavigationObserverBase implements NavigationObserver {
  @override
  void onNavigationStarted(NavigationEvent event) {}

  @override
  void onNavigationCompleted(NavigationEvent event) {}

  @override
  void onNavigationFailed(NavigationEvent event, Object error) {}
}

/// A logging observer that prints navigation events to console.
///
/// Useful for debugging navigation flow.
class LoggingNavigationObserver extends NavigationObserverBase {
  /// Custom log function. Defaults to print.
  final void Function(String message) log;

  /// Creates a logging observer.
  LoggingNavigationObserver({void Function(String)? log})
      : log = log ?? print;

  @override
  void onNavigationStarted(NavigationEvent event) {
    log('[NAV] Started: ${event.route?.name ?? 'unknown'} '
        '(from: ${event.previousRoute?.name ?? 'none'})');
  }

  @override
  void onNavigationCompleted(NavigationEvent event) {
    log('[NAV] Completed: ${event.route?.name ?? 'unknown'}');
  }

  @override
  void onNavigationFailed(NavigationEvent event, Object error) {
    log('[NAV] Failed: ${event.route?.name ?? 'unknown'} - $error');
  }
}

/// A composite observer that broadcasts events to multiple observers.
class CompositeNavigationObserver implements NavigationObserver {
  /// The observers to notify.
  final List<NavigationObserver> observers;

  /// Creates a composite observer.
  CompositeNavigationObserver(this.observers);

  @override
  void onNavigationStarted(NavigationEvent event) {
    for (final observer in observers) {
      observer.onNavigationStarted(event);
    }
  }

  @override
  void onNavigationCompleted(NavigationEvent event) {
    for (final observer in observers) {
      observer.onNavigationCompleted(event);
    }
  }

  @override
  void onNavigationFailed(NavigationEvent event, Object error) {
    for (final observer in observers) {
      observer.onNavigationFailed(event, error);
    }
  }
}

/// An observer that tracks navigation history.
///
/// Useful for testing and debugging.
class HistoryTrackingObserver extends NavigationObserverBase {
  /// List of completed navigation events.
  final List<NavigationEvent> history = [];

  /// Maximum history size. Older entries are removed.
  final int maxHistorySize;

  /// Creates a history tracking observer.
  HistoryTrackingObserver({this.maxHistorySize = 100});

  @override
  void onNavigationCompleted(NavigationEvent event) {
    history.add(event);
    if (history.length > maxHistorySize) {
      history.removeAt(0);
    }
  }

  /// Clears the navigation history.
  void clear() => history.clear();

  /// Returns the last navigated route.
  NavigationEvent? get lastNavigation =>
      history.isNotEmpty ? history.last : null;
}
