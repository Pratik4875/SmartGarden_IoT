import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/wifi_service.dart';

class WiFiCarScreen extends StatefulWidget {
  const WiFiCarScreen({super.key});

  @override
  State<WiFiCarScreen> createState() => _WiFiCarScreenState();
}

class _WiFiCarScreenState extends State<WiFiCarScreen> {
  final WiFiService _wifiService = WiFiService();

  String _status = "READY";
  String _lastError = "";
  Color _statusColor = Colors.white54;

  double _currentSpeed = 50.0;
  bool _lineFollowerMode = false;
  bool _isLightOn = false; // Track light status

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _executeCommand(
    String action,
    Future<String?> Function() command,
  ) async {
    setState(() {
      _status = action.toUpperCase();
      _statusColor = Colors.cyanAccent;
    });
    HapticFeedback.mediumImpact();

    String? error = await command();

    if (mounted) {
      if (error == null) {
        setState(() {
          _statusColor = Colors.greenAccent;
          _lastError = "";
        });
      } else {
        setState(() {
          _status = "ERROR";
          _statusColor = Colors.redAccent;
          _lastError = error
              .replaceAll("ClientException: ", "")
              .replaceAll("SocketException: ", "");
        });
      }
    }
  }

  // Specific handler for lights to toggle state
  void _toggleLights() {
    setState(() => _isLightOn = !_isLightOn);
    _executeCommand(
      "LIGHTS ${_isLightOn ? 'ON' : 'OFF'}",
      () => _wifiService.toggleLight(_isLightOn),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          // Grid Background
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.network(
                "https://i.imgur.com/3Z6Q1jD.png",
                repeat: ImageRepeat.repeat,
                errorBuilder: (c, o, s) => Container(),
              ),
            ),
          ),

          SafeArea(
            child: Row(
              children: [
                // === LEFT: D-PAD ===
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDpadBtn(
                        "F",
                        Icons.arrow_drop_up,
                        Colors.cyanAccent,
                        () => _executeCommand(
                          "FORWARD",
                          _wifiService.moveForward,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDpadBtn(
                            "L",
                            Icons.arrow_left,
                            Colors.cyanAccent,
                            () =>
                                _executeCommand("LEFT", _wifiService.moveLeft),
                          ),
                          const SizedBox(width: 60),
                          _buildDpadBtn(
                            "R",
                            Icons.arrow_right,
                            Colors.cyanAccent,
                            () => _executeCommand(
                              "RIGHT",
                              _wifiService.moveRight,
                            ),
                          ),
                        ],
                      ),
                      _buildDpadBtn(
                        "B",
                        Icons.arrow_drop_down,
                        Colors.cyanAccent,
                        () => _executeCommand(
                          "BACKWARD",
                          _wifiService.moveBackward,
                        ),
                      ),
                    ],
                  ),
                ),

                // === CENTER: DASHBOARD ===
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Connection Header
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          border: Border.all(
                            color: Colors.greenAccent.withValues(alpha: 0.5),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.wifi,
                              color: Colors.greenAccent,
                              size: 16,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _wifiService.currentIp,
                              style: GoogleFonts.robotoMono(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // STATUS TEXT
                      Text(
                        _status,
                        style: GoogleFonts.orbitron(
                          color: _statusColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      if (_lastError.isNotEmpty)
                        Text(
                          _lastError,
                          style: GoogleFonts.robotoMono(
                            color: Colors.redAccent,
                            fontSize: 10,
                          ),
                        ),

                      const Spacer(),

                      // AUTO PILOT TOGGLE
                      Column(
                        children: [
                          Text(
                            "AUTO-PILOT",
                            style: GoogleFonts.orbitron(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                          Switch(
                            value: _lineFollowerMode,
                            activeThumbColor: Colors.purpleAccent,
                            activeTrackColor: Colors.purpleAccent.withValues(
                              alpha: 0.3,
                            ),
                            onChanged: (val) {
                              setState(() => _lineFollowerMode = val);
                              _executeCommand(
                                "AUTO ${val ? 'ON' : 'OFF'}",
                                () => _wifiService.sendCustomCommand(
                                  val ? "X" : "x",
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // === RIGHT: CONTROLS ===
                Expanded(
                  flex: 4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // SPEED SLIDER
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "MAX",
                            style: GoogleFonts.robotoMono(
                              color: Colors.orangeAccent,
                              fontSize: 10,
                            ),
                          ),
                          Expanded(
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 15,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 12,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 20,
                                  ),
                                  activeTrackColor: Colors.orangeAccent,
                                  thumbColor: Colors.orange,
                                ),
                                child: Slider(
                                  value: _currentSpeed,
                                  min: 0,
                                  max: 100,
                                  onChanged: (v) =>
                                      setState(() => _currentSpeed = v),
                                  onChangeEnd: (v) => _executeCommand(
                                    "SPEED ${v.toInt()}",
                                    () => _wifiService.sendCustomCommand(
                                      "speed?val=${v.toInt()}",
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Text(
                            "SPD",
                            style: GoogleFonts.robotoMono(
                              color: Colors.orangeAccent,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),

                      // ACTION BUTTONS (Lights & Horn & Brake)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 1. LIGHTS BUTTON (New!)
                          _buildToggleBtn(
                            "LIGHTS",
                            _isLightOn
                                ? Icons.lightbulb
                                : Icons.lightbulb_outline,
                            _isLightOn ? Colors.yellowAccent : Colors.grey,
                            60,
                            _toggleLights,
                          ),
                          const SizedBox(height: 15),

                          // 2. HORN
                          _buildHoldBtn(
                            "HORN",
                            Icons.volume_up,
                            Colors.amber,
                            60,
                            onPress: () => _executeCommand(
                              "HORN",
                              () => _wifiService.sendCustomCommand("horn_on"),
                            ),
                            onRelease: () => _executeCommand(
                              "SILENT",
                              () => _wifiService.sendCustomCommand("horn_off"),
                            ),
                          ),
                          const SizedBox(height: 15),

                          // 3. BRAKE
                          _buildHoldBtn(
                            "BRAKE",
                            Icons.pan_tool,
                            Colors.redAccent,
                            70,
                            onPress: () =>
                                _executeCommand("STOP", _wifiService.stop),
                            onRelease: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildDpadBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onAction,
  ) {
    return GestureDetector(
      onTapDown: (_) => onAction(),
      onTapUp: (_) => _executeCommand("STOP", _wifiService.stop),
      onTapCancel: () => _executeCommand("STOP", _wifiService.stop),
      child: Container(
        width: 75,
        height: 75,
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 40),
      ),
    );
  }

  // Button for simple Toggle (Tap once on/off)
  Widget _buildToggleBtn(
    String label,
    IconData icon,
    Color color,
    double size,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          border: Border.all(color: color, width: 2),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }

  // Button for Hold Actions (Horn/Brake)
  Widget _buildHoldBtn(
    String label,
    IconData icon,
    Color color,
    double size, {
    required VoidCallback onPress,
    required VoidCallback onRelease,
  }) {
    return GestureDetector(
      onTapDown: (_) => onPress(),
      onTapUp: (_) => onRelease(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          border: Border.all(color: color, width: 2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }
}
