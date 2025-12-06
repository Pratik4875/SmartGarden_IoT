import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ota_update/ota_update.dart';

import 'notification_service.dart';
import 'iot_auth.dart';
import 'iot_control_and_data.dart';

// IMPLEMENTS BOTH CLIENT INTERFACES
class IoTService implements AuthClient, ControlDataClient {
  // --- PUBLIC FIELDS (Required for split files to work) ---
  @override
  DatabaseReference? db;

  @override
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  @override
  final NotificationService notifications = NotificationService();

  late final IoTAuth auth;
  late final IoTControlAndData controlAndData;

  late final Future<void> ready;

  // --- PUBLIC STATE ---
  @override
  String userName = "User";
  String? _userPhotoUrl;
  @override
  bool get isConnected => db != null;

  // --- MONITORING STATE ---
  DateTime? _lastDryAlertTime;
  int? _startMoisture;

  @override
  DateTime? get lastDryAlertTime => _lastDryAlertTime;
  @override
  int? get startMoisture => _startMoisture;

  // Constructor
  IoTService() {
    auth = IoTAuth(this);
    controlAndData = IoTControlAndData(this);
    ready = _initialize();
  }

  // --- CLIENT IMPLEMENTATION ---
  @override
  void updateLastDryAlertTime(DateTime? time) {
    _lastDryAlertTime = time;
  }

  @override
  void setStartMoisture(int? moisture) {
    _startMoisture = moisture;
  }

  @override
  void updateUserName(String name) {
    userName = name;
  }

  Future<void> _initialize() async {
    try {
      await notifications.initialize();
      await notifications.scheduleDailyReport();

      final prefs = await SharedPreferences.getInstance();
      userName =
          prefs.getString('user_name') ??
          firebaseAuth.currentUser?.displayName ??
          "User";
      _userPhotoUrl = firebaseAuth.currentUser?.photoURL;

      String? savedUrl = prefs.getString('firebase_url');

      if (savedUrl != null && savedUrl.isNotEmpty) {
        FirebaseDatabase instance = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: savedUrl,
        );
        db = instance.ref();
        debugPrint("✅ IoT Service Connected to: $savedUrl");
        controlAndData.startSmartMonitoring();
      } else {
        db = null;
        debugPrint("⚠️ Guest Mode: No Database URL found.");
      }
    } catch (e) {
      debugPrint("❌ IoT Init Error: $e");
      db = null;
    }
  }

  // --- STREAMS ---
  @override
  Stream<DatabaseEvent> get soilStream =>
      db?.child('sensors/soil/percent').onValue ??
      const Stream<DatabaseEvent>.empty();

  Stream<bool> get onlineStatusStream {
    if (!isConnected) {
      return Stream.value(false);
    }
    return db!.child('device/ts').onValue.map((event) {
      if (event.snapshot.value == null) {
        return false;
      }
      int lastSeen = int.tryParse(event.snapshot.value.toString()) ?? 0;
      int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return (now - lastSeen).abs() < 120;
    });
  }

  // Delegated Streams
  Stream<DatabaseEvent> get pumpStatusStream => controlAndData.pumpStatusStream;
  Stream<DatabaseEvent> get requestTimeStream =>
      controlAndData.requestTimeStream;
  Stream<DatabaseEvent> get tempStream => controlAndData.tempStream;
  Stream<DatabaseEvent> get humidityStream => controlAndData.humidityStream;
  Stream<DatabaseEvent> get lastWateredStream =>
      controlAndData.lastWateredStream;
  Stream<DatabaseEvent> get schedulesStream => controlAndData.schedulesStream;

  // --- PUBLIC INTERFACE (Delegated) ---

  // Auth
  static Future<UserCredential?> signInWithGoogle() =>
      IoTAuth.signInWithGoogle();
  Future<UserCredential?> registerWithEmail(
    String email,
    String password,
    String name,
  ) => auth.registerWithEmail(email, password, name);
  Future<UserCredential?> loginWithEmail(String email, String password) =>
      auth.loginWithEmail(email, password);
  Future<void> signOut() => auth.signOut();

  // Control
  Future<void> togglePump(bool turnOn) => controlAndData.togglePump(turnOn);
  Future<void> updateScheduleSlot(
    int index,
    bool enabled,
    DateTime localTime,
    int duration,
  ) => controlAndData.updateScheduleSlot(index, enabled, localTime, duration);
  Future<void> deleteScheduleSlot(int index) =>
      controlAndData.deleteScheduleSlot(index);
  Future<List<dynamic>> getSchedulesOnce() => controlAndData.getSchedulesOnce();
  Stream<OtaEvent> updateApp() => controlAndData.updateApp();

  // Data
  Future<String> forceStatusRefresh() => controlAndData.forceStatusRefresh();
  Future<List<List<FlSpot>>> getHistoryData() =>
      controlAndData.getHistoryData();
  Future<Map<String, double>> getDailyInsights() =>
      controlAndData.getDailyInsights();

  // Profile
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
}
