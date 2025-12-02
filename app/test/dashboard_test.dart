import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ota_update/ota_update.dart';
import 'package:ecosync/screens/dashboard.dart';
import 'package:ecosync/services/iot_service.dart';

// --- 1. Create a Fake Service ---
// "implements" forces us to define every method, bypassing the real constructor
class FakeIoTService implements IoTService {
  final _pumpController = StreamController<DatabaseEvent>.broadcast();

  // We don't need a real DB reference for the fake
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  // MOCK STREAMS: Return dummy events so the UI can build
  // We use Stream.empty() to simulate "No data yet", or we could emit data to test values.

  @override
  Stream<DatabaseEvent> get pumpStatusStream => _pumpController.stream;

  @override
  Stream<DatabaseEvent> get tempStream => const Stream.empty();

  @override
  Stream<DatabaseEvent> get humidityStream => const Stream.empty();

  @override
  Stream<DatabaseEvent> get soilStream => const Stream.empty();

  @override
  Stream<DatabaseEvent> get lastWateredStream => const Stream.empty();

  @override
  Stream<DatabaseEvent> get scheduleEnabledStream => const Stream.empty();

  @override
  Stream<DatabaseEvent> get scheduleTimeStream => const Stream.empty();

  @override
  Stream<DatabaseEvent> get scheduleDurationStream => const Stream.empty();

  // MOCK ACTIONS: Do nothing or print to console
  @override
  Future<void> togglePump(bool turnOn) async {
    // We can simulate the DB update loop-back here if we wanted
    // For now, just resolving the future is enough
  }

  @override
  Future<void> setSchedule(
    bool enabled,
    DateTime? localTime,
    int? duration,
  ) async {}

  @override
  Stream<OtaEvent> updateApp() {
    return const Stream.empty();
  }

  @override
  Future<List<List<FlSpot>>> getHistoryData() async {
    return [[], []]; // Return empty graph data
  }
}

void main() {
  testWidgets('Dashboard Renders Critical UI Elements (Offline)', (
    WidgetTester tester,
  ) async {
    // 2. Arrange: Create the fake service
    final fakeService = FakeIoTService();

    // 3. Act: Load Dashboard, injecting the fake service
    // We pass "ignored" for the URL because the fake service doesn't use it.
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          databaseUrl: "ignored",
          iotServiceOverride: fakeService, // <--- INJECTION POINT
        ),
      ),
    );

    // Let the UI settle
    await tester.pump();

    // 4. Assert: Check for Branding
    expect(find.text('EcoSync'), findsOneWidget);

    // 5. Assert: Check for Pump Button logic
    // The button might show "START PUMP" or "STOP PUMP". We check for "PUMP".
    expect(find.textContaining('PUMP', findRichText: true), findsWidgets);

    // 6. Assert: Check for Scheduler
    expect(find.text('Daily Schedule'), findsOneWidget);

    // 7. Assert: Check for Sensor Cards
    expect(find.text('Temperature'), findsOneWidget);
    expect(find.text('Humidity'), findsOneWidget);
    expect(find.text('Soil Moisture'), findsOneWidget);
  });
}
