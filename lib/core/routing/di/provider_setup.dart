/// Provider dependency injection setup for routing.
///
/// This file shows how to set up the routing abstraction with Provider.
/// Copy and adapt this to your application's DI configuration.
///
/// ## Usage
///
/// ```dart
/// // In your main.dart
/// void main() {
///   runApp(
///     MultiProvider(
///       providers: routingProviders,
///       child: MyApp(),
///     ),
///   );
/// }
///
/// // In your app widget
/// class MyApp extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     final router = context.read<AppRouter>();
///
///     return MaterialApp.router(
///       routerConfig: router.routerConfig,
///     );
///   }
/// }
///
/// // In your widgets
/// class ProfileWidget extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return ElevatedButton(
///       onPressed: () {
///         context.read<AppRouter>().goTo(AppRoutes.settings);
///       },
///       child: Text('Settings'),
///     );
///   }
/// }
/// ```
library;

// ═══════════════════════════════════════════════════════════════════
// PROVIDER SETUP (Example Implementation)
// ═══════════════════════════════════════════════════════════════════

/*
// Uncomment and adapt this code for your project:

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../adapters/adapters.dart';
import '../domain/domain.dart';
import '../routes/app_routes.dart';

// ─────────────────────────────────────────────────────────────────
// Provider List
// ─────────────────────────────────────────────────────────────────

/// All routing-related providers.
///
/// Add these to your MultiProvider in main.dart.
List<Provider> get routingProviders => [
      Provider<AuthService>(
        create: (_) => AuthServiceImpl(),
      ),
      ProxyProvider<AuthService, RouteGuard>(
        update: (_, auth, __) => ProviderAuthGuard(auth),
      ),
      Provider<AppRouter>(
        create: (context) => _createRouter(context),
        dispose: (_, router) => (router as GoRouterAdapter).dispose(),
      ),
    ];

AppRouter _createRouter(BuildContext context) {
  final authGuard = context.read<RouteGuard>();

  return GoRouterAdapter(
    configuration: RouterConfiguration(
      routes: AppRoutes.all,
      initialRoute: AppRoutes.splash,
      notFoundRoute: AppRoutes.notFound,
      globalGuards: [authGuard],
      observers: [LoggingNavigationObserver()],
    ),
    pageBuilder: (ctx, route, pathParams, queryParams, extra) {
      return switch (route.name) {
        'splash' => const SplashPage(),
        'login' => const LoginPage(),
        'home' => const HomePage(),
        'userProfile' => UserProfilePage(userId: pathParams['id']!),
        'settings' => const SettingsPage(),
        _ => const NotFoundPage(),
      };
    },
  );
}

// ─────────────────────────────────────────────────────────────────
// Auth Guard Implementation
// ─────────────────────────────────────────────────────────────────

class ProviderAuthGuard implements RouteGuard {
  final AuthService _authService;

  ProviderAuthGuard(this._authService);

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
// Auth Service
// ─────────────────────────────────────────────────────────────────

abstract class AuthService {
  Future<bool> isAuthenticated();
  Stream<bool> get authStateChanges;
}

class AuthServiceImpl implements AuthService {
  final _authController = StreamController<bool>.broadcast();
  bool _isAuthenticated = false;

  @override
  Future<bool> isAuthenticated() async => _isAuthenticated;

  @override
  Stream<bool> get authStateChanges => _authController.stream;

  void setAuthenticated(bool value) {
    _isAuthenticated = value;
    _authController.add(value);
  }
}

// ─────────────────────────────────────────────────────────────────
// Extension for Easy Access
// ─────────────────────────────────────────────────────────────────

extension RouterContext on BuildContext {
  /// Gets the AppRouter from context.
  AppRouter get router => read<AppRouter>();

  /// Navigates to a route.
  Future<NavigationResult<void>> goTo(
    RouteDefinition route, {
    RouteParams? params,
  }) =>
      router.goTo(route, params: params);

  /// Goes back.
  void goBack() => router.goBack();
}

*/
