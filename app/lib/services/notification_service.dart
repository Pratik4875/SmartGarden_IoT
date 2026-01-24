import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart'; // For Colors
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // REQUIRED for scheduling
    tz.initializeTimeZones();

    // 1. Android Settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 2. iOS Settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestAlertPermission: false,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    // 3. Request Permission
    await _requestPermission();
  }

  Future<void> _requestPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  // --- SHOW INSTANT NOTIFICATION ---
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'ecosync_alerts', // Channel ID
          'EcoSync Alerts', // Channel Name
          channelDescription:
              'Notifications for plant health and system status',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFF00E676),
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _notificationsPlugin.show(id, title, body, details);
    } catch (e) {
      debugPrint("Error showing notification: $e");
    }
  }

  // --- SCHEDULE DAILY NOTIFICATION ---
  Future<void> scheduleDailyReport() async {
    try {
      await _notificationsPlugin.zonedSchedule(
        100, // Unique ID
        '🌙 Evening Garden Report',
        'Check your daily insights: Highs, Lows, and Watering status.',
        _nextInstanceOfTime(19, 30), // 7:30 PM
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'ecosync_daily',
            'Daily Summary',
            channelDescription: 'Daily evening reports',
            importance: Importance.high,
            color: Color(0xFF00E676),
          ),
        ),
        // FIX: Use 'inexact' to avoid crashing on Android 12+ without special permissions
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint("✅ Daily Report Scheduled for 7:30 PM");
    } catch (e) {
      debugPrint("❌ Error scheduling notification: $e");
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
