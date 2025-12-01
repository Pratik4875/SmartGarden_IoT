import 'package:firebase_database/firebase_database.dart';

class IoTService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Streams for Real-time Data
  Stream<DatabaseEvent> get pumpStatusStream =>
      _db.child('control/pump').onValue;
  Stream<DatabaseEvent> get tempStream => _db.child('sensors/dht/temp').onValue;
  Stream<DatabaseEvent> get humidityStream =>
      _db.child('sensors/dht/humidity').onValue;
  Stream<DatabaseEvent> get soilStream =>
      _db.child('sensors/soil/percent').onValue;
  Stream<DatabaseEvent> get lastWateredStream =>
      _db.child('status/last_watered').onValue;

  // Actions
  Future<void> togglePump(bool turnOn) async {
    await _db.child('control/pump').set(turnOn);
    // Optional: Log the request time
    if (turnOn) {
      await _db.child('control/request_time').set(ServerValue.timestamp);
    }
  }

  Future<void> setManualMode(bool enabled) async {
    await _db.child('control/manual_mode').set(enabled);
  }
}
