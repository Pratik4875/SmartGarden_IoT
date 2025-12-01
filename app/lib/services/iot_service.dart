import 'package:firebase_database/firebase_database.dart';
import 'package:ota_update/ota_update.dart'; // Add this import

class IoTService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Streams
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

  // Actions
  Future<void> togglePump(bool turnOn) async {
    await _db.child('control/pump').set(turnOn);
    if (turnOn) {
      await _db.child('control/request_time').set(ServerValue.timestamp);
    }
  }

  Future<void> setSchedule(bool enabled, DateTime? localTime) async {
    Map<String, Object> updates = {};
    updates['config/scheduler/enabled'] = enabled;

    if (localTime != null) {
      DateTime utcTime = localTime.toUtc();
      String hour = utcTime.hour.toString().padLeft(2, '0');
      String minute = utcTime.minute.toString().padLeft(2, '0');
      updates['config/scheduler/time_utc'] = "$hour:$minute";
    }
    await _db.update(updates);
  }

  // --- AUTO UPDATE LOGIC ---
  // Call this function when you want to update the app
  Stream<OtaEvent> updateApp() {
    try {
      // LINK TO YOUR GITHUB RELEASE APK
      // ALWAYS name the file 'app-release.apk' in your releases
      return OtaUpdate().execute(
        'https://github.com/Pratik4875/SmartGarden_IoT/releases/latest/download/app-release.apk',
        destinationFilename: 'app-release.apk',
      );
    } catch (e) {
      print('Failed to make OTA update. Details: $e');
      rethrow;
    }
  }
}
