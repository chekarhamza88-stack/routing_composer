/// Riverpod dependency injection setup for routing.
///
/// This file shows how to set up the routing abstraction with Riverpod.
/// Copy and adapt this to your application's DI configuration.
///
/// ## Usage
///
/// ```dart
/// // In your main.dart
/// void main() {
///   runApp(
///     ProviderScope(
///       child: MyApp(),
///     ),
///   );
/// }
///
/// // In your app widget
/// class MyApp extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final router = ref.watch(appRouterProvider);
///
///     return MaterialApp.router(
///       routerConfig: router.routerConfig,
///     );
///   }
/// }
///
/// // In your ViewModels/Controllers
/// class ProfileViewModel {
///   final AppRouter _router;
///
///   ProfileViewModel(this._router);
///
///   Future<void> onSettingsTapped() async {
///     await _router.goTo(AppRoutes.settings);
///   }
/// }
/// ```
library;

// ═══════════════════════════════════════════════════════════════════
// RIVERPOD PROVIDERS (Example Implementation)
// ═══════════════════════════════════════════════════════════════════

/*
// Uncomment and adapt this code for your project:

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../adapters/adapters.dart';
import '../domain/domain.dart';
import '../routes/app_routes.dart';

// ─────────────────────────────────────────────────────────────────
// Auth State Provider (Example - Replace with your auth solution)
// ─────────────────────────────────────────────────────────────────

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final bool isAuthenticated;
  final String? userId;

  const AuthState({this.isAuthenticated = false, this.userId});
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  void login(String userId) {
    state = AuthState(isAuthenticated: true, userId: userId);
  }

  void logout() {
    state = const AuthState();
  }
}

// ─────────────────────────────────────────────────────────────────
// Auth Guard Provider
// ─────────────────────────────────────────────────────────────────

final authGuardProvider = Provider<RouteGuard>((ref) {
  return _RiverpodAuthGuard(ref);
});

class _RiverpodAuthGuard implements RouteGuard {
  final Ref _ref;

  _RiverpodAuthGuard(this._ref);

  @override
  String get name => 'AuthGuard';

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    // Skip auth check for public routes
    if (!context.destination.requiresAuth) {
      return const GuardAllow();
    }

    final authState = _ref.read(authStateProvider);

    if (authState.isAuthenticated) {
      return const GuardAllow();
    }

    // Redirect to login
    return const GuardRedirect(AppRoutes.login);
  }
}

// ─────────────────────────────────────────────────────────────────
// Router Provider
// ─────────────────────────────────────────────────────────────────

final appRouterProvider = Provider<AppRouter>((ref) {
  final authGuard = ref.watch(authGuardProvider);

  return GoRouterAdapter(
    configuration: RouterConfiguration(
      routes: AppRoutes.all,
      initialRoute: AppRoutes.splash,
      notFoundRoute: AppRoutes.notFound,
      globalGuards: [authGuard],
      observers: [
        LoggingNavigationObserver(),
      ],
    ),
    pageBuilder: (context, route, pathParams, queryParams, extra) {
      // Your page builder implementation
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
});

// ─────────────────────────────────────────────────────────────────
// Navigation Stream Provider
// ─────────────────────────────────────────────────────────────────

final navigationStreamProvider = StreamProvider<NavigationEvent>((ref) {
  final router = ref.watch(appRouterProvider);
  return router.navigationStream;
});

// ─────────────────────────────────────────────────────────────────
// Current Route Provider
// ─────────────────────────────────────────────────────────────────

final currentRouteProvider = Provider<RouteDefinition?>((ref) {
  final router = ref.watch(appRouterProvider);
  return router.currentRoute;
});

*/
