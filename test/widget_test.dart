// test/widget_test.dart
//
// Basic smoke test – verifies that the app starts and renders the
// bottom navigation bar with all five destinations.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_vault/main.dart';

void main() {
  testWidgets('App renders bottom navigation bar', (WidgetTester tester) async {
    await tester.pumpWidget(const ReceiptVaultApp());
    // Allow GoRouter to settle.
    await tester.pumpAndSettle();

    // The NavigationBar should be present.
    expect(find.byType(NavigationBar), findsOneWidget);

    // All five tab labels should be visible in the NavigationBar.
    // findsWidgets is used because the active tab may also show the label
    // in the AppBar title, producing more than one match for that tab.
    expect(find.text('Receipts'), findsWidgets);
    expect(find.text('Warranties'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Alerts'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
