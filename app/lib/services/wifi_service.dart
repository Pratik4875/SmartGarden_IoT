import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter/foundation.dart';

class WiFiService {
  // Singleton Pattern
  static final WiFiService _instance = WiFiService._internal();
  factory WiFiService() => _instance;
  WiFiService._internal();

  String _targetIp = "192.168.4.1";

  void setTargetIp(String ip) {
    // If the user typed a space by accident, trim it.
    _targetIp = ip.trim();
  }

  String get currentIp => _targetIp;

  // --- CORE HTTP HELPER (THE FIX) ---
  Future<String?> _sendRequest(String endpoint) async {
    final url = Uri.parse("http://$_targetIp/$endpoint");
    try {
      debugPrint("Sending: $url");

      // FIX: We send a header to close the connection immediately.
      // This prevents the ESP8266 from getting "stuck" on an old connection.
      final response = await http
          .get(
            url,
            headers: {'Connection': 'close'}, // <--- THE MAGIC LINE
          )
          .timeout(
            const Duration(milliseconds: 800),
          ); // Shorter timeout for gaming

      if (response.statusCode == 200) {
        return null; // Success (No error message)
      } else {
        return "Server Error: ${response.statusCode}";
      }
    } catch (e) {
      return "Conn Error: Check WiFi";
    }
  }

  // --- CONTROLS ---
  // Ensure these endpoints MATCH your Arduino code exactly!
  // If your Arduino expects "/move?dir=F", change these lines.

  Future<String?> moveForward() async => await _sendRequest("forward");
  Future<String?> moveBackward() async => await _sendRequest("backward");
  Future<String?> moveLeft() async => await _sendRequest("left");
  Future<String?> moveRight() async => await _sendRequest("right");
  Future<String?> stop() async => await _sendRequest("stop");

  Future<String?> sendCustomCommand(String cmd) async =>
      await _sendRequest(cmd);

  // --- LED SPECIFIC ---
  // If your LED works with specific URLs, ensure this matches:
  Future<String?> toggleLight(bool turnOn) async {
    // Matches the format: http://192.168.4.1/led_on
    return await _sendRequest(turnOn ? "led_on" : "led_off");
  }
}
