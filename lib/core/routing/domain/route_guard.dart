import 'route_definition.dart';
import 'route_params.dart';

/// Context provided to route guards during navigation evaluation.
///
/// Contains all information needed for a guard to make an allow/deny decision.
class GuardContext {
  /// The route being navigated to.
  final RouteDefinition destination;

  /// Parameters for the destination route.
  final RouteParams? params;

  /// The current route before navigation (if any).
  final RouteDefinition? currentRoute;

  /// Parsed path parameters from the URL.
  final Map<String, String> pathParams;

  /// Parsed query parameters from the URL.
  final Map<String, String> queryParams;

  /// The full URI being navigated to.
  final Uri? uri;

  /// Creates a guard context.
  const GuardContext({
    required this.destination,
    this.params,
    this.currentRoute,
    this.pathParams = const {},
    this.queryParams = const {},
    this.uri,
  });
}

/// Result of a route guard evaluation.
///
/// Guards return this sealed type to indicate whether navigation
/// should proceed, be redirected, or be rejected.
sealed class GuardResult {
  const GuardResult();
}

/// Guard allows navigation to proceed.
final class GuardAllow extends GuardResult {
  const GuardAllow();
}

/// Guard redirects to a different route.
final class GuardRedirect extends GuardResult {
  /// The route to redirect to.
  final RouteDefinition redirectTo;

  /// Optional parameters for the redirect route.
  final RouteParams? params;

  /// Creates a redirect result.
  const GuardRedirect(this.redirectTo, {this.params});
}

/// Guard rejects navigation entirely.
final class GuardReject extends GuardResult {
  /// Reason for rejection.
  final String? reason;

  /// Creates a rejection result.
  const GuardReject({this.reason});
}

/// Abstract route guard interface.
///
/// Implement this to create custom navigation guards for authentication,
/// authorization, feature flags, or any other access control logic.
///
/// Example:
/// ```dart
/// class AuthGuard implements RouteGuard {
///   final AuthService _auth;
///
///   AuthGuard(this._auth);
///
///   @override
///   String get name => 'AuthGuard';
///
///   @override
///   Future<GuardResult> canActivate(GuardContext context) async {
///     if (await _auth.isAuthenticated) {
///       return const GuardAllow();
///     }
///     return GuardRedirect(AppRoutes.login);
///   }
/// }
/// ```
abstract interface class RouteGuard {
  /// Unique identifier for this guard.
  ///
  /// Used in error messages and debugging.
  String get name;

  /// Evaluates whether navigation should proceed.
  ///
  /// [context] contains destination route and parameters.
  ///
  /// Returns:
  /// - [GuardAllow] to allow navigation
  /// - [GuardRedirect] to redirect to a different route
  /// - [GuardReject] to reject navigation with an error
  Future<GuardResult> canActivate(GuardContext context);
}

/// A composite guard that chains multiple guards together.
///
/// All guards must allow navigation for it to proceed.
/// First guard to redirect or reject stops evaluation.
class CompositeGuard implements RouteGuard {
  /// The guards to evaluate in order.
  final List<RouteGuard> guards;

  @override
  final String name;

  /// Creates a composite guard.
  ///
  /// [guards] are evaluated in order until one rejects or redirects.
  CompositeGuard(this.guards, {String? name})
      : name = name ?? 'CompositeGuard(${guards.map((g) => g.name).join(', ')})';

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    for (final guard in guards) {
      final result = await guard.canActivate(context);
      if (result is! GuardAllow) {
        return result;
      }
    }
    return const GuardAllow();
  }
}

/// A guard that always allows navigation.
///
/// Useful for testing or as a placeholder.
class AlwaysAllowGuard implements RouteGuard {
  @override
  String get name => 'AlwaysAllowGuard';

  /// Singleton instance.
  static const instance = AlwaysAllowGuard._();

  const AlwaysAllowGuard._();

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    return const GuardAllow();
  }
}

/// A guard that always rejects navigation.
///
/// Useful for testing or marking routes as disabled.
class AlwaysRejectGuard implements RouteGuard {
  @override
  final String name;

  /// The rejection reason.
  final String? reason;

  /// Creates a guard that always rejects.
  const AlwaysRejectGuard({this.name = 'AlwaysRejectGuard', this.reason});

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    return GuardReject(reason: reason);
  }
}

/// Guard registry for managing route-guard associations.
///
/// Maps routes to their guards and provides lookup functionality.
class GuardRegistry {
  final Map<String, List<RouteGuard>> _routeGuards = {};
  final List<RouteGuard> _globalGuards = [];

  /// Registers a guard for a specific route.
  void registerForRoute(RouteDefinition route, RouteGuard guard) {
    _routeGuards.putIfAbsent(route.name, () => []).add(guard);
  }

  /// Registers a global guard applied to all routes.
  void registerGlobal(RouteGuard guard) {
    _globalGuards.add(guard);
  }

  /// Gets all guards for a route (global + route-specific).
  List<RouteGuard> getGuardsFor(RouteDefinition route) {
    return [
      ..._globalGuards,
      ...(_routeGuards[route.name] ?? []),
    ];
  }

  /// Clears all registered guards.
  void clear() {
    _routeGuards.clear();
    _globalGuards.clear();
  }
}
