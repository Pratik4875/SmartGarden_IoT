import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_classic_serial/flutter_bluetooth_classic.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

class ClassicCarScreen extends StatefulWidget {
  const ClassicCarScreen({super.key});

  @override
  State<ClassicCarScreen> createState() => _ClassicCarScreenState();
}

class _ClassicCarScreenState extends State<ClassicCarScreen> {
  final _bluetooth = FlutterBluetoothClassic();
  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice? _connectedDevice;
  bool _isConnecting = false;
  bool _lineFollowerMode = false;
  StreamSubscription? _statusSubscription;

  @override
  void initState() {
    super.initState();
    // 1. FORCE LANDSCAPE MODE (Gaming Feel)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    ); // Hide status bars
    _initBluetooth();
  }

  @override
  void dispose() {
    // 2. RESTORE PORTRAIT MODE
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _statusSubscription?.cancel();
    _bluetooth.disconnect();
    super.dispose();
  }

  Future<void> _initBluetooth() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    try {
      final devices = await _bluetooth.getPairedDevices();
      if (mounted) setState(() => _devicesList = devices);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    setState(() => _isConnecting = true);
    try {
      await _bluetooth.connect(device.address);
      setState(() {
        _connectedDevice = device;
        _isConnecting = false;
      });
      _showSnack("SYSTEM LINKED: ${device.name}");

      _statusSubscription?.cancel();
      _statusSubscription = _bluetooth.onConnectionChanged.listen((state) {
        if (!state.isConnected) {
          if (mounted) {
            setState(() {
              _connectedDevice = null;
              _isConnecting = false;
            });
            _showSnack("CONNECTION LOST");
          }
        }
      });
    } catch (e) {
      setState(() => _isConnecting = false);
      _showSnack("LINK FAILED");
    }
  }

  Future<void> _disconnect() async {
    await _bluetooth.disconnect();
    setState(() => _connectedDevice = null);
  }

  Future<void> _sendCommand(String cmd) async {
    if (_connectedDevice == null) return;
    HapticFeedback.heavyImpact(); // Stronger feedback for gaming
    try {
      await _bluetooth.sendString(cmd);
    } catch (e) {
      debugPrint("TX Error: $e");
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.greenAccent.withValues(alpha: 0.8),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D), // Cyberpunk Black
      body: Stack(
        children: [
          // Background Grid Effect (Optional aesthetic)
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset(
                "assets/logo.png", // Reusing your logo as watermark
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),

          SafeArea(
            child: _connectedDevice == null
                ? _buildConnectionScreen()
                : _buildGamingInterface(),
          ),
        ],
      ),
    );
  }

  // --- SCREEN 1: CONNECTION MENU ---
  Widget _buildConnectionScreen() {
    return Center(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          border: Border.all(color: Colors.greenAccent, width: 2),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.greenAccent.withValues(alpha: 0.2),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "ESTABLISH UPLINK",
              style: GoogleFonts.audiowide(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 20),
            if (_isConnecting)
              const CircularProgressIndicator(color: Colors.greenAccent)
            else if (_devicesList.isEmpty)
              Text(
                "NO PAIRED DEVICES FOUND",
                style: GoogleFonts.robotoMono(color: Colors.grey),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: _devicesList.length,
                  itemBuilder: (context, index) {
                    final device = _devicesList[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.bluetooth,
                        color: Colors.greenAccent,
                      ),
                      title: Text(
                        device.name,
                        style: GoogleFonts.robotoMono(color: Colors.white),
                      ),
                      subtitle: Text(
                        device.address,
                        style: GoogleFonts.robotoMono(color: Colors.grey),
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                        ),
                        onPressed: () => _connect(device),
                        child: const Text(
                          "LINK",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 10),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _initBluetooth,
              tooltip: "Rescan",
            ),
          ],
        ),
      ),
    );
  }

  // --- SCREEN 2: THE GAMING INTERFACE ---
  Widget _buildGamingInterface() {
    return Row(
      children: [
        // === LEFT SIDE: D-PAD (Movement) ===
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDpadBtn("F", Icons.arrow_drop_up, Colors.cyanAccent),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDpadBtn("L", Icons.arrow_left, Colors.cyanAccent),
                  const SizedBox(width: 60), // Spacing for thumb
                  _buildDpadBtn("R", Icons.arrow_right, Colors.cyanAccent),
                ],
              ),
              _buildDpadBtn("B", Icons.arrow_drop_down, Colors.cyanAccent),
            ],
          ),
        ),

        // === CENTER: DASHBOARD ===
        Expanded(
          flex: 1,
          child: Column(
            children: [
              // Top Bar
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
                    const Icon(Icons.wifi, color: Colors.greenAccent, size: 16),
                    const SizedBox(width: 10),
                    Text(
                      _connectedDevice!.name,
                      style: GoogleFonts.robotoMono(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Mode Switch
              Column(
                children: [
                  Text(
                    _lineFollowerMode ? "AUTO-PILOT" : "MANUAL",
                    style: GoogleFonts.audiowide(
                      color: _lineFollowerMode
                          ? Colors.purpleAccent
                          : Colors.cyanAccent,
                      fontSize: 18,
                    ),
                  ),
                  Switch(
                    value: _lineFollowerMode,
                    activeColor: Colors.purpleAccent,
                    activeTrackColor: Colors.purple.withValues(alpha: 0.3),
                    inactiveThumbColor: Colors.cyanAccent,
                    inactiveTrackColor: Colors.cyan.withValues(alpha: 0.3),
                    onChanged: (val) {
                      setState(() => _lineFollowerMode = val);
                      _sendCommand(val ? "X" : "x");
                    },
                  ),
                ],
              ),

              const Spacer(),

              // Disconnect
              IconButton(
                icon: const Icon(Icons.power_settings_new, color: Colors.red),
                onPressed: _disconnect,
              ),
            ],
          ),
        ),

        // === RIGHT SIDE: ACTION BUTTONS (Stop & Horn) ===
        Expanded(
          flex: 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // HORN BUTTON (Yellow)
              _buildActionBtn(
                "HORN",
                Icons.volume_up,
                Colors.amber,
                onPress: () => _sendCommand("H"), // Horn ON
                onRelease: () => _sendCommand("h"), // Horn OFF
              ),

              // STOP BUTTON (Red - Main Action)
              _buildActionBtn(
                "BRAKE",
                Icons.pan_tool,
                Colors.redAccent,
                size: 100, // Bigger than horn
                onPress: () => _sendCommand("S"),
                onRelease: () {}, // No release action needed for stop
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- WIDGET: DIRECTIONAL BUTTON (D-PAD) ---
  Widget _buildDpadBtn(String cmd, IconData icon, Color color) {
    return GestureDetector(
      onTapDown: (_) => _sendCommand(cmd),
      onTapUp: (_) => _sendCommand("S"), // Auto-stop when thumb lifted
      child: Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          shape: BoxShape.circle, // Rounded buttons preferred for thumbs
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 40),
      ),
    );
  }

  // --- WIDGET: ACTION BUTTON (Stop/Horn) ---
  Widget _buildActionBtn(
    String label,
    IconData icon,
    Color color, {
    double size = 80,
    required VoidCallback onPress,
    required VoidCallback onRelease,
  }) {
    return GestureDetector(
      onTapDown: (_) => onPress(),
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
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
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
