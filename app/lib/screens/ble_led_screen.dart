import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptic Feedback
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';

class BleLedScreen extends StatefulWidget {
  const BleLedScreen({super.key});

  @override
  State<BleLedScreen> createState() => _BleLedScreenState();
}

class _BleLedScreenState extends State<BleLedScreen> {
  // --- STATE ---
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  bool _isScanning = false;
  List<ScanResult> _scanResults = [];
  late StreamSubscription<List<ScanResult>> _scanSubscription;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _stopScan();
    super.dispose();
  }

  // --- LOGIC: SCANNING ---
  Future<void> _startScan() async {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
      _scanResults = [];
    });

    try {
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        if (mounted) setState(() => _scanResults = results);
      });
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      await Future.delayed(const Duration(seconds: 10));
      if (mounted) setState(() => _isScanning = false);
    } catch (e) {
      debugPrint("Scan Error: $e");
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      _scanSubscription.cancel();
      if (mounted) setState(() => _isScanning = false);
    } catch (e) {
      debugPrint("Stop Error: $e");
    }
  }

  // --- LOGIC: CONNECTING ---
  Future<void> _connectToDevice(BluetoothDevice device) async {
    await _stopScan();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Connecting to ${device.platformName}..."),
        backgroundColor: Colors.blueGrey,
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      await device.connect(autoConnect: false);

      // Auto-Detect Write Characteristic
      List<BluetoothService> services = await device.discoverServices();
      BluetoothCharacteristic? foundChar;
      for (var service in services) {
        for (var char in service.characteristics) {
          if (char.properties.write || char.properties.writeWithoutResponse) {
            foundChar = char;
            break;
          }
        }
        if (foundChar != null) break;
      }

      if (mounted) {
        setState(() {
          _connectedDevice = device;
          _writeCharacteristic = foundChar;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Connection Failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disconnect() async {
    await _connectedDevice?.disconnect();
    if (mounted) {
      setState(() {
        _connectedDevice = null;
        _writeCharacteristic = null;
      });
      _startScan();
    }
  }

  // --- LOGIC: SENDING ---
  Future<void> _sendData(String data) async {
    if (_writeCharacteristic == null) return;

    HapticFeedback.mediumImpact();

    try {
      bool canWriteNoResponse =
          _writeCharacteristic!.properties.writeWithoutResponse;
      await _writeCharacteristic!.write(
        utf8.encode(data),
        withoutResponse: canWriteNoResponse,
      );
    } catch (e) {
      debugPrint("Write Error: $e");
    }
  }

  // --- UI BUILDING ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          "BLE COMMANDER",
          // CHANGED: jetbrainsMono -> robotoMono (Standard & Safe)
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
        actions: [
          if (_connectedDevice != null)
            IconButton(
              icon: const Icon(
                Icons.power_settings_new,
                color: Colors.redAccent,
              ),
              onPressed: _disconnect,
              tooltip: "Disconnect",
            ),
        ],
      ),
      body: _connectedDevice == null ? _buildScanner() : _buildController(),
    );
  }

  // --- VIEW 1: SCANNER ---
  Widget _buildScanner() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          color: const Color(0xFF1E1E1E),
          child: Center(
            child: _isScanning
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.greenAccent,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    "PULL DOWN TO REFRESH",
                    style: GoogleFonts.robotoMono(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _startScan,
            color: Colors.greenAccent,
            backgroundColor: const Color(0xFF2C2C2C),
            child: _scanResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.bluetooth_searching,
                          size: 80,
                          color: Colors.white10,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "NO DEVICES FOUND",
                          style: GoogleFonts.robotoMono(color: Colors.white24),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _scanResults.length,
                    itemBuilder: (context, index) {
                      final res = _scanResults[index];
                      String name = res.device.platformName;
                      if (name.isEmpty) name = "Unknown Device";

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.bluetooth,
                            color: Colors.greenAccent,
                          ),
                          title: Text(
                            name,
                            style: GoogleFonts.robotoMono(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            res.device.remoteId.toString(),
                            style: GoogleFonts.robotoMono(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.white24,
                          ),
                          onTap: () => _connectToDevice(res.device),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  // --- VIEW 2: CONTROLLER ---
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
              // FIXED: withOpacity -> withValues
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Pulsing Dot
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    // FIXED: withOpacity -> withValues
                    BoxShadow(
                      color: Colors.greenAccent.withValues(alpha: 0.6),
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
                    "CONNECTED TO",
                    style: GoogleFonts.robotoMono(
                      color: Colors.grey,
                      fontSize: 10,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    _connectedDevice?.platformName ?? "UNKNOWN",
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

        // 2. THE ROBUST PUSH BUTTONS
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildRobustButton(
              label: "ON",
              color: Colors.greenAccent,
              icon: Icons.power_settings_new,
              onTap: () => _sendData("1"),
            ),
            const SizedBox(width: 30),
            _buildRobustButton(
              label: "OFF",
              color: Colors.redAccent,
              icon: Icons.power_off,
              onTap: () => _sendData("0"),
            ),
          ],
        ),

        const Spacer(),

        Text(
          "ECOSYNC CONTROLLER v1.0",
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
            // Dark shadow (Depth)
            // FIXED: withOpacity -> withValues
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.8),
              offset: const Offset(8, 8),
              blurRadius: 16,
            ),
            // Light shadow (Highlight)
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
            // Glowing Icon
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // FIXED: withOpacity -> withValues
                color: color.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 1,
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
