/// Adapter layer exports for the routing abstraction.
///
/// This barrel file exports concrete router implementations.
/// Application code should only import the domain layer directly.
/// Adapters are wired up in the DI configuration.
library;

export 'auto_route_adapter.dart';
export 'go_router_adapter.dart';
export 'in_memory_adapter.dart';
