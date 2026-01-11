/// GetIt dependency injection setup for routing.
///
/// This file shows how to set up the routing abstraction with GetIt.
/// Copy and adapt this to your application's DI configuration.
///
/// ## Usage
///
/// ```dart
/// // In your main.dart
/// void main() async {
///   await setupDependencies();
///   runApp(MyApp());
/// }
///
/// // In your app widget
/// class MyApp extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     final router = getIt<AppRouter>();
///
///     return MaterialApp.router(
///       routerConfig: router.routerConfig,
///     );
///   }
/// }
///
/// // In your ViewModels/Controllers
/// class ProfileViewModel {
///   final AppRouter _router = getIt<AppRouter>();
///
///   Future<void> onSettingsTapped() async {
///     await _router.goTo(AppRoutes.settings);
///   }
/// }
/// ```
library;

// ═══════════════════════════════════════════════════════════════════
// GETIT SETUP (Example Implementation)
// ═══════════════════════════════════════════════════════════════════

/*
// Uncomment and adapt this code for your project:

import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

import '../adapters/adapters.dart';
import '../domain/domain.dart';
import '../routes/app_routes.dart';

final getIt = GetIt.instance;

/// Sets up all routing dependencies.
Future<void> setupRoutingDependencies() async {
  // Register auth service (your implementation)
  getIt.registerLazySingleton<AuthService>(() => AuthServiceImpl());

  // Register auth guard
  getIt.registerLazySingleton<RouteGuard>(
    () => GetItAuthGuard(getIt<AuthService>()),
    instanceName: 'authGuard',
  );

  // Register navigation observers
  getIt.registerLazySingleton<NavigationObserver>(
    () => LoggingNavigationObserver(),
    instanceName: 'loggingObserver',
  );

  // Register router
  getIt.registerLazySingleton<AppRouter>(() {
    return GoRouterAdapter(
      configuration: RouterConfiguration(
        routes: AppRoutes.all,
        initialRoute: AppRoutes.splash,
        notFoundRoute: AppRoutes.notFound,
        globalGuards: [
          getIt<RouteGuard>(instanceName: 'authGuard'),
        ],
        observers: [
          getIt<NavigationObserver>(instanceName: 'loggingObserver'),
        ],
      ),
      pageBuilder: _buildPage,
    );
  });
}

Widget _buildPage(
  BuildContext context,
  RouteDefinition route,
  Map<String, String> pathParams,
  Map<String, String> queryParams,
  Object? extra,
) {
  return switch (route.name) {
    'splash' => const SplashPage(),
    'login' => const LoginPage(),
    'home' => const HomePage(),
    'userProfile' => UserProfilePage(userId: pathParams['id']!),
    'settings' => const SettingsPage(),
    _ => const NotFoundPage(),
  };
}

// ─────────────────────────────────────────────────────────────────
// Auth Guard Implementation
// ─────────────────────────────────────────────────────────────────

class GetItAuthGuard implements RouteGuard {
  final AuthService _authService;

  GetItAuthGuard(this._authService);

  @override
  String get name => 'AuthGuard';

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    if (!context.destination.requiresAuth) {
      return const GuardAllow();
    }

    if (await _authService.isAuthenticated()) {
      return const GuardAllow();
    }

    return const GuardRedirect(AppRoutes.login);
  }
}

// ─────────────────────────────────────────────────────────────────
// Auth Service Interface (Example)
// ─────────────────────────────────────────────────────────────────

abstract class AuthService {
  Future<bool> isAuthenticated();
  Future<void> login(String email, String password);
  Future<void> logout();
}

class AuthServiceImpl implements AuthService {
  bool _isAuthenticated = false;

  @override
  Future<bool> isAuthenticated() async => _isAuthenticated;

  @override
  Future<void> login(String email, String password) async {
    // Your login logic
    _isAuthenticated = true;
  }

  @override
  Future<void> logout() async {
    _isAuthenticated = false;
  }
}

// ─────────────────────────────────────────────────────────────────
// Test Setup
// ─────────────────────────────────────────────────────────────────

/// Sets up dependencies for testing.
void setupTestDependencies() {
  getIt.registerLazySingleton<AppRouter>(() {
    return InMemoryAdapter(
      configuration: RouterConfiguration(
        routes: AppRoutes.all,
        initialRoute: AppRoutes.splash,
        notFoundRoute: AppRoutes.notFound,
      ),
    );
  });
}

/// Resets all registered dependencies.
Future<void> resetDependencies() async {
  await getIt.reset();
}

*/
