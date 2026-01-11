<div align="center">
  <img src=".github/assets/flutter_routing_composer.png" alt="Routing Composer Cover" width="100%"/>
  
  # Routing Composer

  **A Routing Composition & Abstraction Layer for Flutter**
  
  <p>Switch routing libraries (GoRouter, AutoRoute, Navigator 2.0, Beamer) without refactoring application code</p>
</div>

## Features

- **Completely decoupled** from routing packages - feature code never imports routing libraries
- **Pluggable adapters** - switch routing implementations without changing app code
- **Type-safe navigation** - strongly typed routes and parameters
- **Route guards** - async guard execution with chaining and redirects
- **Deep linking** - unified parsing across iOS, Android, and Web
- **Testable** - InMemoryAdapter enables navigation testing without UI
- **Clean Architecture** compliant - dependency inversion enforced

## Installation

```yaml
dependencies:
  routing_composer:
    path: ../routing_composer  # Or your package location
```

## Example App

See the complete working example in the [example/](example/) directory:

```bash
cd example
flutter run -d macos  # or ios, android, chrome
```

## Quick Start

### 1. Define Routes

```dart
import 'package:routing_composer/routing_composer.dart';

abstract final class AppRoutes {
  static const home = RouteDefinition(path: '/', name: 'home');
  static const login = RouteDefinition(path: '/login', name: 'login');
  static const userProfile = RouteDefinition(
    path: '/user/:id',
    name: 'userProfile',
    requiresAuth: true,
  );

  static const List<RouteDefinition> all = [home, login, userProfile];
}
```

### 2. Create Router

```dart
final router = GoRouterAdapter(
  configuration: RouterConfiguration(
    routes: AppRoutes.all,
    initialRoute: AppRoutes.home,
  ),
  pageBuilder: (context, route, pathParams, queryParams, extra) {
    return switch (route.name) {
      'home' => const HomePage(),
      'login' => const LoginPage(),
      'userProfile' => UserProfilePage(userId: pathParams['id']!),
      _ => const NotFoundPage(),
    };
  },
);
```

### 3. Use in MaterialApp

```dart
MaterialApp.router(
  routerConfig: router.routerConfig,
);
```

### 4. Navigate

```dart
// Simple navigation
await router.goTo(AppRoutes.home);

// With typed parameters
await router.goTo(
  AppRoutes.userProfile,
  params: UserProfileParams(userId: '123', tab: 'posts'),
);

// Replace current route
await router.replaceWith(AppRoutes.settings);

// Clear stack (for logout)
await router.clearStackAndGoTo(AppRoutes.login);

// Go back
router.goBack();
```

## Route Guards

Guards protect routes with authentication, authorization, or any custom logic:

```dart
class AuthGuard implements RouteGuard {
  final AuthService _auth;

  AuthGuard(this._auth);

  @override
  String get name => 'AuthGuard';

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    if (!context.destination.requiresAuth) {
      return const GuardAllow();
    }

    if (await _auth.isAuthenticated) {
      return const GuardAllow();
    }

    return const GuardRedirect(AppRoutes.login);
  }
}

// Register guard
router.addGlobalGuard(AuthGuard(authService));
```

## Deep Linking

Deep links are automatically parsed and matched to routes:

```dart
// Handle incoming deep link
await router.handleDeepLink(Uri.parse('/user/123?tab=posts'));

// Path params extracted: {'id': '123'}
// Query params extracted: {'tab': 'posts'}
```

## Testing

Use `InMemoryAdapter` for unit testing navigation without Flutter:

```dart
void main() {
  test('navigates to profile', () async {
    final router = InMemoryAdapter(
      configuration: RouterConfiguration(
        routes: AppRoutes.all,
        initialRoute: AppRoutes.home,
      ),
    );

    await router.goTo(AppRoutes.userProfile,
      params: UserProfileParams(userId: '123'));

    expect(router.currentRoute, equals(AppRoutes.userProfile));
    expect(router.currentPathParams['id'], equals('123'));
    expect(router.navigationHistory.length, equals(2));
  });

  test('auth guard redirects unauthenticated', () async {
    final router = InMemoryAdapter(...);
    router.addGlobalGuard(AuthGuard(mockAuthService));

    final result = await router.goTo(AppRoutes.settings);

    expect(result.isFailure, isTrue);
    expect(result.errorOrNull, isA<GuardRejectedError>());
    expect(router.currentRoute, equals(AppRoutes.login));
  });
}
```

## Navigation Result Handling

All navigation operations return `NavigationResult<T>`:

```dart
final result = await router.goTo(AppRoutes.settings);

// Pattern matching
switch (result) {
  case NavigationSuccess():
    print('Navigated successfully');
  case NavigationFailure(:final error):
    print('Navigation failed: $error');
}

// Or use fold
result.fold(
  onSuccess: (_) => showSnackBar('Loaded'),
  onFailure: (error) => showError(error.message),
);
```

## Error Types

```dart
sealed class NavigationError {
  RouteNotFoundError     // Route doesn't exist
  GuardRejectedError     // Guard blocked navigation
  InvalidParamsError     // Missing/invalid parameters
  NavigationCancelledError // Navigation was cancelled
  DeepLinkError          // Deep link parsing failed
  UnknownNavigationError // Unexpected error
}
```

## Folder Structure

```
lib/
├── core/
│   └── routing/
│       ├── domain/           # Pure abstractions
│       │   ├── app_router.dart
│       │   ├── route_definition.dart
│       │   ├── route_params.dart
│       │   ├── navigation_result.dart
│       │   ├── route_guard.dart
│       │   └── navigation_observer.dart
│       ├── adapters/         # Concrete implementations
│       │   ├── go_router_adapter.dart
│       │   └── in_memory_adapter.dart
│       ├── routes/           # Route definitions
│       │   └── app_routes.dart
│       └── di/               # DI setup
│           └── routing_module.dart
├── features/
│   └── ... (imports only from domain/)
```

## Dependency Injection

### Riverpod

```dart
final appRouterProvider = Provider<AppRouter>((ref) {
  return GoRouterAdapter(
    configuration: RouterConfiguration(...),
    pageBuilder: _buildPage,
  );
});
```

### GetIt

```dart
getIt.registerLazySingleton<AppRouter>(() => GoRouterAdapter(...));
```

### Provider

```dart
Provider<AppRouter>(create: (_) => GoRouterAdapter(...));
```

## Migration Guide

### Migrating from Direct GoRouter Usage

**Before (coupled to GoRouter):**

```dart
// Feature code directly imports GoRouter
import 'package:go_router/go_router.dart';

class ProfileViewModel {
  void onSettingsTap(BuildContext context) {
    context.go('/settings');
  }
}
```

**After (decoupled):**

```dart
// Feature code only imports domain abstractions
import 'package:routing_composer/routing_composer.dart';

class ProfileViewModel {
  final AppRouter _router;

  ProfileViewModel(this._router);

  Future<void> onSettingsTap() async {
    await _router.goTo(AppRoutes.settings);
  }
}
```

### Migration Steps

1. **Add routing_composer** to dependencies
2. **Define routes** in `app_routes.dart`
3. **Create GoRouterAdapter** in your DI setup
4. **Replace** `context.go(...)` with `router.goTo(...)`
5. **Remove** all `go_router` imports from feature code
6. **Add guards** to replace redirect logic
7. **Run tests** using InMemoryAdapter

### What Changes

| Before | After |
|--------|-------|
| `context.go('/path')` | `router.goTo(AppRoutes.route)` |
| `context.push('/path')` | `router.goTo(route)` (stack behavior) |
| `context.pop()` | `router.goBack()` |
| `GoRouter.of(context)` | Inject `AppRouter` via DI |
| `redirect` callback | `RouteGuard` implementation |

### What Stays the Same

- URL paths and structure
- Deep link handling (automatic)
- Browser back/forward buttons
- Route parameters

## Architecture Benefits

### 1. Testability

- Test navigation logic without UI
- Mock guards to test auth flows
- Assert on navigation history

### 2. Migration Cost

- Switch from GoRouter to AutoRoute: **Change 1 file** (adapter initialization)
- Feature code: **Zero changes**

### 3. Coupling Prevention

- Feature modules depend only on `AppRouter` interface
- Routing package changes don't propagate
- Import restrictions enforceable via linter rules

### 4. Enterprise Scalability

- Multi-team development: teams own routes, not routing logic
- Feature module isolation: each module defines its routes
- Long-term maintainability: routing decisions are centralized

## API Reference

### AppRouter

```dart
abstract interface class AppRouter {
  // Navigation
  Future<NavigationResult<void>> goTo(RouteDefinition route, {RouteParams? params});
  Future<NavigationResult<T>> goToAndAwait<T>(RouteDefinition route);
  Future<NavigationResult<void>> replaceWith(RouteDefinition route);
  Future<NavigationResult<void>> clearStackAndGoTo(RouteDefinition route);

  // Back navigation
  void goBack();
  void goBackWithResult<T>(T result);
  bool canGoBack();

  // Current state
  RouteDefinition? get currentRoute;
  Map<String, String> get currentPathParams;
  Map<String, String> get currentQueryParams;

  // Deep linking
  Future<NavigationResult<void>> handleDeepLink(Uri uri);

  // Guards
  void addGlobalGuard(RouteGuard guard);
  void addGuardForRoute(RouteDefinition route, RouteGuard guard);
  void setBypassGuards(bool bypass);

  // Observers
  void addObserver(NavigationObserver observer);
  Stream<NavigationEvent> get navigationStream;
}
```

## License

MIT License - see LICENSE file for details.
