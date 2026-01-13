/// AutoRoute example application setup.
library;

import 'package:flutter/material.dart';
import 'package:routing_composer/routing_composer.dart';

import '../core/guards/auth_guard.dart';
import '../core/services/auth_service.dart';
import '../pages/home_page.dart';
import '../pages/login_page.dart';
import '../pages/not_found_page.dart';
import '../pages/notifications_page.dart';
import '../pages/search_page.dart';
import '../pages/settings_page.dart';
import '../pages/splash_page.dart';
import '../pages/user_profile_page.dart';
import '../widgets/main_shell_auto_route.dart';

/// Example app using AutoRouteAdapter.
class AutoRouteExampleApp extends StatefulWidget {
  const AutoRouteExampleApp({super.key});

  @override
  State<AutoRouteExampleApp> createState() => _AutoRouteExampleAppState();
}

class _AutoRouteExampleAppState extends State<AutoRouteExampleApp> {
  late final AppRouter _router;
  final _authService = ExampleAuthService();

  @override
  void initState() {
    super.initState();
    _router = _createRouter();
  }

  @override
  void dispose() {
    // AutoRouteAdapter requires explicit disposal
    (_router as AutoRouteAdapter).dispose();
    super.dispose();
  }

  AppRouter _createRouter() {
    return AutoRouteAdapter(
      configuration: RouterConfiguration(
        routes: AppRoutes.all,
        initialRoute: AppRoutes.splash,
        notFoundRoute: AppRoutes.notFound,
        globalGuards: [ExampleAuthGuard(_authService)],
        observers: [LoggingNavigationObserver()],
      ),
      pageBuilder: _buildPage,
      shellBuilder: _buildShell,
    );
  }

  Widget _buildPage(
    BuildContext context,
    RouteDefinition route,
    Map<String, String> pathParams,
    Map<String, String> queryParams,
    Object? extra,
  ) {
    return switch (route.name) {
      'splash' => SplashPage(router: _router, authService: _authService),
      'login' => LoginPage(router: _router, authService: _authService),
      'home' => HomePage(
          router: _router,
          infoCard: const InfoCardConfig(
            icon: Icons.auto_awesome,
            title: 'AutoRoute Adapter',
            description:
                'This example uses AutoRouteAdapter. The same AppRouter '
                'interface works with both GoRouter and AutoRoute!',
          ),
        ),
      'userProfile' => UserProfilePage(
          router: _router,
          userId: pathParams['id'] ?? 'unknown',
          tab: queryParams['tab'],
        ),
      'settings' => SettingsPage(router: _router, authService: _authService),
      'search' => SearchPage(router: _router, query: queryParams['q']),
      'notifications' => NotificationsPage(router: _router),
      'notFound' => NotFoundPage(router: _router),
      _ => NotFoundPage(router: _router),
    };
  }

  Widget _buildShell(
    BuildContext context,
    AutoRouteShellData data,
    Widget child,
  ) {
    return MainShellAutoRoute(router: _router, shellData: data, child: child);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Routing Composer - AutoRoute Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: _router.routerConfig,
    );
  }
}
