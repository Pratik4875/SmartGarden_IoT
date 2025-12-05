import 'dart:async';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ota_update/ota_update.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class IoTService {
  DatabaseReference? _db;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notifications = NotificationService();

  late final Future<void> ready;

  String userName = "User";
  String? _userPhotoUrl;
  bool get isConnected => _db != null;

  // Smart Monitoring Variables
  DateTime? _lastDryAlertTime;
  final int _dryThreshold = 30;
  int? _startMoisture;
  Timer? _failureCheckTimer;

  IoTService() {
    ready = _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _notifications.initialize();
      await _notifications.scheduleDailyReport();

      final prefs = await SharedPreferences.getInstance();
      userName =
          prefs.getString('user_name') ??
          _auth.currentUser?.displayName ??
          "User";
      _userPhotoUrl = _auth.currentUser?.photoURL;

      String? savedUrl = prefs.getString('firebase_url');

      if (savedUrl != null && savedUrl.isNotEmpty) {
        FirebaseDatabase instance = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: savedUrl,
        );
        _db = instance.ref();
        debugPrint("✅ IoT Service Connected to: $savedUrl");
        _startSmartMonitoring();
      } else {
        _db = null;
        debugPrint("⚠️ Guest Mode: No Database URL found.");
      }
    } catch (e) {
      debugPrint("❌ IoT Init Error: $e");
      _db = null;
    }
  }

  // --- AUTHENTICATION ---

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return null;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      debugPrint("❌ Google Sign-In Error: $e");
      return null;
    }
  }

  Future<UserCredential?> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      await userCredential.user?.updateDisplayName(name);
      userName = name;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);

      if (isConnected && _db != null) {
        await _db!.child('users/${userCredential.user!.uid}').set({
          'name': name,
          'email': email,
          'joined': ServerValue.timestamp,
        });
      }

      return userCredential;
    } catch (e) {
      debugPrint("❌ Registration Error: $e");
      rethrow;
    }
  }

  Future<UserCredential?> loginWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      userName = userCredential.user?.displayName ?? "User";
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', userName);

      return userCredential;
    } catch (e) {
      debugPrint("❌ Login Error: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().disconnect();
    } catch (e) {
      debugPrint("Google disconnect error: $e");
    }
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // --- STREAMS ---
  Stream<bool> get onlineStatusStream {
    if (!isConnected) {
      return Stream.value(false);
    }
    return _db!.child('device/ts').onValue.map((event) {
      if (event.snapshot.value == null) {
        return false;
      }
      int lastSeen = int.tryParse(event.snapshot.value.toString()) ?? 0;
      int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return (now - lastSeen).abs() < 120;
    });
  }

  Stream<DatabaseEvent> get pumpStatusStream =>
      _db?.child('control/pump').onValue ?? const Stream<DatabaseEvent>.empty();
  Stream<DatabaseEvent> get tempStream =>
      _db?.child('sensors/dht/temp').onValue ??
      const Stream<DatabaseEvent>.empty();
  Stream<DatabaseEvent> get humidityStream =>
      _db?.child('sensors/dht/humidity').onValue ??
      const Stream<DatabaseEvent>.empty();
  Stream<DatabaseEvent> get soilStream =>
      _db?.child('sensors/soil/percent').onValue ??
      const Stream<DatabaseEvent>.empty();
  Stream<DatabaseEvent> get lastWateredStream =>
      _db?.child('status/last_watered').onValue ??
      const Stream<DatabaseEvent>.empty();
  Stream<DatabaseEvent> get deviceLastSeenStream =>
      _db?.child('device/ts').onValue ?? const Stream<DatabaseEvent>.empty();
  Stream<DatabaseEvent> get schedulesStream =>
      _db?.child('config/schedules').onValue ??
      const Stream<DatabaseEvent>.empty();

  // --- ACTIONS ---
  Future<void> togglePump(bool turnOn) async {
    if (!isConnected) {
      return;
    }
    await _db!.child('control/pump').set(turnOn);
    if (turnOn) {
      await _db!.child('control/request_time').set(ServerValue.timestamp);
    }
  }

  Future<void> updateScheduleSlot(
    int index,
    bool enabled,
    DateTime localTime,
    int duration,
  ) async {
    if (!isConnected) {
      return;
    }
    DateTime utc = localTime.toUtc();
    String timeStr =
        "${utc.hour.toString().padLeft(2, '0')}:${utc.minute.toString().padLeft(2, '0')}";
    await _db!.child('config/schedules/$index').update({
      'enabled': enabled,
      'time_utc': timeStr,
      'duration_sec': duration,
    });
  }

  Future<void> deleteScheduleSlot(int index) async {
    if (!isConnected) {
      return;
    }
    await _db!.child('config/schedules/$index').set({
      'enabled': false,
      'time_utc': "00:00",
      'duration_sec': 0,
    });
  }

  Future<List<dynamic>> getSchedulesOnce() async {
    if (!isConnected) {
      return [];
    }
    final snapshot = await _db!.child('config/schedules').get();
    if (snapshot.exists && snapshot.value != null) {
      if (snapshot.value is List) {
        return snapshot.value as List;
      }
      if (snapshot.value is Map) {
        Map map = snapshot.value as Map;
        List<dynamic> list = List.filled(5, null);
        map.forEach((k, v) {
          int? idx = int.tryParse(k.toString());
          if (idx != null && idx < 5) {
            list[idx] = v;
          }
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

  // --- PROFILE ---
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

  // --- LOGIC ---
  void _startSmartMonitoring() {
    if (!isConnected) {
      return;
    }

    _db!.child('sensors/soil/percent').onValue.listen((event) {
      if (event.snapshot.value != null) {
        int moisture = int.tryParse(event.snapshot.value.toString()) ?? 0;
        _checkSoilHealth(moisture);
      }
    });

    _db!.child('control/pump').onValue.listen((event) async {
      bool isPumpOn = (event.snapshot.value == true);
      if (isPumpOn) {
        final snap = await _db!.child('sensors/soil/percent').get();
        _startMoisture = int.tryParse(snap.value.toString()) ?? 0;

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
      if (_lastDryAlertTime == null ||
          now.difference(_lastDryAlertTime!).inMinutes > 30) {
        _notifications.showNotification(
          id: 3,
          title: "⚠️ Sensor Error",
          body: "Check wiring.",
        );
        _lastDryAlertTime = now;
      }
      return;
    }
    if (moisture < _dryThreshold) {
      if (_lastDryAlertTime == null ||
          now.difference(_lastDryAlertTime!).inHours > 6) {
        _notifications.showNotification(
          id: 1,
          title: "🌱 Thirsty!",
          body: "Soil is $moisture%.",
        );
        _lastDryAlertTime = now;
      }
    }
  }

  Future<void> _checkWateringSuccess() async {
    if (_startMoisture == null) {
      return;
    }
    final snap = await _db!.child('sensors/soil/percent').get();
    int endMoisture = int.tryParse(snap.value.toString()) ?? 0;

    if (endMoisture < 95 &&
        (endMoisture - _startMoisture!) < 3 &&
        _startMoisture! < 90) {
      _notifications.showNotification(
        id: 2,
        title: "⚠️ Watering Failed",
        body: "Check pump/tank.",
      );
    }
    _startMoisture = null;
  }

  // --- HISTORY ---
  Future<List<List<FlSpot>>> getHistoryData() async {
    if (!isConnected) {
      return [[], []];
    }
    final snapshot = await _db!.child('history').get();
    List<FlSpot> tempSpots = [];
    List<FlSpot> soilSpots = [];

    if (snapshot.exists && snapshot.value != null) {
      try {
        List<dynamic> rawValues = [];
        if (snapshot.value is Map) {
          rawValues = (snapshot.value as Map).values.toList();
        } else if (snapshot.value is List) {
          rawValues = snapshot.value as List;
        }

        List<Map> cleanEntries = [];
        for (var item in rawValues) {
          if (item != null && item is Map) {
            cleanEntries.add(item);
          }
        }

        cleanEntries.sort((a, b) {
          int tsA = int.tryParse(a['ts'].toString()) ?? 0;
          int tsB = int.tryParse(b['ts'].toString()) ?? 0;
          return tsA.compareTo(tsB);
        });

        if (cleanEntries.length > 24) {
          cleanEntries = cleanEntries.sublist(cleanEntries.length - 24);
        }

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

  // --- INSIGHTS ---
  Future<Map<String, double>> getDailyInsights() async {
    if (!isConnected) {
      return {'minTemp': 0, 'maxTemp': 0, 'minSoil': 0, 'maxSoil': 0};
    }

    final snapshot = await _db!.child('history').get();

    if (snapshot.exists && snapshot.value != null) {
      try {
        List<dynamic> rawValues = [];
        if (snapshot.value is Map) {
          rawValues = (snapshot.value as Map).values.toList();
        } else if (snapshot.value is List) {
          rawValues = snapshot.value as List;
        }

        int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        int oneDayAgo = now - 86400; // 24 hours ago

        List<double> temps = [];
        List<double> soils = [];

        for (var item in rawValues) {
          if (item == null || item is! Map) {
            continue;
          }

          int ts = int.tryParse(item['ts'].toString()) ?? 0;

          if (ts > oneDayAgo) {
            double t = double.tryParse(item['t'].toString()) ?? 0;
            double s = double.tryParse(item['s'].toString()) ?? 0;
            if (t > 0) {
              temps.add(t);
            }
            if (s > 0) {
              soils.add(s);
            }
          }
        }

        if (temps.isEmpty) {
          return {'minTemp': 0, 'maxTemp': 0, 'minSoil': 0, 'maxSoil': 0};
        }

        return {
          'minTemp': temps.reduce(min),
          'maxTemp': temps.reduce(max),
          'minSoil': soils.reduce(min),
          'maxSoil': soils.reduce(max),
        };
      } catch (e) {
        debugPrint("Insights Calculation Error: $e");
      }
    }
    return {'minTemp': 0, 'maxTemp': 0, 'minSoil': 0, 'maxSoil': 0};
  }
}
