import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http; // Required for the ping check

// 1. Import your Service
import '../services/wifi_service.dart';

// 2. Import your Screens
import 'wifi_car_screen.dart';
import 'wifi_led_screen.dart';
import 'wifi_terminal_screen.dart';

class WiFiHubScreen extends StatefulWidget {
  const WiFiHubScreen({super.key});

  @override
  State<WiFiHubScreen> createState() => _WiFiHubScreenState();
}

class _WiFiHubScreenState extends State<WiFiHubScreen>
    with WidgetsBindingObserver {
  // Default IP for ESP8266 in AP Mode
  final TextEditingController _ipController = TextEditingController(
    text: "192.168.4.1",
  );

  bool _isConnected = false;
  bool _isChecking = false;
  String _statusText = "Waiting for connection...";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start the auto-check loop
    _startHeartbeat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _ipController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Immediately check when user returns to app (e.g. from WiFi settings)
      _checkConnection();
    }
  }

  void _startHeartbeat() {
    // Check every 3 seconds automatically
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isChecking) _checkConnection();
    });
    // Also run one check immediately
    _checkConnection();
  }

  // --- CONNECTION LOGIC ---
  Future<void> _checkConnection() async {
    if (_isChecking) return;
    if (!mounted) return;

    setState(() => _isChecking = true);

    // 1. Get IP from text field
    String currentIp = _ipController.text.trim();
    if (currentIp.isEmpty) {
      setState(() => _isChecking = false);
      return;
    }

    // 2. Update the Global Service
    WiFiService().setTargetIp(currentIp);

    // 3. Ping the device to see if it's alive
    bool isAlive = false;
    try {
      final url = Uri.parse("http://$currentIp/");
      // Short timeout (1.5s) to avoid UI freezing
      await http.get(url).timeout(const Duration(milliseconds: 1500));
      isAlive = true;
    } catch (e) {
      isAlive = false;
    }

    if (mounted) {
      setState(() {
        // FIX: Now we actually use the result!
        _isConnected = isAlive;

        _statusText = isAlive
            ? "Connected to $currentIp"
            : "No response from $currentIp";

        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: Text(
          "WiFi Connection Hub",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.cyanAccent),
            onPressed: _checkConnection, // Manual Retry
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // --- INSTRUCTION CARD ---
            Container(
              padding: const EdgeInsets.all(15),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orangeAccent),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      "Tip: Connect to 'SmartCar' WiFi & Turn OFF Mobile Data.",
                      style: GoogleFonts.roboto(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- IP INPUT ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi, color: Colors.grey),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextField(
                      controller: _ipController,
                      style: GoogleFonts.robotoMono(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        labelText: "Target IP Address",
                        labelStyle: TextStyle(color: Colors.grey),
                      ),
                      keyboardType: TextInputType.number,
                      onSubmitted: (_) => _checkConnection(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // --- STATUS INDICATOR ---
            GestureDetector(
              onTap: _checkConnection,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isConnected
                      ? Colors.greenAccent.withValues(alpha: 0.1)
                      : Colors.redAccent.withValues(alpha: 0.1),
                  border: Border.all(
                    color: _isConnected ? Colors.greenAccent : Colors.redAccent,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isConnected
                          ? Colors.greenAccent.withValues(alpha: 0.2)
                          : Colors.redAccent.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isConnected ? Icons.link : Icons.link_off,
                      size: 50,
                      color: _isConnected
                          ? Colors.greenAccent
                          : Colors.redAccent,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isConnected ? "ONLINE" : "OFFLINE",
                      style: GoogleFonts.orbitron(
                        color: _isConnected
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            Text(
              _statusText,
              style: GoogleFonts.robotoMono(color: Colors.white54),
            ),

            const SizedBox(height: 50),

            // --- MENU BUTTONS ---
            // These buttons force the IP update before pushing the screen
            Opacity(
              opacity: _isConnected
                  ? 1.0
                  : 0.7, // Dim if offline, but still clickable
              child: Column(
                children: [
                  _buildNavButton(
                    context,
                    label: "START ENGINE",
                    icon: Icons.gamepad,
                    color: Colors.cyanAccent,
                    onTap: () {
                      // CRITICAL: Update IP before going to the Car Screen
                      WiFiService().setTargetIp(_ipController.text);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WiFiCarScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNavButton(
                          context,
                          label: "LIGHTS",
                          icon: Icons.lightbulb,
                          color: Colors.yellowAccent,
                          onTap: () {
                            WiFiService().setTargetIp(_ipController.text);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    WiFiLedScreen(deviceIp: _ipController.text),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildNavButton(
                          context,
                          label: "TERMINAL",
                          icon: Icons.terminal,
                          color: Colors.purpleAccent,
                          onTap: () {
                            WiFiService().setTargetIp(_ipController.text);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WiFiTerminalScreen(
                                  deviceIp: _ipController.text,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 15),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
