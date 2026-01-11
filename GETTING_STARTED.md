# Getting Started with Routing Composer

## 📁 Project Structure

```
routing_composer/                    # Main package
├── lib/
│   ├── routing_composer.dart       # Public API
│   ├── core/routing/
│   │   ├── domain/                 # Pure abstractions (no dependencies)
│   │   ├── adapters/               # GoRouter & InMemory implementations
│   │   ├── di/                     # Dependency injection helpers
│   │   └── routes/                 # Route definitions
│   └── example/
│       └── example_app.dart        # Legacy example (use example/ folder instead)
├── test/
│   └── unit/
│       └── navigation_test.dart    # Unit tests (54 tests)
├── example/                         # ✨ Separate example app
│   ├── lib/main.dart               # Complete working example
│   ├── pubspec.yaml                # Depends on parent package
│   └── README.md                   # Example documentation
├── README.md                        # Package documentation
└── pubspec.yaml                     # Package configuration
```

---

## 🚀 Quick Start Guide

### 1. Run Unit Tests

```bash
cd /Users/hamzachekar/template_ui_kit/routing_composer
flutter test
```

✅ **54 tests** - No device needed, uses `InMemoryAdapter`

---

### 2. Run Example App

```bash
cd /Users/hamzachekar/template_ui_kit/routing_composer/example
flutter-perso run -d macos  # or ios, android, chrome
```

**What you'll see:**
- Splash screen → Login (auth guard redirect)
- Bottom tab navigation
- Type-safe route navigation
- Deep link handling
- Error pages (404)

---

### 3. Use in Your Own Project

#### Add Dependency

In your `pubspec.yaml`:
```yaml
dependencies:
  routing_composer:
    path: ../routing_composer
  go_router: ^14.0.0
```

#### Define Routes

```dart
import 'package:routing_composer/routing_composer.dart';

abstract final class AppRoutes {
  static const home = RouteDefinition(path: '/', name: 'home');
  static const profile = RouteDefinition(
    path: '/profile/:id',
    name: 'profile',
    requiresAuth: true,
  );
}
```

#### Create Router

```dart
final router = GoRouterAdapter(
  configuration: RouterConfiguration(
    routes: [AppRoutes.home, AppRoutes.profile],
    initialRoute: AppRoutes.home,
  ),
  pageBuilder: (context, route, pathParams, queryParams, extra) {
    return switch (route.name) {
      'home' => const HomePage(),
      'profile' => ProfilePage(userId: pathParams['id']!),
      _ => const NotFoundPage(),
    };
  },
);
```

#### Use in MaterialApp

```dart
MaterialApp.router(
  routerConfig: router.routerConfig,
);
```

#### Navigate

```dart
// Simple navigation
await router.goTo(AppRoutes.home);

// With parameters
await router.goTo(
  AppRoutes.profile,
  params: const MapRouteParams(pathParams: {'id': '123'}),
);

// Go back
router.goBack();

// Clear stack (logout)
await router.clearStackAndGoTo(AppRoutes.login);
```

---

## 📦 Available Adapters

| Adapter | Status | Use Case |
|---------|--------|----------|
| `GoRouterAdapter` | ✅ Production | Real apps with GoRouter |
| `InMemoryAdapter` | ✅ Testing | Unit tests without UI |
| `AutoRouteAdapter` | 🔜 Coming | Future migration path |

---

## 🧪 Testing Your Navigation

```dart
import 'package:routing_composer/routing_composer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('navigates to profile', () async {
    final router = InMemoryAdapter(
      configuration: RouterConfiguration(
        routes: [AppRoutes.home, AppRoutes.profile],
        initialRoute: AppRoutes.home,
      ),
    );

    await router.goTo(AppRoutes.profile);

    expect(router.currentRoute, equals(AppRoutes.profile));
    expect(router.navigationStack.length, equals(2));
  });
}
```

---

## 🔗 Key Concepts

### 1. **Domain Abstractions** (No Dependencies)
- `AppRouter` - Main navigation interface
- `RouteDefinition` - Route metadata
- `RouteGuard` - Auth/permission checks
- `NavigationResult<T>` - Success/failure results

### 2. **Adapter Pattern**
- Isolates routing library dependencies
- Swap implementations without app changes
- Test navigation without UI

### 3. **Type-Safe Navigation**
- No string-based routes in app code
- Compile-time route validation
- Typed parameters via `RouteParams`

### 4. **Guard System**
- Async authentication checks
- Redirect on unauthorized access
- Chain multiple guards

---

## 📚 Resources

- [README.md](README.md) - Complete package documentation
- [example/](example/) - Working example app
- [test/unit/navigation_test.dart](test/unit/navigation_test.dart) - Test examples
- [routing_composer_prompt.md](routing_composer_prompt.md) - Design specification

---

## 🛠️ Commands Reference

```bash
# Run tests
cd /Users/hamzachekar/template_ui_kit/routing_composer
flutter test

# Run example
cd /Users/hamzachekar/template_ui_kit/routing_composer/example
flutter-perso run -d macos

# Get dependencies
flutter-perso pub get

# Analyze code
flutter analyze
```

---

## ✨ What Makes This Package Special

✅ **Zero coupling** - App code never imports `go_router`  
✅ **Testable** - Navigate without `BuildContext` or widgets  
✅ **Swappable** - Change routing libraries without refactoring  
✅ **Type-safe** - Compile-time route validation  
✅ **Clean Architecture** - Domain → Adapter separation  

---

Happy routing! 🚀
