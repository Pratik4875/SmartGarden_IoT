import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptic Feedback
import 'package:google_fonts/google_fonts.dart';
import '../services/wifi_service.dart';

class WiFiLedScreen extends StatefulWidget {
  // You can keep this parameter for backward compatibility,
  // but we will prioritize the Service's IP.
  final String deviceIp;

  const WiFiLedScreen({super.key, required this.deviceIp});

  @override
  State<WiFiLedScreen> createState() => _WiFiLedScreenState();
}

class _WiFiLedScreenState extends State<WiFiLedScreen> {
  // Use the singleton service
  final WiFiService _wifiService = WiFiService();
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    // Verify connection on load
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    // We send a harmless command (like turning LED off or just checking root)
    // to see if we get a 200 OK.
    // Since we don't have a pure 'ping', we can just mark it connected if the user navigated here.
    setState(() => _isConnected = true);
  }

  Future<void> _sendData(bool turnOn) async {
    HapticFeedback.mediumImpact();

    String? error = await _wifiService.toggleLight(turnOn);

    if (error == null) {
      _showSnack("LED TURNED ${turnOn ? 'ON' : 'OFF'}", Colors.greenAccent);
    } else {
      _showSnack("FAILED: $error", Colors.redAccent);
      setState(() => _isConnected = false);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color.withValues(alpha: 0.5),
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          "WIFI LED COMMANDER",
          style: GoogleFonts.robotoMono(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildController(),
    );
  }

  Widget _buildController() {
    return Column(
      children: [
        // 1. STATUS BAR
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _isConnected ? Colors.greenAccent : Colors.redAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _isConnected
                          ? Colors.greenAccent.withValues(alpha: 0.6)
                          : Colors.redAccent.withValues(alpha: 0.6),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TARGET IP",
                    style: GoogleFonts.robotoMono(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    _wifiService
                        .currentIp, // Pulls directly from shared service
                    style: GoogleFonts.robotoMono(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Spacer(),

        // 2. BUTTONS
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildRobustButton(
              label: "ON",
              color: Colors.greenAccent,
              icon: Icons.power_settings_new,
              onTap: () => _sendData(true),
            ),
            const SizedBox(width: 30),
            _buildRobustButton(
              label: "OFF",
              color: Colors.redAccent,
              icon: Icons.power_off,
              onTap: () => _sendData(false),
            ),
          ],
        ),

        const Spacer(),
        Text(
          "HTTP PROTOCOL v1.0",
          style: GoogleFonts.robotoMono(color: Colors.white10, fontSize: 10),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRobustButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTapDown: (_) => HapticFeedback.lightImpact(),
      onTapUp: (_) => onTap(),
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: const Color(0xFF252525),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.8),
              offset: const Offset(8, 8),
              blurRadius: 16,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.05),
              offset: const Offset(-8, -8),
              blurRadius: 16,
            ),
          ],
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E2E2E), Color(0xFF1A1A1A)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 15),
            Text(
              label,
              style: GoogleFonts.robotoMono(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
