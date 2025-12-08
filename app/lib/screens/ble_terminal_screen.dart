import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class BleTerminalScreen extends StatefulWidget {
  const BleTerminalScreen({super.key});

  @override
  State<BleTerminalScreen> createState() => _BleTerminalScreenState();
}

class _BleTerminalScreenState extends State<BleTerminalScreen> {
  // --- STATE ---
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  // REMOVED: _notifyCharacteristic (caused the warning)

  bool _isScanning = false;
  List<ScanResult> _scanResults = [];
  final List<TerminalMessage> _logs = [];

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late StreamSubscription<List<ScanResult>> _scanSubscription;
  StreamSubscription<List<int>>? _notifySubscription;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _stopScan();
    _notifySubscription?.cancel();
    // _connectedDevice?.disconnect(); // Optional: Keep connection alive?
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- 1. SCANNING ---
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

  // --- 2. CONNECT & SETUP ---
  Future<void> _connectToDevice(BluetoothDevice device) async {
    await _stopScan();
    if (!mounted) return;

    _addLog("System", "Connecting to ${device.platformName}...");

    try {
      await device.connect(autoConnect: false);
      _addLog("System", "Connected! Discovering services...");

      List<BluetoothService> services = await device.discoverServices();
      BluetoothCharacteristic? writeChar;
      BluetoothCharacteristic? notifyChar;

      // Auto-Detect Characteristics
      for (var service in services) {
        for (var char in service.characteristics) {
          if (char.properties.write || char.properties.writeWithoutResponse) {
            writeChar = char;
          }
          if (char.properties.notify || char.properties.indicate) {
            notifyChar = char;
          }
        }
      }

      if (notifyChar != null) {
        _addLog("System", "Subscribing to notifications...");
        await notifyChar.setNotifyValue(true);
        _notifySubscription = notifyChar.lastValueStream.listen((value) {
          String text = utf8.decode(value, allowMalformed: true);
          if (text.isNotEmpty) _addLog("RX", text);
        });
      }

      if (mounted) {
        setState(() {
          _connectedDevice = device;
          _writeCharacteristic = writeChar;
          // REMOVED assignment to _notifyCharacteristic
        });
      }

      _addLog(
        "System",
        "Terminal Ready. ${writeChar == null ? '(No Write Found)' : ''}",
      );
    } catch (e) {
      _addLog("Error", "Connection failed: $e");
    }
  }

  Future<void> _disconnect() async {
    await _connectedDevice?.disconnect();
    if (mounted) {
      setState(() {
        _connectedDevice = null;
        _writeCharacteristic = null;
        _logs.clear();
      });
      _startScan();
    }
  }

  // --- 3. SENDING DATA ---
  Future<void> _sendMessage() async {
    String text = _textController.text.trim();
    if (text.isEmpty || _writeCharacteristic == null) return;

    _textController.clear();
    _addLog("TX", text);
    HapticFeedback.lightImpact();

    try {
      // Note: Some boards require adding "\n" or "\r" to the end of the string
      // text += "\n";

      bool canWriteNoResponse =
          _writeCharacteristic!.properties.writeWithoutResponse;
      await _writeCharacteristic!.write(
        utf8.encode(text),
        withoutResponse: canWriteNoResponse,
      );
    } catch (e) {
      _addLog("Error", "Send failed: $e");
    }
  }

  void _addLog(String type, String message) {
    if (!mounted) return;
    setState(() {
      _logs.add(
        TerminalMessage(
          type: type,
          message: message,
          timestamp: DateTime.now(),
        ),
      );
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "TERMINAL >_",
          style: GoogleFonts.robotoMono(
            color: Colors.greenAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.greenAccent),
        actions: [
          if (_connectedDevice != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _disconnect,
              tooltip: "Disconnect",
            ),
        ],
      ),
      body: _connectedDevice == null ? _buildScanner() : _buildTerminal(),
    );
  }

  // VIEW 1: SCANNER
  Widget _buildScanner() {
    return Column(
      children: [
        if (_isScanning)
          const LinearProgressIndicator(
            color: Colors.greenAccent,
            backgroundColor: Colors.white10,
          ),
        Expanded(
          child: _scanResults.isEmpty
              ? Center(
                  child: Text(
                    "SCANNING FOR SIGNALS...",
                    style: GoogleFonts.robotoMono(
                      color: Colors.greenAccent.withValues(alpha: 0.5),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _scanResults.length,
                  itemBuilder: (context, index) {
                    final res = _scanResults[index];
                    String name = res.device.platformName.isEmpty
                        ? "Unknown Device"
                        : res.device.platformName;
                    return ListTile(
                      title: Text(
                        name,
                        style: GoogleFonts.robotoMono(
                          color: Colors.greenAccent,
                        ),
                      ),
                      subtitle: Text(
                        res.device.remoteId.toString(),
                        style: GoogleFonts.robotoMono(
                          color: Colors.greenAccent.withValues(alpha: 0.5),
                          fontSize: 10,
                        ),
                      ),
                      onTap: () => _connectToDevice(res.device),
                      trailing: Text(
                        "${res.rssi} dBm",
                        style: GoogleFonts.robotoMono(
                          color: Colors.greenAccent,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // VIEW 2: TERMINAL
  Widget _buildTerminal() {
    return Column(
      children: [
        // LOG AREA
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            color: const Color(0xFF0D0D0D),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.robotoMono(fontSize: 14),
                      children: [
                        TextSpan(
                          text:
                              "[${DateFormat('HH:mm:ss').format(log.timestamp)}] ",
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        TextSpan(
                          text: "${log.type}: ",
                          style: TextStyle(
                            color: log.type == "TX"
                                ? Colors.blueAccent
                                : log.type == "RX"
                                ? Colors.orangeAccent
                                : log.type == "Error"
                                ? Colors.red
                                : Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: log.message,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // INPUT AREA
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border(
              top: BorderSide(color: Colors.greenAccent.withValues(alpha: 0.3)),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.greenAccent,
                size: 16,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: GoogleFonts.robotoMono(color: Colors.white),
                  cursorColor: Colors.greenAccent,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Enter command...",
                    hintStyle: TextStyle(color: Colors.white24),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.greenAccent),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TerminalMessage {
  final String type;
  final String message;
  final DateTime timestamp;

  TerminalMessage({
    required this.type,
    required this.message,
    required this.timestamp,
  });
}
