import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ecosync/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slide_to_act/slide_to_act.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test (diagnostics)', () {
    testWidgets(
      'verify login and dashboard flow',
      (tester) async {
        // 1. Setup
        SharedPreferences.setMockInitialValues({});
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // 2. Verify Login Loaded
        if (find.text('ECOSYNC').evaluate().isEmpty) {
          debugPrint('Login title not found — dumping elements:');
          debugDumpApp();
          fail('Login screen not visible');
        }

        // 3. Enter Data
        final Finder urlFieldFinder = find.byType(TextFormField).first;
        await tester.enterText(
          urlFieldFinder,
          'https://pratik-s-garden-default-rtdb.asia-southeast1.firebasedatabase.app',
        );
        await tester.pumpAndSettle();

        // 4. Hide keyboard safely
        await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // 5. Find Slider
        final Finder sliderFinder = find.byType(SlideAction).first;
        await tester.ensureVisible(sliderFinder);
        await tester.pumpAndSettle();

        // 6. DRAG LOGIC (PRECISE)
        // Get the position of the slider
        final Offset sliderTopLeft = tester.getTopLeft(sliderFinder);

        // Target the "Knob":
        // Usually the knob is at the start (left), centered vertically.
        // Let's guess the knob center is about 30px in and 30px down.
        final Offset knobPos = sliderTopLeft + const Offset(30.0, 30.0);

        // Perform drag from the knob position
        await tester.dragFrom(knobPos, const Offset(300.0, 0));
        await tester.pump(); // Start animation

        // 7. Poll for dashboard
        bool dashboardFound = false;
        for (int i = 0; i < 40; i++) {
          await tester.pump(const Duration(seconds: 1));
          if (find.text('Daily Schedule').evaluate().isNotEmpty) {
            dashboardFound = true;
            break;
          }
        }

        if (!dashboardFound) {
          debugPrint('Dashboard not found — dumping app tree:');
          // debugDumpApp(); // Uncomment if you want huge logs
          fail('Dashboard did not load within timeout.');
        }

        expect(find.text('EcoSync'), findsOneWidget);
        expect(find.text('24h Insights'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 140)),
    );
  });
}
