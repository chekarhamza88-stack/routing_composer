/// Adapter layer exports for the routing abstraction.
///
/// This barrel file exports concrete router implementations.
/// Application code should only import the domain layer directly.
/// Adapters are wired up in the DI configuration.
///
/// ## Structure
///
/// Each adapter is organized in its own folder:
/// - `auto_route/` - AutoRoute adapter and helpers
/// - `go_router/` - GoRouter adapter and helpers
/// - `in_memory/` - InMemoryAdapter for testing
library;

export 'auto_route/auto_route.dart';
export 'go_router/go_router.dart';
export 'in_memory/in_memory.dart';
