import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  // REPLACE THESE WITH YOUR BOARD'S UUIDS
  // specific UUIDs for your device (Example: ESP32 UART Service)
  final String serviceUuid = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  final String charUuid =
      "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"; // RX Characteristic

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? targetCharacteristic;

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;
  Stream<bool> get isScanning => FlutterBluePlus.isScanning;

  // 1. Start Scanning
  Future<void> startScan() async {
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    } catch (e) {
      debugPrint("Error starting scan: $e");
    }
  }

  // 2. Stop Scanning
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  // 3. Connect to Device
  Future<void> connect(BluetoothDevice device) async {
    await device.connect();
    connectedDevice = device;
    await _discoverServices(device);
  }

  // 4. Discover Services & Find Write Characteristic
  Future<void> _discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();

    for (var service in services) {
      if (service.uuid.toString().toUpperCase() == serviceUuid) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toUpperCase() == charUuid) {
            targetCharacteristic = characteristic;
            debugPrint("✅ Found Target Characteristic!");
            return;
          }
        }
      }
    }
  }

  // 5. Send Data (1 for ON, 0 for OFF)
  Future<void> sendCommand(String command) async {
    if (targetCharacteristic == null) {
      debugPrint("❌ No characteristic found. Is device connected?");
      return;
    }

    // Convert string to bytes (utf8)
    List<int> bytes = command.codeUnits;
    await targetCharacteristic!.write(bytes, withoutResponse: true);
  }

  // 6. Disconnect
  Future<void> disconnect() async {
    await connectedDevice?.disconnect();
    connectedDevice = null;
    targetCharacteristic = null;
  }
}
