import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ota_update/ota_update.dart';
import 'package:ecosync/screens/dashboard.dart';
import 'package:ecosync/services/iot_service.dart';

// --- 1. Create a Fake Service ---
class FakeIoTService implements IoTService {
  final _pumpController = StreamController<DatabaseEvent>.broadcast();

  // FIX: Add the 'ready' future required by the new Dashboard logic
  @override
  late final Future<void> ready = Future.value(); // Completes instantly

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  // MOCK STREAMS
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

  // MOCK ACTIONS
  @override
  Future<void> togglePump(bool turnOn) async {}

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
    // Return dummy graph data for the test
    return [
      [const FlSpot(0, 25), const FlSpot(1, 26)], // Temp
      [const FlSpot(0, 50), const FlSpot(1, 45)], // Soil
    ];
  }
}

void main() {
  testWidgets('Dashboard Renders Critical UI Elements (Offline)', (
    WidgetTester tester,
  ) async {
    // 2. Arrange
    final fakeService = FakeIoTService();

    // 3. Act
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          databaseUrl: "ignored",
          iotServiceOverride: fakeService,
        ),
      ),
    );

    // Trigger FutureBuilder
    await tester.pump();

    // 4. Assert
    expect(find.text('EcoSync'), findsOneWidget);
    expect(find.textContaining('PUMP', findRichText: true), findsWidgets);
    expect(find.text('Daily Schedule'), findsOneWidget);

    // Verify Sensors exist
    expect(find.text('Temperature'), findsOneWidget);
  });
}
