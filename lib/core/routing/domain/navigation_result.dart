import 'route_definition.dart';

/// Sealed result type for navigation operations.
///
/// All navigation methods return a [NavigationResult] to indicate
/// success or failure with detailed error information.
///
/// Usage with pattern matching:
/// ```dart
/// final result = await router.goTo(AppRoutes.home);
/// switch (result) {
///   case NavigationSuccess():
///     print('Navigated successfully');
///   case NavigationFailure(:final error):
///     print('Navigation failed: $error');
/// }
/// ```
sealed class NavigationResult<T> {
  const NavigationResult();

  /// Returns true if navigation was successful.
  bool get isSuccess => this is NavigationSuccess<T>;

  /// Returns true if navigation failed.
  bool get isFailure => this is NavigationFailure<T>;

  /// Returns the value if successful, throws if failed.
  T get valueOrThrow {
    return switch (this) {
      NavigationSuccess(:final value) => value,
      NavigationFailure(:final error) => throw error,
    };
  }

  /// Returns the value if successful, or null if failed.
  T? get valueOrNull {
    return switch (this) {
      NavigationSuccess(:final value) => value,
      NavigationFailure() => null,
    };
  }

  /// Returns the error if failed, or null if successful.
  NavigationError? get errorOrNull {
    return switch (this) {
      NavigationSuccess() => null,
      NavigationFailure(:final error) => error,
    };
  }

  /// Transforms the success value using the provided function.
  NavigationResult<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      NavigationSuccess(:final value) =>
        NavigationSuccess(transform(value)),
      NavigationFailure(:final error) => NavigationFailure(error),
    };
  }

  /// Executes [onSuccess] if successful, [onFailure] if failed.
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(NavigationError error) onFailure,
  }) {
    return switch (this) {
      NavigationSuccess(:final value) => onSuccess(value),
      NavigationFailure(:final error) => onFailure(error),
    };
  }
}

/// Represents a successful navigation operation.
final class NavigationSuccess<T> extends NavigationResult<T> {
  /// The result value from the navigation.
  ///
  /// For `goToAndAwait`, this contains the value returned by the destination.
  /// For other operations, this is typically `void` (null).
  final T value;

  /// Creates a successful navigation result.
  const NavigationSuccess(this.value);

  @override
  String toString() => 'NavigationSuccess(value: $value)';
}

/// Represents a failed navigation operation.
final class NavigationFailure<T> extends NavigationResult<T> {
  /// The error that caused navigation to fail.
  final NavigationError error;

  /// Creates a failed navigation result.
  const NavigationFailure(this.error);

  @override
  String toString() => 'NavigationFailure(error: $error)';
}

/// Sealed error hierarchy for navigation failures.
///
/// All navigation errors extend this base class, enabling
/// exhaustive pattern matching on error types.
sealed class NavigationError implements Exception {
  /// Human-readable error message.
  final String message;

  /// Optional underlying exception.
  final Object? cause;

  /// Stack trace at the point of error.
  final StackTrace? stackTrace;

  const NavigationError({
    required this.message,
    this.cause,
    this.stackTrace,
  });

  @override
  String toString() => '$runtimeType: $message';
}

/// Error when the requested route does not exist.
final class RouteNotFoundError extends NavigationError {
  /// The path that was not found.
  final String path;

  /// Creates a route not found error.
  const RouteNotFoundError({
    required this.path,
    super.cause,
    super.stackTrace,
  }) : super(message: 'Route not found: $path');
}

/// Error when a route guard rejects navigation.
final class GuardRejectedError extends NavigationError {
  /// The route that was rejected.
  final RouteDefinition? route;

  /// The redirect destination suggested by the guard.
  ///
  /// If non-null, the router should navigate to this route instead.
  final RouteDefinition? redirectTo;

  /// The name of the guard that rejected navigation.
  final String? guardName;

  /// Creates a guard rejected error.
  const GuardRejectedError({
    this.route,
    this.redirectTo,
    this.guardName,
    String? message,
    super.cause,
    super.stackTrace,
  }) : super(
          message: message ??
              'Navigation rejected by guard${guardName != null ? ': $guardName' : ''}',
        );
}

/// Error when route parameters are invalid or missing.
final class InvalidParamsError extends NavigationError {
  /// The route with invalid parameters.
  final RouteDefinition? route;

  /// List of missing required parameters.
  final List<String> missingParams;

  /// List of parameters with invalid values.
  final List<String> invalidParams;

  /// Creates an invalid params error.
  InvalidParamsError({
    this.route,
    this.missingParams = const [],
    this.invalidParams = const [],
    String? message,
    super.cause,
    super.stackTrace,
  }) : super(
          message: message ?? _buildParamsErrorMessage(missingParams, invalidParams),
        );

  static String _buildParamsErrorMessage(
    List<String> missing,
    List<String> invalid,
  ) {
    final parts = <String>[];
    if (missing.isNotEmpty) {
      parts.add('missing: ${missing.join(', ')}');
    }
    if (invalid.isNotEmpty) {
      parts.add('invalid: ${invalid.join(', ')}');
    }
    return 'Invalid parameters: ${parts.join('; ')}';
  }
}

/// Error when navigation was cancelled before completion.
final class NavigationCancelledError extends NavigationError {
  /// The reason for cancellation.
  final String? reason;

  /// Creates a navigation cancelled error.
  const NavigationCancelledError({
    this.reason,
    super.cause,
    super.stackTrace,
  }) : super(
          message: reason ?? 'Navigation was cancelled',
        );
}

/// Error during deep link parsing or handling.
final class DeepLinkError extends NavigationError {
  /// The URI that failed to parse.
  final Uri? uri;

  /// Creates a deep link error.
  const DeepLinkError({
    required super.message,
    this.uri,
    super.cause,
    super.stackTrace,
  });
}

/// Generic navigation error for unexpected failures.
final class UnknownNavigationError extends NavigationError {
  /// Creates an unknown navigation error.
  const UnknownNavigationError({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}
