/// Routing Composition & Abstraction Layer for Flutter.
///
/// A routing abstraction that allows switching routing libraries
/// (GoRouter, AutoRoute, Navigator 2.0, Beamer) without refactoring
/// application code.
///
/// ## Getting Started
///
/// ```dart
/// import 'package:routing_composer/routing_composer.dart';
///
/// // 1. Define your routes
/// abstract final class AppRoutes {
///   static const home = RouteDefinition(path: '/', name: 'home');
///   static const profile = RouteDefinition(
///     path: '/profile/:id',
///     name: 'profile',
///     requiresAuth: true,
///   );
/// }
///
/// // 2. Create the router
/// final router = GoRouterAdapter(
///   configuration: RouterConfiguration(
///     routes: [AppRoutes.home, AppRoutes.profile],
///     initialRoute: AppRoutes.home,
///   ),
///   pageBuilder: (context, route, pathParams, queryParams, extra) {
///     return switch (route.name) {
///       'home' => const HomePage(),
///       'profile' => ProfilePage(userId: pathParams['id']!),
///       _ => const NotFoundPage(),
///     };
///   },
/// );
///
/// // 3. Use in MaterialApp
/// MaterialApp.router(routerConfig: router.routerConfig);
///
/// // 4. Navigate using the abstraction
/// await router.goTo(AppRoutes.profile, params: ProfileParams(userId: '123'));
/// ```
///
/// ## Core Principles
///
/// - Depend on abstractions, never implementations
/// - No UI/feature code imports routing packages directly
/// - Routing is accessed only via [AppRouter] interface
/// - Adapters are replaceable without app code changes
///
/// ## Key Features
///
/// - **Route Guards**: Async guards with chaining and redirect support
/// - **Deep Linking**: Unified parsing across platforms
/// - **Nested Navigation**: Shell routes for tab-based layouts
/// - **Error Handling**: Sealed error types with global handlers
/// - **Testing**: InMemoryAdapter for unit tests without UI
library;

// Domain Layer - Pure abstractions (import these in feature code)
export 'core/routing/domain/app_router.dart';
export 'core/routing/domain/deep_link_handler.dart';
export 'core/routing/domain/navigation_observer.dart';
export 'core/routing/domain/navigation_result.dart';
export 'core/routing/domain/route_definition.dart';
export 'core/routing/domain/route_guard.dart';
export 'core/routing/domain/route_params.dart';

// Adapters - Concrete implementations (wire up in DI)
export 'core/routing/adapters/go_router_adapter.dart';
export 'core/routing/adapters/in_memory_adapter.dart';

// Routes - Application route definitions
export 'core/routing/routes/app_routes.dart';

// DI - Dependency injection helpers
export 'core/routing/di/routing_module.dart';
