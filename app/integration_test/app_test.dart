// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecosync/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test (complete flow)', () {
    testWidgets(
      'verify login -> scheduler -> pump -> logout',
      (tester) async {
        // Start with no saved URL so the app shows the login screen.
        SharedPreferences.setMockInitialValues({});

        // Start the app and wait for Firebase/init to finish.
        await app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // --- PHASE 1: LOGIN ---
        final Finder urlFieldFinder = find.byType(TextFormField).first;
        expect(urlFieldFinder, findsOneWidget, reason: 'URL input not found');

        await tester.enterText(
          urlFieldFinder,
          'https://pratik-s-garden-default-rtdb.asia-southeast1.firebasedatabase.app',
        );
        await tester.pumpAndSettle();

        // Hide keyboard and wait for UI to settle.
        await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Find the login slider area (wrapper for SlideAction)
        final Finder loginArea = find.byKey(const Key('loginSliderArea'));
        expect(loginArea, findsOneWidget, reason: 'loginSliderArea missing');

        // DEBUG: print coordinates and size so you can inspect if needed
        final Rect areaRect = tester.getRect(loginArea);
        debugPrint('loginArea rect: $areaRect');

        // Compute a start point near the left edge and vertically centered.
        // IMPORTANT: start slightly inside the left edge (8-12 px) so it hits the knob.
        final Offset start =
            areaRect.topLeft + Offset(10.0, areaRect.height / 2);
        final double dragDistance =
            areaRect.width - 20.0; // generous distance to the right
        final Offset endOffset = Offset(dragDistance, 0.0);

        debugPrint('Drag start: $start  dragDistance: $dragDistance');

        // Execute the drag from the left-side start point to the right.
        await tester.dragFrom(start, endOffset);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // --- Wait for Dashboard to appear ---
        bool dashboardFound = false;
        for (int i = 0; i < 40; i++) {
          await tester.pump(const Duration(seconds: 1));
          if (find.text('Daily Schedule').evaluate().isNotEmpty) {
            dashboardFound = true;
            break;
          }
        }
        if (!dashboardFound) {
          debugPrint('Dashboard did not appear in time. Dumping widget tree:');
          debugDumpApp();
          fail('Dashboard did not load within timeout.');
        }

        expect(find.text('EcoSync'), findsOneWidget);

        // --- PHASE 2: SCHEDULER TOGGLE ---
        debugPrint('🧪 Testing Scheduler Switch...');
        final Finder schedulerSwitch = find.byKey(const Key('schedulerSwitch'));
        expect(
          schedulerSwitch,
          findsOneWidget,
          reason: 'schedulerSwitch missing',
        );
        await tester.ensureVisible(schedulerSwitch);
        await tester.pumpAndSettle();
        await tester.tap(schedulerSwitch);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // --- PHASE 3: PUMP CONTROL ---
        debugPrint('🧪 Testing Pump Control (tap)...');
        final Finder pumpControl = find.byKey(const Key('pumpControl'));
        expect(pumpControl, findsOneWidget, reason: 'pumpControl missing');
        await tester.ensureVisible(pumpControl);
        await tester.pumpAndSettle();
        await tester.tap(pumpControl);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final bool pumpTextVisible =
            find.text('PUMP ACTIVE').evaluate().isNotEmpty ||
            find.text('START PUMP').evaluate().isNotEmpty;
        expect(pumpTextVisible, isTrue, reason: 'Pump label not visible');

        // --- PHASE 4: LOGOUT ---
        debugPrint('🧪 Testing Logout...');
        final Finder logoutBtn = find.byIcon(Icons.logout).first;
        expect(logoutBtn, findsOneWidget, reason: 'Logout button missing');
        await tester.tap(logoutBtn);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Final check: the login screen should be visible again (slide text)
        expect(
          find.text('SLIDE TO CONNECT'),
          findsOneWidget,
          reason: 'Did not return to login after logout',
        );

        debugPrint('✅ Complete User Flow Verified!');
      },
      timeout: const Timeout(Duration(seconds: 240)),
    );
  });
}
