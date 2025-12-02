import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ota_update/ota_update.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';

class IoTService {
  late final DatabaseReference _db;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // NEW: A public future that the UI can wait for
  late final Future<void> ready;

  IoTService(String databaseUrl) {
    // 1. Initialize Database Reference immediately (so UI doesn't crash)
    FirebaseDatabase instance = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: databaseUrl,
    );
    _db = instance.ref();

    // 2. Perform Auth Handshake and save the Future
    ready = _authenticate();
  }

  Future<void> _authenticate() async {
    try {
      // Check if already signed in
      if (_auth.currentUser == null) {
        debugPrint("🔒 Attempting Anonymous Sign-In...");
        await _auth.signInAnonymously();
        debugPrint("✅ Signed In! User ID: ${_auth.currentUser?.uid}");
      } else {
        debugPrint("✅ Already Signed In: ${_auth.currentUser?.uid}");
      }
    } catch (e) {
      debugPrint("❌ CRITICAL AUTH ERROR: $e");
      // If this fails, Firebase Rules will block all data.
    }
  }

  // ... (Rest of your code: Streams, Actions, etc.) ...
  // Paste the rest of your existing file here

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

  Future<void> togglePump(bool turnOn) async {
    await _db.child('control/pump').set(turnOn);
    if (turnOn)
      await _db.child('control/request_time').set(ServerValue.timestamp);
  }

  Future<void> setSchedule(
    bool enabled,
    DateTime? localTime,
    int? duration,
  ) async {
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
  }

  Stream<OtaEvent> updateApp() {
    return OtaUpdate().execute(
      'https://github.com/Pratik4875/SmartGarden_IoT/releases/latest/download/EcoSync.apk',
      destinationFilename: 'EcoSync.apk',
    );
  }

  Future<List<List<FlSpot>>> getHistoryData() async {
    final snapshot = await _db.child('history').get();
    List<FlSpot> tempSpots = [];
    List<FlSpot> soilSpots = [];
    if (snapshot.exists && snapshot.value != null) {
      // (Your existing history parsing logic here)
      // If parsing fails, just return empty lists
      try {
        Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
        var entries = values.entries.toList();
        entries.sort((a, b) => a.value['ts'].compareTo(b.value['ts']));
        if (entries.length > 24) entries = entries.sublist(entries.length - 24);
        int index = 0;
        for (var entry in entries) {
          var data = entry.value;
          tempSpots.add(
            FlSpot(index.toDouble(), (data['t'] as num).toDouble()),
          );
          soilSpots.add(
            FlSpot(index.toDouble(), (data['s'] as num).toDouble()),
          );
          index++;
        }
      } catch (e) {
        debugPrint("Error parsing history: $e");
      }
    }
    return [tempSpots, soilSpots];
  }
}
