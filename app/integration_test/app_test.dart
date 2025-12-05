import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecosync/screens/login_screen.dart';

void main() {
  testWidgets('Login Screen UI Check', (WidgetTester tester) async {
    // 1. Load the Login Screen
    // pumpWidget returns void, so we just await it.
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    // 2. Verify Title Exists
    expect(find.text('ECOSYNC'), findsOneWidget);
    expect(find.text('Smart Home Automation'), findsOneWidget);

    // 3. Verify Google Button Exists
    // We check for the text "Continue with Google"
    expect(find.text('Continue with Google'), findsOneWidget);

    // We check for the Google Icon (g_mobiledata)
    expect(find.byIcon(Icons.g_mobiledata), findsOneWidget);
  });
}
