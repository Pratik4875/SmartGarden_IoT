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
        await _fetchAndEmit('sensors/soil/percent', _soilCtrl);
        await _fetchAndEmit('control/pump', _pumpCtrl);
        await _fetchAndEmit('sensors/dht/temp', _tempCtrl);
        await _fetchAndEmit('sensors/dht/humidity', _humidCtrl);
        await _fetchAndEmit('led/status', _genericStreamCtrl);
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

  Stream<DatabaseEvent> get requestTimeStream => const Stream.empty();
  Stream<DatabaseEvent> get lastWateredStream => const Stream.empty();
  Stream<DatabaseEvent> get schedulesStream => const Stream.empty();

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

  Future<void> updateScheduleSlot(int i, bool e, DateTime t, int d) async {}
  Future<void> deleteScheduleSlot(int i) async {}
  Future<List<dynamic>> getSchedulesOnce() async => [];
  Stream<OtaEvent> updateApp() => const Stream.empty();
  Future<String> forceStatusRefresh() async => "OK";
  Future<List<List<FlSpot>>> getHistoryData() async => [];
  Future<Map<String, double>> getDailyInsights() async => {};

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
