import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routing_composer/routing_composer.dart';
import 'package:routing_composer/core/routing/utils/iterable_extensions.dart';

void main() {
  group('ShellRouteData', () {
    test('creates with default values', () {
      const data = ShellRouteData();

      expect(data.currentRoute, isNull);
      expect(data.pathParams, isEmpty);
      expect(data.queryParams, isEmpty);
    });

    test('creates with provided values', () {
      const data = ShellRouteData(
        currentRoute: AppRoutes.home,
        pathParams: {'id': '123'},
        queryParams: {'tab': 'posts'},
      );

      expect(data.currentRoute, equals(AppRoutes.home));
      expect(data.pathParams['id'], equals('123'));
      expect(data.queryParams['tab'], equals('posts'));
    });
  });

  group('IterableExtension', () {
    test('firstWhereOrNull returns matching element', () {
      final list = [1, 2, 3, 4, 5];

      final result = list.firstWhereOrNull((e) => e > 3);

      expect(result, equals(4));
    });

    test('firstWhereOrNull returns null when no match', () {
      final list = [1, 2, 3];

      final result = list.firstWhereOrNull((e) => e > 10);

      expect(result, isNull);
    });

    test('firstWhereOrNull works on empty list', () {
      final list = <int>[];

      final result = list.firstWhereOrNull((e) => true);

      expect(result, isNull);
    });

    test('firstWhereOrNull returns first match', () {
      final list = [1, 2, 3, 4, 5];

      final result = list.firstWhereOrNull((e) => e % 2 == 0);

      expect(result, equals(2));
    });
  });

  group('PageBuilder typedef', () {
    test('has correct signature', () {
      // This test verifies the typedef signature at compile time.
      // We test that a function with the expected signature can be assigned.
      Widget testBuilder(
        BuildContext context,
        RouteDefinition route,
        Map<String, String> pathParams,
        Map<String, String> queryParams,
        Object? extra,
      ) {
        return const SizedBox.shrink();
      }

      // If this compiles, the typedef has the correct signature
      final PageBuilder builder = testBuilder;
      expect(builder, isA<PageBuilder>());
    });
  });

  group('AutoRouteShellBuilder typedef', () {
    test('has correct signature', () {
      Widget testBuilder(
        BuildContext context,
        ShellRouteData data,
        Widget child,
      ) {
        return child;
      }

      final AutoRouteShellBuilder builder = testBuilder;
      expect(builder, isA<AutoRouteShellBuilder>());
    });

    test('shell data provides route info to builder', () {
      // Simulate what the adapter does when building a shell
      final data = ShellRouteData(
        currentRoute: AppRoutes.settings,
        pathParams: {'id': 'test'},
        queryParams: {'mode': 'edit'},
      );

      // Verify the data structure that would be passed to shell builders
      expect(data.currentRoute, equals(AppRoutes.settings));
      expect(data.pathParams['id'], equals('test'));
      expect(data.queryParams['mode'], equals('edit'));
    });
  });
}

// Note: Full integration tests for AutoRouteAdapter require a Flutter widget
// test environment with MaterialApp. The InMemoryAdapter tests in
// navigation_test.dart verify the AppRouter interface contract which
// AutoRouteAdapter implements.
//
// For widget testing AutoRouteAdapter:
//
// ```dart
// testWidgets('AutoRouteAdapter navigates correctly', (tester) async {
//   final adapter = AutoRouteAdapter(
//     configuration: RouterConfiguration(
//       routes: AppRoutes.all,
//       initialRoute: AppRoutes.home,
//     ),
//     pageBuilder: (context, route, pathParams, queryParams, extra) {
//       return switch (route.name) {
//         'home' => const Text('Home'),
//         'settings' => const Text('Settings'),
//         _ => const Text('Not Found'),
//       };
//     },
//   );
//
//   await tester.pumpWidget(
//     MaterialApp.router(routerConfig: adapter.routerConfig),
//   );
//
//   expect(find.text('Home'), findsOneWidget);
//
//   await adapter.goTo(AppRoutes.settings);
//   await tester.pumpAndSettle();
//
//   expect(find.text('Settings'), findsOneWidget);
// });
// ```
