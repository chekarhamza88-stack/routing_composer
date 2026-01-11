import 'route_definition.dart';
import 'route_params.dart';

/// Parsed deep link information.
///
/// Contains the matched route and extracted parameters from a URI.
class ParsedDeepLink {
  /// The matched route definition.
  final RouteDefinition route;

  /// Path parameters extracted from the URI.
  final Map<String, String> pathParams;

  /// Query parameters extracted from the URI.
  final Map<String, String> queryParams;

  /// The original URI that was parsed.
  final Uri uri;

  /// Creates a parsed deep link.
  const ParsedDeepLink({
    required this.route,
    required this.uri,
    this.pathParams = const {},
    this.queryParams = const {},
  });

  /// Converts to RouteParams for navigation.
  RouteParams toRouteParams() => MapRouteParams(
        pathParams: pathParams,
        queryParams: queryParams,
      );

  @override
  String toString() =>
      'ParsedDeepLink(route: ${route.name}, pathParams: $pathParams, queryParams: $queryParams)';
}

/// Abstract interface for parsing and handling deep links.
///
/// Implement this to customize how deep links are matched to routes
/// and parameters are extracted.
///
/// Example:
/// ```dart
/// class AppDeepLinkHandler extends DeepLinkHandler {
///   final List<RouteDefinition> _routes;
///
///   AppDeepLinkHandler(this._routes);
///
///   @override
///   ParsedDeepLink? parse(Uri uri) {
///     for (final route in _routes) {
///       final match = _matchRoute(route, uri);
///       if (match != null) return match;
///     }
///     return null;
///   }
/// }
/// ```
abstract class DeepLinkHandler {
  /// Parses a URI into a [ParsedDeepLink].
  ///
  /// Returns null if no matching route is found.
  ParsedDeepLink? parse(Uri uri);

  /// Parses a URI string into a [ParsedDeepLink].
  ///
  /// Convenience method that wraps [parse].
  ParsedDeepLink? parseString(String uriString) {
    try {
      return parse(Uri.parse(uriString));
    } catch (_) {
      return null;
    }
  }

  /// Validates that a URI can be handled.
  bool canHandle(Uri uri) => parse(uri) != null;
}

/// Default deep link handler that matches URIs to registered routes.
class DefaultDeepLinkHandler extends DeepLinkHandler {
  /// The routes to match against.
  final List<RouteDefinition> routes;

  /// Creates a default deep link handler.
  DefaultDeepLinkHandler(this.routes);

  @override
  ParsedDeepLink? parse(Uri uri) {
    final path = uri.path.isEmpty ? '/' : uri.path;

    for (final route in routes) {
      final match = _matchRoute(route, path);
      if (match != null) {
        return ParsedDeepLink(
          route: route,
          uri: uri,
          pathParams: match,
          queryParams: uri.queryParameters,
        );
      }
    }
    return null;
  }

  /// Attempts to match a route pattern against a path.
  ///
  /// Returns path parameters if matched, null otherwise.
  Map<String, String>? _matchRoute(RouteDefinition route, String path) {
    final routeSegments = route.path.split('/').where((s) => s.isNotEmpty).toList();
    final pathSegments = path.split('/').where((s) => s.isNotEmpty).toList();

    if (routeSegments.length != pathSegments.length) {
      return null;
    }

    final params = <String, String>{};

    for (var i = 0; i < routeSegments.length; i++) {
      final routeSegment = routeSegments[i];
      final pathSegment = pathSegments[i];

      if (routeSegment.startsWith(':')) {
        // Path parameter
        params[routeSegment.substring(1)] = Uri.decodeComponent(pathSegment);
      } else if (routeSegment != pathSegment) {
        // Literal mismatch
        return null;
      }
    }

    return params;
  }
}

/// Deep link configuration for platform-specific handling.
class DeepLinkConfig {
  /// iOS Universal Links domains.
  final List<String> iosUniversalLinkDomains;

  /// Android App Links domains.
  final List<String> androidAppLinkDomains;

  /// Custom URI schemes (e.g., 'myapp://').
  final List<String> customSchemes;

  /// Whether to use path URL strategy on web (no hash).
  final bool usePathUrlStrategy;

  /// Creates a deep link configuration.
  const DeepLinkConfig({
    this.iosUniversalLinkDomains = const [],
    this.androidAppLinkDomains = const [],
    this.customSchemes = const [],
    this.usePathUrlStrategy = true,
  });

  /// Default configuration with path URL strategy enabled.
  static const defaultConfig = DeepLinkConfig();
}
