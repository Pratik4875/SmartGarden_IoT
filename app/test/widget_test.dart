import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecosync/screens/login_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Login Screen Validation & Success', (WidgetTester tester) async {
    // Variable to verify success
    String? capturedUrl;

    // 1. Load Screen with a Test Callback
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onLoginSuccess: (url) {
            capturedUrl = url; // Capture the URL instead of navigating
          },
        ),
      ),
    );

    // 2. Test Invalid Input
    await tester.enterText(find.byType(TextFormField).first, 'bad-url');
    await tester.tap(find.text('CONNECT HUB'));
    await tester.pump();
    expect(find.text("Must start with http/https"), findsOneWidget);

    // 3. Test Valid Input
    await tester.enterText(
      find.byType(TextFormField).first,
      'https://pratik-s-garden-default-rtdb.asia-southeast1.firebasedatabase.app',
    );
    await tester.tap(find.text('CONNECT HUB'));

    // Fast forward the 1-second delay
    await tester.pump(const Duration(seconds: 1));

    // 4. Assert Success
    // If capturedUrl is set, it means the logic worked and tried to "Login"
    expect(
      capturedUrl,
      'https://pratik-s-garden-default-rtdb.asia-southeast1.firebasedatabase.app',
    );
  });
}
