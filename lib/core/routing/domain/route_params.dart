/// Base class for typed route parameters.
///
/// Extend this class to create strongly-typed parameters for specific routes.
/// This ensures type safety when navigating and extracting parameters.
///
/// Example:
/// ```dart
/// class UserProfileParams extends RouteParams {
///   final String userId;
///   final String? tab;
///
///   const UserProfileParams({required this.userId, this.tab});
///
///   @override
///   Map<String, String> toPathParams() => {'id': userId};
///
///   @override
///   Map<String, String> toQueryParams() =>
///       tab != null ? {'tab': tab!} : {};
/// }
/// ```
abstract class RouteParams {
  /// Creates a route params instance.
  const RouteParams();

  /// Converts this params instance to path parameters.
  ///
  /// Returns a map of parameter names to values for path substitution.
  /// Parameter names should match the `:param` placeholders in the route path.
  Map<String, String> toPathParams();

  /// Converts this params instance to query parameters.
  ///
  /// Returns a map of query parameter names to values.
  /// These will be appended to the URL as `?key=value&key2=value2`.
  Map<String, String> toQueryParams() => {};

  /// Merges path and query parameters into a single map.
  ///
  /// Useful for adapters that need all parameters in one place.
  Map<String, String> toMap() => {
        ...toPathParams(),
        ...toQueryParams(),
      };
}

/// Empty route params for routes that don't require any parameters.
class EmptyRouteParams extends RouteParams {
  /// Singleton instance.
  static const instance = EmptyRouteParams._();

  const EmptyRouteParams._();

  @override
  Map<String, String> toPathParams() => {};

  @override
  Map<String, String> toQueryParams() => {};
}

/// Generic route params created from raw maps.
///
/// Use this when you need to pass parameters dynamically without
/// creating a dedicated params class.
class MapRouteParams extends RouteParams {
  /// Path parameters map.
  final Map<String, String> pathParams;

  /// Query parameters map.
  final Map<String, String> queryParams;

  /// Creates map-based route params.
  const MapRouteParams({
    this.pathParams = const {},
    this.queryParams = const {},
  });

  @override
  Map<String, String> toPathParams() => pathParams;

  @override
  Map<String, String> toQueryParams() => queryParams;
}

/// Parsed parameters extracted from a navigation event.
///
/// This record type holds both path and query parameters
/// after they've been parsed from a URI.
typedef ParsedParams = ({
  Map<String, String> pathParams,
  Map<String, String> queryParams,
});
