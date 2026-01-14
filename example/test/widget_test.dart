// Basic widget test for the routing composer example app.

import 'package:flutter_test/flutter_test.dart';
import 'package:routing_composer_example/app/go_router_app.dart';

void main() {
  testWidgets('GoRouterExampleApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GoRouterExampleApp());

    // Verify that the splash screen is displayed.
    expect(find.text('Routing Composer'), findsOneWidget);
    expect(find.text('Loading...'), findsOneWidget);
  });
}
