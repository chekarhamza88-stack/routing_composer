/// Route definition abstraction representing a navigable destination.
///
/// This class defines route metadata including path templates with parameters,
/// route names for identification, and optional configuration.
///
/// Example:
/// ```dart
/// const userProfile = RouteDefinition(
///   path: '/user/:id',
///   name: 'userProfile',
/// );
/// ```
class RouteDefinition {
  /// The URL path template for this route.
  ///
  /// Supports path parameters using colon notation: `/user/:id`
  /// Supports query parameters: `/search?q=flutter`
  final String path;

  /// A unique identifier for this route.
  ///
  /// Used for navigation and route matching.
  final String name;

  /// Whether this route requires authentication.
  ///
  /// Used by guards to enforce access control.
  final bool requiresAuth;

  /// Additional metadata associated with this route.
  ///
  /// Can be used to pass custom configuration to guards or observers.
  final Map<String, dynamic> metadata;

  /// Creates a new route definition.
  ///
  /// [path] - The URL path template (required)
  /// [name] - Unique route identifier (required)
  /// [requiresAuth] - Whether authentication is required (default: false)
  /// [metadata] - Additional route configuration (default: empty)
  const RouteDefinition({
    required this.path,
    required this.name,
    this.requiresAuth = false,
    this.metadata = const {},
  });

  /// Extracts path parameter names from the path template.
  ///
  /// Returns a list of parameter names without the colon prefix.
  /// For `/user/:id/post/:postId`, returns `['id', 'postId']`.
  List<String> get pathParameterNames {
    final regex = RegExp(r':(\w+)');
    return regex.allMatches(path).map((m) => m.group(1)!).toList();
  }

  /// Builds a concrete path by substituting path parameters.
  ///
  /// [params] - Map of parameter names to values
  ///
  /// Example:
  /// ```dart
  /// final route = RouteDefinition(path: '/user/:id', name: 'user');
  /// route.buildPath({'id': '123'}); // Returns '/user/123'
  /// ```
  String buildPath(Map<String, String> params) {
    var result = path;
    for (final entry in params.entries) {
      result = result.replaceAll(':${entry.key}', entry.value);
    }
    return result;
  }

  /// Builds a complete URI including query parameters.
  ///
  /// [pathParams] - Path parameter substitutions
  /// [queryParams] - Query string parameters
  String buildUri({
    Map<String, String> pathParams = const {},
    Map<String, String> queryParams = const {},
  }) {
    final pathResult = buildPath(pathParams);
    if (queryParams.isEmpty) return pathResult;

    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return '$pathResult?$queryString';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteDefinition &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          name == other.name;

  @override
  int get hashCode => path.hashCode ^ name.hashCode;

  @override
  String toString() => 'RouteDefinition(name: $name, path: $path)';
}

/// A route definition for shell/nested navigation containers.
///
/// Shell routes provide a persistent scaffold (like bottom navigation)
/// that wraps child routes.
class ShellRouteDefinition extends RouteDefinition {
  /// Child routes that appear within this shell.
  final List<RouteDefinition> children;

  /// Creates a shell route definition.
  ///
  /// [path] - Base path for the shell
  /// [name] - Unique identifier
  /// [children] - Nested route definitions
  const ShellRouteDefinition({
    required super.path,
    required super.name,
    required this.children,
    super.requiresAuth,
    super.metadata,
  });
}
