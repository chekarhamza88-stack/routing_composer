import 'package:flutter_test/flutter_test.dart';
import 'package:routing_composer/core/routing/adapters/in_memory_adapter.dart';
import 'package:routing_composer/core/routing/domain/domain.dart';
import 'package:routing_composer/core/routing/routes/app_routes.dart';

void main() {
  group('InMemoryAdapter Navigation Tests', () {
    late InMemoryAdapter router;

    setUp(() {
      router = InMemoryAdapter(
        configuration: RouterConfiguration(
          routes: AppRoutes.all,
          initialRoute: AppRoutes.splash,
          notFoundRoute: AppRoutes.notFound,
        ),
      );
    });

    tearDown(() {
      router.dispose();
    });

    group('Basic Navigation', () {
      test('starts with initial route', () {
        expect(router.currentRoute, equals(AppRoutes.splash));
        expect(router.navigationStack.length, equals(1));
      });

      test('goTo navigates to route', () async {
        final result = await router.goTo(AppRoutes.home);

        expect(result.isSuccess, isTrue);
        expect(router.currentRoute, equals(AppRoutes.home));
        expect(router.navigationStack.length, equals(2));
      });

      test('goTo with params sets path params', () async {
        await router.goTo(
          AppRoutes.userProfile,
          params: const UserProfileParams(userId: 'user_123'),
        );

        expect(router.currentRoute, equals(AppRoutes.userProfile));
        expect(router.currentPathParams['id'], equals('user_123'));
      });

      test('goTo with params sets query params', () async {
        await router.goTo(
          AppRoutes.userProfile,
          params: const UserProfileParams(userId: 'user_123', tab: 'posts'),
        );

        expect(router.currentQueryParams['tab'], equals('posts'));
      });

      test('goToPath navigates by path', () async {
        final result = await router.goToPath('/settings');

        expect(result.isSuccess, isTrue);
        expect(router.currentRoute, equals(AppRoutes.settings));
      });

      test('goToPath returns error for unknown path', () async {
        final result = await router.goToPath('/unknown/path');

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<RouteNotFoundError>());
      });
    });

    group('Stack Operations', () {
      test('replaceWith replaces current route', () async {
        await router.goTo(AppRoutes.home);
        await router.replaceWith(AppRoutes.settings);

        expect(router.currentRoute, equals(AppRoutes.settings));
        expect(router.navigationStack.length, equals(2));
      });

      test('clearStackAndGoTo clears stack', () async {
        await router.goTo(AppRoutes.home);
        await router.goTo(AppRoutes.settings);
        await router.goTo(AppRoutes.userProfile);
        await router.clearStackAndGoTo(AppRoutes.login);

        expect(router.currentRoute, equals(AppRoutes.login));
        expect(router.navigationStack.length, equals(1));
      });

      test('goBack pops the stack', () async {
        await router.goTo(AppRoutes.home);
        await router.goTo(AppRoutes.settings);

        router.goBack();

        expect(router.currentRoute, equals(AppRoutes.home));
        expect(router.navigationStack.length, equals(2));
      });

      test('goBack does nothing when cannot go back', () {
        expect(router.canGoBack(), isFalse);

        router.goBack();

        expect(router.navigationStack.length, equals(1));
      });

      test('canGoBack returns true when stack has multiple items', () async {
        await router.goTo(AppRoutes.home);

        expect(router.canGoBack(), isTrue);
      });

      test('popUntil pops to matching route', () async {
        await router.goTo(AppRoutes.home);
        await router.goTo(AppRoutes.settings);
        await router.goTo(AppRoutes.notifications);

        final found = await router.popUntil((r) => r.name == 'home');

        expect(found, isTrue);
        expect(router.currentRoute, equals(AppRoutes.home));
      });
    });

    group('Result Awaiting', () {
      test('goToAndAwait receives result', () async {
        final future = router.goToAndAwait<String>(AppRoutes.settings);

        // Simulate returning result from settings page
        await Future.delayed(const Duration(milliseconds: 10));
        router.goBackWithResult('selected_option');

        final result = await future;
        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull, equals('selected_option'));
      });
    });

    group('Navigation History', () {
      test('tracks navigation history', () async {
        await router.goTo(AppRoutes.home);
        await router.goTo(AppRoutes.settings);

        expect(router.navigationHistory.length, equals(3));
        expect(router.navigationHistory[0].route, equals(AppRoutes.splash));
        expect(router.navigationHistory[1].route, equals(AppRoutes.home));
        expect(router.navigationHistory[2].route, equals(AppRoutes.settings));
      });

      test('clearHistory clears history', () async {
        await router.goTo(AppRoutes.home);
        await router.goTo(AppRoutes.settings);

        router.clearHistory();

        expect(router.navigationHistory, isEmpty);
      });

      test('reset returns to initial state', () async {
        await router.goTo(AppRoutes.home);
        await router.goTo(AppRoutes.settings);

        router.reset();

        expect(router.currentRoute, equals(AppRoutes.splash));
        expect(router.navigationStack.length, equals(1));
      });
    });
  });

  group('Route Guard Tests', () {
    late InMemoryAdapter router;

    setUp(() {
      router = InMemoryAdapter(
        configuration: RouterConfiguration(
          routes: AppRoutes.all,
          initialRoute: AppRoutes.splash,
        ),
      );
    });

    tearDown(() {
      router.dispose();
    });

    test('guard allows navigation when returning GuardAllow', () async {
      router.addGlobalGuard(AlwaysAllowGuard.instance);

      final result = await router.goTo(AppRoutes.home);

      expect(result.isSuccess, isTrue);
      expect(router.currentRoute, equals(AppRoutes.home));
    });

    test('guard rejects navigation when returning GuardReject', () async {
      router.addGlobalGuard(
        const AlwaysRejectGuard(reason: 'Access denied'),
      );

      final result = await router.goTo(AppRoutes.home);

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<GuardRejectedError>());
    });

    test('guard redirects when returning GuardRedirect', () async {
      router.addGuardForRoute(
        AppRoutes.settings,
        _RedirectGuard(AppRoutes.login),
      );

      final result = await router.goTo(AppRoutes.settings);

      expect(result.isFailure, isTrue);
      expect(router.currentRoute, equals(AppRoutes.login));
    });

    test('setBypassGuards bypasses all guards', () async {
      router.addGlobalGuard(const AlwaysRejectGuard());
      router.setBypassGuards(true);

      final result = await router.goTo(AppRoutes.home);

      expect(result.isSuccess, isTrue);
      expect(router.currentRoute, equals(AppRoutes.home));
    });

    test('simulateGuardCheck evaluates guards without navigation', () async {
      router.addGlobalGuard(const AlwaysRejectGuard());

      final result = await router.simulateGuardCheck(AppRoutes.home);

      expect(result, isA<GuardReject>());
      expect(router.currentRoute, equals(AppRoutes.splash));
    });

    test('composite guard chains multiple guards', () async {
      final guard = CompositeGuard([
        AlwaysAllowGuard.instance,
        const AlwaysRejectGuard(reason: 'Second guard'),
      ]);

      router.addGlobalGuard(guard);

      final result = await router.goTo(AppRoutes.home);

      expect(result.isFailure, isTrue);
    });

    test('route-specific guards only apply to that route', () async {
      router.addGuardForRoute(
        AppRoutes.settings,
        const AlwaysRejectGuard(),
      );

      // Home should succeed
      final homeResult = await router.goTo(AppRoutes.home);
      expect(homeResult.isSuccess, isTrue);

      // Settings should fail
      final settingsResult = await router.goTo(AppRoutes.settings);
      expect(settingsResult.isFailure, isTrue);
    });
  });

  group('Deep Link Tests', () {
    late InMemoryAdapter router;

    setUp(() {
      router = InMemoryAdapter(
        configuration: RouterConfiguration(
          routes: AppRoutes.all,
          initialRoute: AppRoutes.splash,
        ),
      );
    });

    tearDown(() {
      router.dispose();
    });

    test('handleDeepLink navigates to matched route', () async {
      final result = await router.handleDeepLink(Uri.parse('/settings'));

      expect(result.isSuccess, isTrue);
      expect(router.currentRoute, equals(AppRoutes.settings));
    });

    test('handleDeepLink extracts path params', () async {
      await router.handleDeepLink(Uri.parse('/user/abc123'));

      expect(router.currentRoute, equals(AppRoutes.userProfile));
      expect(router.currentPathParams['id'], equals('abc123'));
    });

    test('handleDeepLink extracts query params', () async {
      await router.handleDeepLink(Uri.parse('/user/abc123?tab=posts'));

      expect(router.currentQueryParams['tab'], equals('posts'));
    });

    test('handleDeepLink returns error for unknown URI', () async {
      final result =
          await router.handleDeepLink(Uri.parse('/nonexistent/path'));

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<DeepLinkError>());
    });

    test('injectDeepLink is convenience method for testing', () async {
      await router.injectDeepLink('/user/test_user?tab=likes');

      expect(router.currentPathParams['id'], equals('test_user'));
      expect(router.currentQueryParams['tab'], equals('likes'));
    });
  });

  group('Navigation Observer Tests', () {
    late InMemoryAdapter router;
    late _TestObserver observer;

    setUp(() {
      observer = _TestObserver();
      router = InMemoryAdapter(
        configuration: RouterConfiguration(
          routes: AppRoutes.all,
          initialRoute: AppRoutes.splash,
          observers: [observer],
        ),
      );
    });

    tearDown(() {
      router.dispose();
    });

    test('observer receives onNavigationStarted', () async {
      await router.goTo(AppRoutes.home);

      expect(observer.startedEvents.length, equals(1));
      expect(observer.startedEvents[0].route, equals(AppRoutes.home));
    });

    test('observer receives onNavigationCompleted', () async {
      await router.goTo(AppRoutes.home);

      // Initial + navigation
      expect(observer.completedEvents.length, equals(2));
      expect(observer.completedEvents[1].route, equals(AppRoutes.home));
    });

    test('observer receives onNavigationFailed', () async {
      router.addGlobalGuard(const AlwaysRejectGuard());

      await router.goTo(AppRoutes.home);

      expect(observer.failedEvents.length, equals(1));
      expect(observer.failedEvents[0].event.route, equals(AppRoutes.home));
    });

    test('addObserver adds new observer', () async {
      final newObserver = _TestObserver();
      router.addObserver(newObserver);

      await router.goTo(AppRoutes.home);

      expect(newObserver.completedEvents.length, equals(1));
    });

    test('removeObserver removes observer', () async {
      router.removeObserver(observer);

      await router.goTo(AppRoutes.home);

      expect(observer.startedEvents, isEmpty);
    });

    test('HistoryTrackingObserver tracks history', () async {
      final historyObserver = HistoryTrackingObserver();
      router.addObserver(historyObserver);

      await router.goTo(AppRoutes.home);
      await router.goTo(AppRoutes.settings);

      expect(historyObserver.history.length, equals(2));
      expect(historyObserver.lastNavigation?.route, equals(AppRoutes.settings));
    });
  });

  group('Navigation Stream Tests', () {
    late InMemoryAdapter router;

    setUp(() {
      router = InMemoryAdapter(
        configuration: RouterConfiguration(
          routes: AppRoutes.all,
          initialRoute: AppRoutes.splash,
        ),
      );
    });

    tearDown(() {
      router.dispose();
    });

    test('navigationStream emits events', () async {
      final events = <NavigationEvent>[];
      final subscription = router.navigationStream.listen(events.add);

      await router.goTo(AppRoutes.home);
      await router.goTo(AppRoutes.settings);

      await Future.delayed(const Duration(milliseconds: 10));

      expect(events.length, equals(2));
      expect(events[0].route, equals(AppRoutes.home));
      expect(events[1].route, equals(AppRoutes.settings));

      await subscription.cancel();
    });
  });

  group('Tab Navigation Tests', () {
    late InMemoryAdapter router;

    setUp(() {
      router = InMemoryAdapter(
        configuration: RouterConfiguration(
          routes: AppRoutes.all,
          initialRoute: AppRoutes.home,
        ),
      );
    });

    tearDown(() {
      router.dispose();
    });

    test('switchToTab changes current tab', () async {
      expect(router.currentTabIndex, equals(0));

      router.switchToTab(1);

      expect(router.currentTabIndex, equals(1));
    });

    test('getCurrentRouteForTab returns tab-specific route', () async {
      // Navigate in tab 0
      await router.goTo(AppRoutes.home);

      // Switch to tab 1 and navigate
      router.switchToTab(1);
      await router.goTo(AppRoutes.search);

      // Current route for tab 1
      expect(
        router.getCurrentRouteForTab(1),
        equals(AppRoutes.search),
      );
    });
  });

  group('NavigationResult Tests', () {
    test('isSuccess returns true for success', () {
      const result = NavigationSuccess<void>(null);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
    });

    test('isFailure returns true for failure', () {
      final result = NavigationFailure<void>(
        const RouteNotFoundError(path: '/test'),
      );
      expect(result.isFailure, isTrue);
      expect(result.isSuccess, isFalse);
    });

    test('valueOrThrow throws for failure', () {
      final result = NavigationFailure<void>(
        const RouteNotFoundError(path: '/test'),
      );
      expect(() => result.valueOrThrow, throwsA(isA<RouteNotFoundError>()));
    });

    test('valueOrNull returns null for failure', () {
      final result = NavigationFailure<String>(
        const RouteNotFoundError(path: '/test'),
      );
      expect(result.valueOrNull, isNull);
    });

    test('map transforms success value', () {
      const result = NavigationSuccess<int>(42);
      final mapped = result.map((v) => 'Value: $v');

      expect(mapped.valueOrNull, equals('Value: 42'));
    });

    test('fold calls correct callback', () {
      const success = NavigationSuccess<int>(42);
      final failure = NavigationFailure<int>(
        const RouteNotFoundError(path: '/test'),
      );

      expect(
        success.fold(
          onSuccess: (v) => 'success: $v',
          onFailure: (e) => 'failure',
        ),
        equals('success: 42'),
      );

      expect(
        failure.fold(
          onSuccess: (v) => 'success',
          onFailure: (e) => 'failure: ${e.message}',
        ),
        equals('failure: Route not found: /test'),
      );
    });
  });

  group('RouteDefinition Tests', () {
    test('pathParameterNames extracts param names', () {
      const route = RouteDefinition(
        path: '/user/:id/post/:postId',
        name: 'userPost',
      );

      expect(route.pathParameterNames, equals(['id', 'postId']));
    });

    test('buildPath substitutes params', () {
      const route = RouteDefinition(
        path: '/user/:id',
        name: 'user',
      );

      expect(route.buildPath({'id': '123'}), equals('/user/123'));
    });

    test('buildUri includes query params', () {
      const route = RouteDefinition(
        path: '/user/:id',
        name: 'user',
      );

      expect(
        route.buildUri(
          pathParams: {'id': '123'},
          queryParams: {'tab': 'posts'},
        ),
        equals('/user/123?tab=posts'),
      );
    });
  });

  group('DeepLinkHandler Tests', () {
    late DefaultDeepLinkHandler handler;

    setUp(() {
      handler = DefaultDeepLinkHandler(AppRoutes.all);
    });

    test('parse matches simple route', () {
      final result = handler.parse(Uri.parse('/settings'));

      expect(result, isNotNull);
      expect(result!.route.name, equals('settings'));
    });

    test('parse extracts path params', () {
      final result = handler.parse(Uri.parse('/user/abc123'));

      expect(result, isNotNull);
      expect(result!.pathParams['id'], equals('abc123'));
    });

    test('parse extracts query params', () {
      final result = handler.parse(Uri.parse('/settings?theme=dark'));

      expect(result, isNotNull);
      expect(result!.queryParams['theme'], equals('dark'));
    });

    test('parse returns null for unknown path', () {
      final result = handler.parse(Uri.parse('/nonexistent'));

      expect(result, isNull);
    });

    test('parseString handles string URIs', () {
      final result = handler.parseString('/user/test');

      expect(result, isNotNull);
      expect(result!.route.name, equals('userProfile'));
    });

    test('canHandle returns true for valid URI', () {
      expect(handler.canHandle(Uri.parse('/settings')), isTrue);
      expect(handler.canHandle(Uri.parse('/unknown')), isFalse);
    });
  });

  group('Error Handler Tests', () {
    late InMemoryAdapter router;
    NavigationError? capturedError;
    RouteDefinition? capturedRoute;

    setUp(() {
      capturedError = null;
      capturedRoute = null;

      router = InMemoryAdapter(
        configuration: RouterConfiguration(
          routes: AppRoutes.all,
          initialRoute: AppRoutes.splash,
        ),
      );

      router.setErrorHandler((error, route) {
        capturedError = error;
        capturedRoute = route;
      });
    });

    tearDown(() {
      router.dispose();
    });

    test('error handler receives guard rejection', () async {
      router.addGlobalGuard(const AlwaysRejectGuard());

      await router.goTo(AppRoutes.home);

      expect(capturedError, isA<GuardRejectedError>());
      expect(capturedRoute, equals(AppRoutes.home));
    });

    test('error handler receives route not found', () async {
      await router.goToPath('/unknown');

      expect(capturedError, isA<RouteNotFoundError>());
    });
  });
}

// ═══════════════════════════════════════════════════════════════════
// Test Helpers
// ═══════════════════════════════════════════════════════════════════

class _TestObserver implements NavigationObserver {
  final List<NavigationEvent> startedEvents = [];
  final List<NavigationEvent> completedEvents = [];
  final List<({NavigationEvent event, Object error})> failedEvents = [];

  @override
  void onNavigationStarted(NavigationEvent event) {
    startedEvents.add(event);
  }

  @override
  void onNavigationCompleted(NavigationEvent event) {
    completedEvents.add(event);
  }

  @override
  void onNavigationFailed(NavigationEvent event, Object error) {
    failedEvents.add((event: event, error: error));
  }
}

class _RedirectGuard implements RouteGuard {
  final RouteDefinition redirectTo;

  _RedirectGuard(this.redirectTo);

  @override
  String get name => 'RedirectGuard';

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    return GuardRedirect(redirectTo);
  }
}
