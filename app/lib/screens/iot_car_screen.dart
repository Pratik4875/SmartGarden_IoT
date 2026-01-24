import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/iot_service.dart';

class IoTCarScreen extends StatefulWidget {
  final IoTService iotService;
  const IoTCarScreen({super.key, required this.iotService});

  @override
  State<IoTCarScreen> createState() => _IoTCarScreenState();
}

class _IoTCarScreenState extends State<IoTCarScreen> {
  // 🆕 STATE: Default speed
  double _currentSpeed = 100.0;

  @override
  void initState() {
    super.initState();
    // Force Landscape for Gaming Mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore Portrait
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _sendCommand(String cmd) {
    HapticFeedback.heavyImpact();
    widget.iotService.moveCar(cmd);
  }

  void _updateSpeed(double val) {
    setState(() {
      _currentSpeed = val;
    });
    // Send to IoT Service
    widget.iotService.setCarSpeed(val.toInt());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          // Cyberpunk Grid Background
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.cyanAccent, Colors.purpleAccent],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Row(
              children: [
                // === LEFT SIDE: D-PAD ===
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDpadBtn(
                        "F",
                        Icons.arrow_drop_up,
                        Colors.cyanAccent,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDpadBtn(
                            "L",
                            Icons.arrow_left,
                            Colors.cyanAccent,
                          ),
                          const SizedBox(width: 60),
                          _buildDpadBtn(
                            "R",
                            Icons.arrow_right,
                            Colors.cyanAccent,
                          ),
                        ],
                      ),
                      _buildDpadBtn(
                        "B",
                        Icons.arrow_drop_down,
                        Colors.cyanAccent,
                      ),
                    ],
                  ),
                ),

                // === CENTER: DASHBOARD ===
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      // Top Status Bar
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          // FIX: withValues for Flutter 3.27+
                          border: Border.all(
                            color: Colors.greenAccent.withValues(alpha: 0.5),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cloud_done,
                              color: Colors.greenAccent,
                              size: 16,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "CLOUD UPLINK ACTIVE",
                              style: GoogleFonts.robotoMono(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Center Icon
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white10, width: 2),
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                        child: const Icon(
                          Icons.directions_car,
                          color: Colors.white24,
                          size: 30,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 🆕 SPEED SLIDER SECTION
                      Column(
                        children: [
                          Text(
                            "THROTTLE: ${_currentSpeed.toInt()}%",
                            style: GoogleFonts.robotoMono(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(
                            height: 40,
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Colors.cyanAccent,
                                inactiveTrackColor: Colors.white24,
                                thumbColor: Colors.cyanAccent,
                                overlayColor: Colors.cyanAccent.withValues(
                                  alpha: 0.2,
                                ),
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 8,
                                ),
                              ),
                              child: Slider(
                                value: _currentSpeed,
                                min: 0,
                                max: 100,
                                onChanged: (val) {
                                  _updateSpeed(val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Exit Button
                      IconButton(
                        icon: const Icon(
                          Icons.power_settings_new,
                          color: Colors.red,
                        ),
                        tooltip: "Exit",
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // === RIGHT SIDE: ACTION BUTTONS ===
                Expanded(
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // LIGHTS TOGGLE
                      StreamBuilder<DatabaseEvent>(
                        stream: widget.iotService.listenGenericData(
                          'led/status',
                        ),
                        builder: (context, snapshot) {
                          bool isOn = false;
                          if (snapshot.hasData &&
                              snapshot.data!.snapshot.value != null) {
                            final val = snapshot.data!.snapshot.value;
                            isOn =
                                (val == true ||
                                val == "true" ||
                                val == 1 ||
                                val == "1");
                          }

                          return _buildActionBtn(
                            "LIGHTS",
                            Icons.highlight,
                            isOn
                                ? Colors.yellowAccent
                                : Colors.amber.withValues(alpha: 0.5),
                            onPress: () => widget.iotService.toggleLed(!isOn),
                            onRelease: () {},
                          );
                        },
                      ),

                      // BRAKE
                      _buildActionBtn(
                        "BRAKE",
                        Icons.pan_tool,
                        Colors.redAccent,
                        size: 100,
                        onPress: () => _sendCommand("S"),
                        onRelease: () {},
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

  Widget _buildDpadBtn(String cmd, IconData icon, Color color) {
    return GestureDetector(
      onTapDown: (_) => _sendCommand(cmd),
      onTapUp: (_) => _sendCommand("S"),
      onTapCancel: () => _sendCommand("S"),
      child: Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 15),
          ],
        ),
        child: Icon(icon, color: color, size: 40),
      ),
    );
  }

  Widget _buildActionBtn(
    String label,
    IconData icon,
    Color color, {
    double size = 80,
    required VoidCallback onPress,
    required VoidCallback onRelease,
  }) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.mediumImpact();
        onPress();
      },
      onTapUp: (_) => onRelease(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              border: Border.all(color: color, width: 3),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20),
              ],
            ),
            child: Icon(icon, color: color, size: size * 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.robotoMono(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
