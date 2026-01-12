/// Utility extensions for the routing package.
library;

/// Extension to add firstWhereOrNull to Iterable.
///
/// This avoids importing collection package for a single method.
extension IterableExtension<T> on Iterable<T> {
  /// Returns the first element matching [test], or null if none found.
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
