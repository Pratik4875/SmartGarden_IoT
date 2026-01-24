import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ota_update/ota_update.dart';

import 'notification_service.dart';
import 'iot_auth.dart';
import 'iot_control_and_data.dart';

class IoTService implements AuthClient, ControlDataClient {
  // --- FIELDS ---
  String? _cloudLink;
  bool _isFirebase = false;
  MqttServerClient? mqtt;

  // 🚀 SPEED FIX: Keep one client open to reuse SSL connections
  final http.Client _fastClient = http.Client();

  Timer? _pollingTimer;

  // Stream Controllers
  final StreamController<DatabaseEvent> _genericStreamCtrl =
      StreamController.broadcast();
  final StreamController<DatabaseEvent> _soilCtrl =
      StreamController.broadcast();
  final StreamController<DatabaseEvent> _pumpCtrl =
      StreamController.broadcast();
  final StreamController<DatabaseEvent> _tempCtrl =
      StreamController.broadcast();
  final StreamController<DatabaseEvent> _humidCtrl =
      StreamController.broadcast();
  final StreamController<DatabaseEvent> _heartbeatCtrl =
      StreamController.broadcast();
  final StreamController<DatabaseEvent> _lastWateredCtrl =
      StreamController.broadcast();
  final StreamController<DatabaseEvent> _scheduleCtrl =
      StreamController.broadcast();

  @override
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  @override
  final NotificationService notifications = NotificationService();

  @override
  DatabaseReference? db;

  late final IoTAuth auth;
  late final IoTControlAndData controlAndData;
  late final Future<void> ready;

  @override
  String userName = "User";
  String? _userPhotoUrl;

  @override
  bool get isConnected => _cloudLink != null && _cloudLink!.isNotEmpty;

  IoTService() {
    auth = IoTAuth(this);
    controlAndData = IoTControlAndData(this);
    ready = _initialize();
  }

  Future<void> _initialize() async {
    try {
      await notifications.initialize();
      final prefs = await SharedPreferences.getInstance();
      userName = prefs.getString('user_name') ?? "User";
      _userPhotoUrl = prefs.getString('user_photo');

      _cloudLink = prefs.getString('firebase_url');

      if (_cloudLink != null && _cloudLink!.isNotEmpty) {
        if (_cloudLink!.startsWith("http")) {
          _isFirebase = true;
          debugPrint("✅ Mode: FIREBASE HTTP (TURBO)");
          _startPolling();
        } else {
          _isFirebase = false;
          debugPrint("✅ Mode: MQTT ($_cloudLink)");
          await _connectMqtt();
        }
      } else {
        debugPrint("⚠️ Guest Mode: No Link Found");
      }
    } catch (e) {
      debugPrint("❌ Init Error: $e");
    }
  }

  // ======================================================
  // 🚀 UNIVERSAL HTTP SENDER (OPTIMIZED)
  // ======================================================
  Future<void> setGenericData(String path, dynamic value) async {
    if (_isFirebase && _cloudLink != null) {
      String cleanUrl = _cloudLink!.endsWith('/')
          ? _cloudLink!.substring(0, _cloudLink!.length - 1)
          : _cloudLink!;

      final url = Uri.parse("$cleanUrl/$path.json");

      try {
        await _fastClient.put(url, body: json.encode(value));
      } catch (e) {
        debugPrint("❌ HTTP Error: $e");
      }
    } else if (mqtt != null && !_isFirebase) {
      if (mqtt!.connectionStatus?.state != MqttConnectionState.connected) {
        await _connectMqtt();
      }
      String fullTopic = "$_cloudLink/$path";
      final builder = MqttClientPayloadBuilder();
      builder.addString(value.toString());
      try {
        mqtt!.publishMessage(fullTopic, MqttQos.atMostOnce, builder.payload!);
      } catch (e) {
        debugPrint("❌ MQTT TX Error: $e");
      }
    }
  }

  // --- COMMANDS ---
  Future<void> moveCar(String command) async =>
      await setGenericData('car/cmd', command);

  Future<void> toggleLed(bool turnOn) async =>
      await setGenericData('led/status', turnOn);

  // 🆕 ADDED: Speed Control Function
  Future<void> setCarSpeed(int speed) async {
    // Clamping just in case, though slider handles it
    int safeSpeed = speed.clamp(0, 100);
    await setGenericData('car/speed', safeSpeed);
  }

  // ======================================================
  // 👂 POLLING LISTENER
  // ======================================================

  Stream<DatabaseEvent> listenGenericData(String path) {
    return _genericStreamCtrl.stream;
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_isFirebase && _cloudLink != null) {
        await _fetchAndEmit('status/sensors/mapped', _soilCtrl); // FIXED PATH
        await _fetchAndEmit('control/pump', _pumpCtrl);
        await _fetchAndEmit('sensors/dht/temp', _tempCtrl);
        await _fetchAndEmit('sensors/dht/humidity', _humidCtrl);
        await _fetchAndEmit('sensors/dht/humidity', _humidCtrl);
        await _fetchAndEmit('led/status', _genericStreamCtrl);
        await _fetchAndEmit('device/status', _heartbeatCtrl); // NEW
        await _fetchAndEmit('status/last_watered', _lastWateredCtrl); // NEW
        await _fetchAndEmit('config/scheduler/slots', _scheduleCtrl); // NEW
      }
    });
  }

  Future<void> _fetchAndEmit(
    String path,
    StreamController<DatabaseEvent> ctrl,
  ) async {
    try {
      String cleanUrl = _cloudLink!.endsWith('/')
          ? _cloudLink!.substring(0, _cloudLink!.length - 1)
          : _cloudLink!;
      final url = Uri.parse("$cleanUrl/$path.json");

      final response = await _fastClient.get(url);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        ctrl.add(MockDatabaseEvent(decoded));
      }
    } catch (e) {
      // Silent error during polling
    }
  }

  Future<void> _connectMqtt() async {
    mqtt = MqttServerClient(
      'broker.hivemq.com',
      'flutter_stu_${DateTime.now().millisecondsSinceEpoch}',
    );
    mqtt!.port = 1883;
    mqtt!.logging(on: false);
    mqtt!.keepAlivePeriod = 20;
    mqtt!.autoReconnect = true;

    try {
      await mqtt!.connect();
    } catch (e) {
      debugPrint("❌ MQTT Error: $e");
      mqtt!.disconnect();
    }
  }

  // --- IMPLEMENTATION FIXES ---
  @override
  DateTime? lastDryAlertTime;
  @override
  int? startMoisture;
  @override
  void updateLastDryAlertTime(DateTime? t) => lastDryAlertTime = t;
  @override
  void setStartMoisture(int? m) => startMoisture = m;
  @override
  void updateUserName(String n) => userName = n;

  @override
  Stream<DatabaseEvent> get soilStream => _soilCtrl.stream;

  Stream<DatabaseEvent> get pumpStatusStream => _pumpCtrl.stream;
  Stream<DatabaseEvent> get tempStream => _tempCtrl.stream;
  Stream<DatabaseEvent> get humidityStream => _humidCtrl.stream;
  Stream<bool> get onlineStatusStream => Stream.value(isConnected);

  Stream<DatabaseEvent> get requestTimeStream => _heartbeatCtrl.stream; // Reusing for heartbeat
  Stream<DatabaseEvent> get lastWateredStream => _lastWateredCtrl.stream;
  Stream<DatabaseEvent> get schedulesStream => _scheduleCtrl.stream;

  static Future<UserCredential?> signInWithGoogle() =>
      IoTAuth.signInWithGoogle();
  Future<UserCredential?> registerWithEmail(String e, String p, String n) =>
      auth.registerWithEmail(e, p, n);
  Future<UserCredential?> loginWithEmail(String e, String p) =>
      auth.loginWithEmail(e, p);
  Future<void> signOut() => auth.signOut();

  Future<void> togglePump(bool on) async {
    await setGenericData('control/pump', on);
  }

  Future<void> updateScheduleSlot(int i, bool e, String time, int d) async {
      // time format: "HH:mm"
      // We are using a List of strings for simplicity in Arduino
      // Fetch current list first
      // For now, we just overwrite the slot or add to list.
      // To strictly follow "Max 5", "No Duplicates", we handle that in UI and just save the list here.
      // Actually, let's just use a simpler method: saveScheduleList
  }
  
  Future<void> saveScheduleList(List<String> times) async {
      await setGenericData('config/scheduler/slots', times);
  }

  Future<void> deleteScheduleSlot(int i) async {} // Handled by saving new list
  Future<List<dynamic>> getSchedulesOnce() async {
     // This is just a helper if we want one-time fetch, but we have stream now.
     return [];
  }
  @override 
  Stream<OtaEvent> updateApp() => const Stream.empty();
  @override 
  Future<String> forceStatusRefresh() async {
     // Re-trigger polling instantly
     await _fetchAndEmit('status/sensors/mapped', _soilCtrl);
     await _fetchAndEmit('control/pump', _pumpCtrl);
     await _fetchAndEmit('device/status', _heartbeatCtrl); 
     return "Status Refreshed";
  }

  // --- ANALYSIS IMPLEMENTATION ---
  
  @override 
  Future<List<List<FlSpot>>> getHistoryData() async {
    if (_cloudLink == null || !_isFirebase) return [[], []];

    String cleanUrl = _cloudLink!.endsWith('/')
        ? _cloudLink!.substring(0, _cloudLink!.length - 1)
        : _cloudLink!;
    
    // Fetch last 50 entries to cover ~12 hours (15m * 4) given reasonable spacing
    final url = Uri.parse("$cleanUrl/history/log.json?orderBy=\"\$key\"&limitToLast=50");
    
    List<FlSpot> soilSports = [];
    List<FlSpot> pumpSpots = []; // Using this for "pump" analysis if needed, or temp?
    // Wait... HistoryScreen expects [TempPoints, SoilPoints]. 
    // Our Arduino logs: "m": moisture, "p": pump. No Temp logged in history yet.
    // Let's map Pump to "Temp" graph for now to show ON/OFF history? 
    // Or just return empty for Temp. 
    // Better: Arduino "m" -> Soil. 
    // Temp -> Let's check if we can reuse it for something useful. 
    // The user asked for "Soil Moisture History" and "Last Pump Activation".
    // Let's just return Soil Points for now.

    try {
      final response = await _fastClient.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        int index = 0;
        
        // Firebase returns map with keys. Must sort by key (timestamp)
        var sortedKeys = data.keys.toList()..sort();
        
        for (var key in sortedKeys) {
           var entry = data[key]; // {"t": 123, "m": 45, "p": 0}
           if (entry is Map) {
              double m = double.tryParse(entry['m'].toString()) ?? 0;
              // double p = double.tryParse(entry['p'].toString()) ?? 0;
              
              soilSports.add(FlSpot(index.toDouble(), m));
              index++;
           }
        }
      }
    } catch (e) {
      debugPrint("❌ History Error: $e");
    }

    return [[], soilSports]; // [Temp(Empty), Soil]
  }

  @override 
  Future<Map<String, double>> getDailyInsights() async {
    // We can reuse getHistoryData logic or fetch again.
    // For simplicity, let's fetch strictly last 24h?
    // 24h * 4 entries/hr = 96 entries.
    // Limit to 100.
    
    if (_cloudLink == null || !_isFirebase) return {};
    
    String cleanUrl = _cloudLink!.endsWith('/')
        ? _cloudLink!.substring(0, _cloudLink!.length - 1)
        : _cloudLink!;
        
    final url = Uri.parse("$cleanUrl/history/log.json?orderBy=\"\$key\"&limitToLast=96");
    
    double minMoist = 100;
    double maxMoist = 0;
    bool found = false;

    try {
      final response = await _fastClient.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        for (var entry in data.values) {
           if (entry is Map) {
              double m = double.tryParse(entry['m'].toString()) ?? 0;
              if (m < minMoist) minMoist = m;
              if (m > maxMoist) maxMoist = m;
              found = true;
           }
        }
      }
    } catch (e) {
       // Error
    }
    
    // InsightsCard expects "minTemp" and "maxTemp" keys. 
    // We will repurpose them to send Moisture Min/Max.
    // User sees "Night Low" / "Day Peak" -> Works for moisture too (Low moisture = dry).
    
    if (!found) return {};
    
    return {
      "minTemp": minMoist, 
      "maxTemp": maxMoist 
    };
  }

  Future<void> updateProfileName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    userName = name;
  }

  Future<void> updateProfilePhoto(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_photo', url);
    _userPhotoUrl = url;
  }

  String? get photoUrl => _userPhotoUrl;

  void dispose() {
    _pollingTimer?.cancel();
    _genericStreamCtrl.close();
    _soilCtrl.close();
    _pumpCtrl.close();
    _tempCtrl.close();
    _humidCtrl.close();
    _heartbeatCtrl.close();
    _lastWateredCtrl.close();
    _scheduleCtrl.close();
    _fastClient.close();
    mqtt?.disconnect();
  }
}

// --- MOCK CLASSES ---
class MockDatabaseEvent implements DatabaseEvent {
  final dynamic _val;
  MockDatabaseEvent(this._val);
  @override
  DataSnapshot get snapshot => MockDataSnapshot(_val);
  @override
  DatabaseEventType get type => DatabaseEventType.value;
  @override
  String? get previousChildKey => null;
}

class MockDataSnapshot implements DataSnapshot {
  final dynamic _val;
  MockDataSnapshot(this._val);
  @override
  bool get exists => _val != null;
  @override
  dynamic get value => _val;
  @override
  String? get key => "mock";
  @override
  Iterable<DataSnapshot> get children => [];
  @override
  DataSnapshot child(String path) => this;
  @override
  bool hasChild(String path) => false;

  int get childrenCount => 0;
  @override
  dynamic get priority => null;
  @override
  DatabaseReference get ref =>
      throw UnimplementedError("Mock ref not supported");

  Iterator<DataSnapshot> get iterator => <DataSnapshot>[].iterator;
}
