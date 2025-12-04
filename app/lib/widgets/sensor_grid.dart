import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/iot_service.dart';

class SensorGrid extends StatelessWidget {
  final IoTService iotService;

  const SensorGrid({super.key, required this.iotService});

  @override
  Widget build(BuildContext context) {
    // 1. Listen to Device Heartbeat first
    return StreamBuilder<DatabaseEvent>(
      stream: iotService.deviceLastSeenStream,
      builder: (context, deviceSnapshot) {
        bool isOnline = false;

        // Calculate Online Status
        if (deviceSnapshot.hasData &&
            deviceSnapshot.data!.snapshot.value != null) {
          int lastSeenTs =
              int.tryParse(deviceSnapshot.data!.snapshot.value.toString()) ?? 0;
          int now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
          // 120s Buffer
          if ((now - lastSeenTs).abs() < 120) {
            isOnline = true;
          }
        }

        // 2. Pass isOnline to cards
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          childAspectRatio: 1.5,
          children: [
            _sensorCard(
              "Temperature",
              iotService.tempStream,
              "°C",
              Colors.orange,
              isOnline,
            ),
            _sensorCard(
              "Humidity",
              iotService.humidityStream,
              "%",
              Colors.blue,
              isOnline,
            ),
            _sensorCard(
              "Soil Moisture",
              iotService.soilStream,
              "%",
              Colors.green,
              isOnline,
            ),
          ],
        );
      },
    );
  }

  Widget _sensorCard(
    String title,
    Stream<DatabaseEvent> stream,
    String unit,
    Color color,
    bool isOnline, // NEW Parameter
  ) {
    return StreamBuilder<DatabaseEvent>(
      stream: stream,
      builder: (context, snapshot) {
        String value = "--";

        // Only show data if Device is Online AND Data exists
        if (isOnline &&
            snapshot.hasData &&
            snapshot.data!.snapshot.value != null) {
          value = snapshot.data!.snapshot.value.toString();
        }

        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isOnline
                  ? color.withValues(alpha: 0.3)
                  : Colors.grey.withValues(
                      alpha: 0.2,
                    ), // Grey border if offline
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.circle,
                size: 10,
                color: isOnline ? color : Colors.grey, // Grey dot if offline
              ),
              Text(
                "$value$unit",
                style: GoogleFonts.poppins(
                  color: isOnline
                      ? Colors.white
                      : Colors.white38, // Dim text if offline
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
