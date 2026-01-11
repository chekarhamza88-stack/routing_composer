/// Domain layer exports for the routing abstraction.
///
/// This barrel file exports all pure abstractions that feature code
/// should depend on. No routing package imports leak through here.
library;

export 'app_router.dart';
export 'deep_link_handler.dart';
export 'navigation_observer.dart';
export 'navigation_result.dart';
export 'route_definition.dart';
export 'route_guard.dart';
export 'route_params.dart';
