import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:ota_update/ota_update.dart';
import 'notification_service.dart';

abstract class ControlDataClient {
  DatabaseReference? get db; // Public
  bool get isConnected;
  NotificationService get notifications; // Public

  void updateLastDryAlertTime(DateTime? time);
  DateTime? get lastDryAlertTime;

  int? get startMoisture;
  void setStartMoisture(int? moisture);

  Stream<DatabaseEvent> get soilStream;
}

class IoTControlAndData {
  final ControlDataClient _client;
  final int _dryThreshold = 30;
  Timer? _failureCheckTimer;

  IoTControlAndData(this._client);

  // --- STREAMS ---
  // FIX: Using public .db accessor
  Stream<DatabaseEvent> get pumpStatusStream =>
      _client.db?.child('control/pump').onValue ??
      const Stream<DatabaseEvent>.empty();

  Stream<DatabaseEvent> get requestTimeStream =>
      _client.db?.child('control/request_time').onValue ??
      const Stream<DatabaseEvent>.empty();

  Stream<DatabaseEvent> get tempStream =>
      _client.db?.child('sensors/dht/temp').onValue ??
      const Stream<DatabaseEvent>.empty();

  Stream<DatabaseEvent> get humidityStream =>
      _client.db?.child('sensors/dht/humidity').onValue ??
      const Stream<DatabaseEvent>.empty();

  Stream<DatabaseEvent> get lastWateredStream =>
      _client.db?.child('status/last_watered').onValue ??
      const Stream<DatabaseEvent>.empty();

  Stream<DatabaseEvent> get schedulesStream =>
      _client.db?.child('config/schedules').onValue ??
      const Stream<DatabaseEvent>.empty();

  // --- ACTIONS ---
  Future<void> togglePump(bool turnOn) async {
    if (!_client.isConnected) return;
    await _client.db!.child('control/pump').set(turnOn);
    if (turnOn) {
      await _client.db!
          .child('control/request_time')
          .set(ServerValue.timestamp);
    }
  }

  Future<void> updateScheduleSlot(
    int index,
    bool enabled,
    DateTime localTime,
    int duration,
  ) async {
    if (!_client.isConnected) return;
    DateTime utc = localTime.toUtc();
    String timeStr =
        "${utc.hour.toString().padLeft(2, '0')}:${utc.minute.toString().padLeft(2, '0')}";
    await _client.db!.child('config/schedules/$index').update({
      'enabled': enabled,
      'time_utc': timeStr,
      'duration_sec': duration,
    });
  }

  Future<void> deleteScheduleSlot(int index) async {
    if (!_client.isConnected) return;
    await _client.db!.child('config/schedules/$index').set({
      'enabled': false,
      'time_utc': "00:00",
      'duration_sec': 0,
    });
  }

  Future<List<dynamic>> getSchedulesOnce() async {
    if (!_client.isConnected) return [];
    final snapshot = await _client.db!.child('config/schedules').get();
    if (snapshot.exists && snapshot.value != null) {
      if (snapshot.value is List) return snapshot.value as List;
      if (snapshot.value is Map) {
        Map map = snapshot.value as Map;
        List<dynamic> list = List.filled(5, null);
        map.forEach((k, v) {
          int? idx = int.tryParse(k.toString());
          if (idx != null && idx < 5) list[idx] = v;
        });
        return list;
      }
    }
    return [];
  }

  Stream<OtaEvent> updateApp() {
    return OtaUpdate().execute(
      'https://github.com/Pratik4875/SmartGarden_IoT/releases/latest/download/EcoSync.apk',
      destinationFilename: 'EcoSync.apk',
    );
  }

  // --- MONITORING LOGIC ---
  void startSmartMonitoring() {
    if (!_client.isConnected) return;

    _client.soilStream.listen((event) {
      if (event.snapshot.value != null) {
        int moisture = int.tryParse(event.snapshot.value.toString()) ?? 0;
        _checkSoilHealth(moisture);
      }
    });

    pumpStatusStream.listen((event) async {
      bool isPumpOn = (event.snapshot.value == true);
      if (isPumpOn) {
        final snap = await _client.db!.child('sensors/soil/percent').get();
        _client.setStartMoisture(int.tryParse(snap.value.toString()) ?? 0);

        _failureCheckTimer?.cancel();
        _failureCheckTimer = Timer(
          const Duration(seconds: 60),
          _checkWateringSuccess,
        );
      }
    });
  }

  void _checkSoilHealth(int moisture) {
    final now = DateTime.now();
    if (moisture <= 5) {
      if (_client.lastDryAlertTime == null ||
          now.difference(_client.lastDryAlertTime!).inMinutes > 30) {
        _client.notifications.showNotification(
          id: 3,
          title: "⚠️ Sensor Error",
          body: "Check wiring.",
        );
        _client.updateLastDryAlertTime(now);
      }
      return;
    }
    if (moisture < _dryThreshold) {
      if (_client.lastDryAlertTime == null ||
          now.difference(_client.lastDryAlertTime!).inHours > 6) {
        _client.notifications.showNotification(
          id: 1,
          title: "🌱 Thirsty!",
          body: "Soil is $moisture%.",
        );
        _client.updateLastDryAlertTime(now);
      }
    }
  }

  Future<void> _checkWateringSuccess() async {
    if (_client.startMoisture == null) return;
    final snap = await _client.db!.child('sensors/soil/percent').get();
    int endMoisture = int.tryParse(snap.value.toString()) ?? 0;

    if (endMoisture < 95 &&
        (endMoisture - _client.startMoisture!) < 3 &&
        _client.startMoisture! < 90) {
      _client.notifications.showNotification(
        id: 2,
        title: "⚠️ Watering Failed",
        body: "Check pump/tank.",
      );
    }
    _client.setStartMoisture(null);
  }

  // --- REFRESH / DATA ---
  Future<String> forceStatusRefresh() async {
    if (!_client.isConnected) return "App Offline. Check Internet.";
    try {
      final tsSnap = await _client.db!.child('device/ts').get();
      await _client.db!.child('status/last_watered').get();
      await _client.db!.child('control/request_time').get();
      await _client.db!.child('sensors').get();

      int deviceTs = int.tryParse(tsSnap.value?.toString() ?? '0') ?? 0;
      int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      int diff = now - deviceTs;

      if (diff < 120) return "Device Online & Synced";
      int mins = diff ~/ 60;
      return "Device Offline (Last seen ${mins}m ago)";
    } catch (e) {
      return "Sync Failed: ${e.toString()}";
    }
  }

  Future<List<List<FlSpot>>> getHistoryData() async {
    if (!_client.isConnected) return [[], []];
    final snapshot = await _client.db!.child('history').get();
    List<FlSpot> tempSpots = [];
    List<FlSpot> soilSpots = [];

    if (snapshot.exists && snapshot.value != null) {
      try {
        List<dynamic> rawValues = [];
        if (snapshot.value is Map)
          rawValues = (snapshot.value as Map).values.toList();
        else if (snapshot.value is List)
          rawValues = snapshot.value as List;

        List<Map> cleanEntries = [];
        for (var item in rawValues) {
          if (item != null && item is Map) cleanEntries.add(item);
        }

        cleanEntries.sort((a, b) {
          int tsA = int.tryParse(a['ts'].toString()) ?? 0;
          int tsB = int.tryParse(b['ts'].toString()) ?? 0;
          return tsA.compareTo(tsB);
        });

        if (cleanEntries.length > 24)
          cleanEntries = cleanEntries.sublist(cleanEntries.length - 24);

        int index = 0;
        for (var data in cleanEntries) {
          double t = double.tryParse(data['t'].toString()) ?? 0;
          double s = double.tryParse(data['s'].toString()) ?? 0;
          tempSpots.add(FlSpot(index.toDouble(), t));
          soilSpots.add(FlSpot(index.toDouble(), s));
          index++;
        }
      } catch (e) {
        debugPrint("History Error: $e");
      }
    }
    return [tempSpots, soilSpots];
  }

  Future<Map<String, double>> getDailyInsights() async {
    if (!_client.isConnected)
      return {'minTemp': 0, 'maxTemp': 0, 'minSoil': 0, 'maxSoil': 0};
    final snapshot = await _client.db!.child('history').get();

    if (snapshot.exists && snapshot.value != null) {
      try {
        List<dynamic> rawValues = [];
        if (snapshot.value is Map)
          rawValues = (snapshot.value as Map).values.toList();
        else if (snapshot.value is List)
          rawValues = snapshot.value as List;

        int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        int oneDayAgo = now - 86400;

        List<double> temps = [];
        List<double> soils = [];

        for (var item in rawValues) {
          if (item == null || item is! Map) continue;
          int ts = int.tryParse(item['ts'].toString()) ?? 0;
          if (ts > oneDayAgo) {
            double t = double.tryParse(item['t'].toString()) ?? 0;
            double s = double.tryParse(item['s'].toString()) ?? 0;
            if (t > 0) temps.add(t);
            if (s > 0) soils.add(s);
          }
        }

        if (temps.isEmpty)
          return {'minTemp': 0, 'maxTemp': 0, 'minSoil': 0, 'maxSoil': 0};

        return {
          'minTemp': temps.reduce(math.min),
          'maxTemp': temps.reduce(math.max),
          'minSoil': soils.reduce(math.min),
          'maxSoil': soils.reduce(math.max),
        };
      } catch (e) {
        debugPrint("Insights Calculation Error: $e");
      }
    }
    return {'minTemp': 0, 'maxTemp': 0, 'minSoil': 0, 'maxSoil': 0};
  }
}
