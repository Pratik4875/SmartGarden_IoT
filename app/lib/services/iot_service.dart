import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ota_update/ota_update.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

class IoTService {
  late final DatabaseReference _db;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notifications = NotificationService();

  late final Future<void> ready;

  // --- SMART MONITORING VARIABLES ---
  DateTime? _lastDryAlertTime;
  final int _dryThreshold = 30;

  // --- FAILURE DETECTION VARIABLES ---
  int? _startMoisture;
  Timer? _failureCheckTimer;

  IoTService(String databaseUrl) {
    FirebaseDatabase instance = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: databaseUrl,
    );
    _db = instance.ref();

    ready = _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _notifications.initialize();

      if (_auth.currentUser == null) {
        debugPrint("🔒 Attempting Anonymous Sign-In...");
        await _auth.signInAnonymously();
        debugPrint("✅ Signed In! User ID: ${_auth.currentUser?.uid}");
      } else {
        debugPrint("✅ Already Signed In: ${_auth.currentUser?.uid}");
      }

      _startSmartMonitoring();
    } catch (e) {
      debugPrint("❌ CRITICAL ERROR: $e");
    }
  }

  // --- SMART LOGIC ---
  void _startSmartMonitoring() {
    // 1. Monitor Soil for Alerts
    _db.child('sensors/soil/percent').onValue.listen((event) {
      if (event.snapshot.value != null) {
        int moisture = int.tryParse(event.snapshot.value.toString()) ?? 0;
        _checkSoilHealth(moisture);
      }
    });

    // 2. Monitor Pump for Success/Failure
    _db.child('control/pump').onValue.listen((event) async {
      bool isPumpOn = (event.snapshot.value == true);

      if (isPumpOn) {
        // Pump JUST started: Record initial moisture
        final snap = await _db.child('sensors/soil/percent').get();
        _startMoisture = int.tryParse(snap.value.toString()) ?? 0;

        // Schedule check in 60 seconds
        _failureCheckTimer?.cancel();
        _failureCheckTimer = Timer(
          const Duration(seconds: 60),
          _checkWateringSuccess,
        );
        debugPrint("💧 Pump Started. Start Moisture: $_startMoisture%");
      }
    });
  }

  // Logic 1: Soil Health Checks (Dry / Disconnected)
  void _checkSoilHealth(int moisture) {
    final now = DateTime.now();

    // Case A: Sensor Disconnected (0-5%)
    if (moisture <= 5) {
      if (_lastDryAlertTime == null ||
          now.difference(_lastDryAlertTime!).inMinutes > 30) {
        _notifications.showNotification(
          id: 3,
          title: "⚠️ Sensor Error",
          body: "Moisture is near 0%. Check wiring or sensor placement.",
        );
        _lastDryAlertTime = now; // Reuse timer to prevent spam
      }
      return;
    }

    // Case B: Dry Soil (5-30%)
    if (moisture < _dryThreshold) {
      if (_lastDryAlertTime == null ||
          now.difference(_lastDryAlertTime!).inHours > 6) {
        _notifications.showNotification(
          id: 1,
          title: "🌱 Plant is Thirsty!",
          body: "Soil is dry ($moisture%). Time to water.",
        );
        _lastDryAlertTime = now;
      }
    }
  }

  // Logic 2: Watering Verification
  Future<void> _checkWateringSuccess() async {
    if (_startMoisture == null) return;

    final snap = await _db.child('sensors/soil/percent').get();
    int endMoisture = int.tryParse(snap.value.toString()) ?? 0;
    int difference = endMoisture - _startMoisture!;

    // Case A: Already Wet (Success)
    if (endMoisture >= 95) {
      debugPrint("✅ Watering Success: Soil is fully saturated ($endMoisture%)");
      _startMoisture = null;
      return;
    }

    // Case B: Significant Increase (Success)
    if (difference >= 3) {
      debugPrint("✅ Watering Success: Moisture rose by $difference%");
      _startMoisture = null;
      return;
    }

    // Case C: No Increase (Failure)
    // Only alert if we started below 90%
    if (_startMoisture! < 90) {
      _notifications.showNotification(
        id: 2,
        title: "⚠️ Watering Failed",
        body: "Pump ran, but soil didn't get wetter. Empty tank?",
      );
      debugPrint("❌ Failure: Start $_startMoisture -> End $endMoisture");
    }

    _startMoisture = null;
  }

  // --- STREAMS ---
  Stream<DatabaseEvent> get pumpStatusStream =>
      _db.child('control/pump').onValue;
  Stream<DatabaseEvent> get tempStream => _db.child('sensors/dht/temp').onValue;
  Stream<DatabaseEvent> get humidityStream =>
      _db.child('sensors/dht/humidity').onValue;
  Stream<DatabaseEvent> get soilStream =>
      _db.child('sensors/soil/percent').onValue;
  Stream<DatabaseEvent> get lastWateredStream =>
      _db.child('status/last_watered').onValue;

  Stream<DatabaseEvent> get scheduleEnabledStream =>
      _db.child('config/scheduler/enabled').onValue;
  Stream<DatabaseEvent> get scheduleTimeStream =>
      _db.child('config/scheduler/time_utc').onValue;
  Stream<DatabaseEvent> get scheduleDurationStream =>
      _db.child('config/scheduler/duration_sec').onValue;
  Stream<DatabaseEvent> get deviceLastSeenStream =>
      _db.child('device/ts').onValue;

  // --- ACTIONS ---
  Future<void> togglePump(bool turnOn) async {
    await _db.child('control/pump').set(turnOn);
    if (turnOn) {
      await _db.child('control/request_time').set(ServerValue.timestamp);
    }
  }

  Future<void> setSchedule(
    bool enabled,
    DateTime? localTime,
    int? duration,
  ) async {
    Map<String, Object> updates = {};
    updates['config/scheduler/enabled'] = enabled;

    if (duration != null) {
      updates['config/scheduler/duration_sec'] = duration;
    }

    if (localTime != null) {
      DateTime utcTime = localTime.toUtc();
      String hour = utcTime.hour.toString().padLeft(2, '0');
      String minute = utcTime.minute.toString().padLeft(2, '0');
      updates['config/scheduler/time_utc'] = "$hour:$minute";
    }

    await _db.update(updates);
  }

  Stream<OtaEvent> updateApp() {
    try {
      return OtaUpdate().execute(
        'https://github.com/Pratik4875/SmartGarden_IoT/releases/latest/download/EcoSync.apk',
        destinationFilename: 'EcoSync.apk',
      );
    } catch (e) {
      debugPrint('Failed to make OTA update. Details: $e');
      rethrow;
    }
  }

  // --- HISTORY & INSIGHTS ---
  Future<List<List<FlSpot>>> getHistoryData() async {
    final snapshot = await _db.child('history').get();
    List<FlSpot> tempSpots = [];
    List<FlSpot> soilSpots = [];

    if (snapshot.exists && snapshot.value != null) {
      try {
        List<Map<dynamic, dynamic>> safeEntries = [];

        if (snapshot.value is List) {
          var list = snapshot.value as List;
          for (var item in list) {
            if (item != null) {
              safeEntries.add(item as Map);
            }
          }
        } else if (snapshot.value is Map) {
          var map = snapshot.value as Map;
          map.forEach((key, value) {
            safeEntries.add(value as Map);
          });
        }

        safeEntries.sort((a, b) => (a['ts'] ?? 0).compareTo(b['ts'] ?? 0));

        if (safeEntries.length > 24) {
          safeEntries = safeEntries.sublist(safeEntries.length - 24);
        }

        int index = 0;
        for (var data in safeEntries) {
          double t = (data['t'] as num? ?? 0).toDouble();
          double s = (data['s'] as num? ?? 0).toDouble();

          tempSpots.add(FlSpot(index.toDouble(), t));
          soilSpots.add(FlSpot(index.toDouble(), s));
          index++;
        }
      } catch (e) {
        debugPrint("Error parsing history: $e");
      }
    }
    return [tempSpots, soilSpots];
  }

  Future<Map<String, double>> getDailyInsights() async {
    final snapshot = await _db.child('history').get();

    double minTemp = 100.0;
    double maxTemp = 0.0;
    double minSoil = 100.0;
    double maxSoil = 0.0;

    if (!snapshot.exists || snapshot.value == null) {
      return {'minTemp': 0, 'maxTemp': 0, 'minSoil': 0, 'maxSoil': 0};
    }

    try {
      Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;

      int nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      int oneDayAgo = nowSec - 86400;

      for (var entry in values.values) {
        int ts = (entry['ts'] as num).toInt();
        if (ts > oneDayAgo) {
          double t = (entry['t'] as num).toDouble();
          double s = (entry['s'] as num).toDouble();

          if (t < minTemp) {
            minTemp = t;
          }
          if (t > maxTemp) {
            maxTemp = t;
          }
          if (s < minSoil) {
            minSoil = s;
          }
          if (s > maxSoil) {
            maxSoil = s;
          }
        }
      }

      if (minTemp == 100.0) {
        minTemp = 0.0;
      }
    } catch (e) {
      debugPrint("Error calculating insights: $e");
    }

    return {
      'minTemp': minTemp,
      'maxTemp': maxTemp,
      'minSoil': minSoil,
      'maxSoil': maxSoil,
    };
  }
}
