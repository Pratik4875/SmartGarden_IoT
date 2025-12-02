import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:ota_update/ota_update.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class IoTService {
  late final DatabaseReference _db;

  IoTService(String databaseUrl) {
    debugPrint("🔌 IoTService Initializing with URL: $databaseUrl");
    try {
      FirebaseDatabase instance = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: databaseUrl,
      );
      _db = instance.ref();

      // Test Connection
      _db
          .child('status')
          .get()
          .then((_) {
            debugPrint("✅ Database Connected Successfully!");
          })
          .catchError((e) {
            debugPrint("❌ Database Connection Failed: $e");
          });
    } catch (e) {
      debugPrint("❌ Critical Error Initializing DB: $e");
    }
  }

  // --- STREAMS ---
  // Added error handling to streams
  Stream<DatabaseEvent> get pumpStatusStream => _db
      .child('control/pump')
      .onValue
      .handleError((e) => debugPrint("Stream Error (Pump): $e"));
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

  // --- ACTIONS ---

  Future<void> togglePump(bool turnOn) async {
    try {
      await _db.child('control/pump').set(turnOn);
      if (turnOn) {
        await _db.child('control/request_time').set(ServerValue.timestamp);
      }
    } catch (e) {
      debugPrint("❌ Error Toggling Pump: $e");
      // You could throw this to show a Snackbar in UI
      rethrow;
    }
  }

  Future<void> setSchedule(
    bool enabled,
    DateTime? localTime,
    int? duration,
  ) async {
    try {
      Map<String, Object> updates = {};
      updates['config/scheduler/enabled'] = enabled;

      if (duration != null) updates['config/scheduler/duration_sec'] = duration;

      if (localTime != null) {
        DateTime utcTime = localTime.toUtc();
        String hour = utcTime.hour.toString().padLeft(2, '0');
        String minute = utcTime.minute.toString().padLeft(2, '0');
        updates['config/scheduler/time_utc'] = "$hour:$minute";
      }

      await _db.update(updates);
    } catch (e) {
      debugPrint("❌ Error Setting Schedule: $e");
    }
  }

  // --- AUTO UPDATE ---
  Stream<OtaEvent> updateApp() {
    try {
      return OtaUpdate().execute(
        'https://github.com/Pratik4875/SmartGarden_IoT/releases/latest/download/app-release.apk',
        destinationFilename: 'app-release.apk',
      );
    } catch (e) {
      debugPrint('❌ OTA Error: $e');
      rethrow;
    }
  }

  // --- ANALYTICS (Robust) ---
  Future<List<List<FlSpot>>> getHistoryData() async {
    debugPrint("📊 Fetching History Data...");
    try {
      final snapshot = await _db.child('history').get();

      List<FlSpot> tempSpots = [];
      List<FlSpot> soilSpots = [];

      if (snapshot.exists && snapshot.value != null) {
        debugPrint(
          "📊 History Data Found: ${snapshot.children.length} entries",
        );

        // Handle different data structures (List vs Map)
        List<Map<dynamic, dynamic>> safeEntries = [];

        if (snapshot.value is List) {
          var list = snapshot.value as List;
          for (var item in list) {
            if (item != null) safeEntries.add(item as Map);
          }
        } else if (snapshot.value is Map) {
          var map = snapshot.value as Map;
          map.forEach((key, value) {
            safeEntries.add(value as Map);
          });
        }

        // Sort
        safeEntries.sort((a, b) => (a['ts'] ?? 0).compareTo(b['ts'] ?? 0));

        // Limit
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
      } else {
        debugPrint("⚠️ No History Data Found in DB");
      }

      return [tempSpots, soilSpots];
    } catch (e) {
      debugPrint("❌ Error Fetching History: $e");
      return [[], []]; // Return empty lists so graph doesn't crash
    }
  }
}
