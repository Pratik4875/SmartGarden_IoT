import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/iot_service.dart';
import 'liquid_progress.dart'; // Import new widget

class SensorGrid extends StatelessWidget {
  final IoTService iotService;

  const SensorGrid({super.key, required this.iotService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: iotService.onlineStatusStream,
      initialData: false,
      builder: (context, statusSnapshot) {
        final bool isOnline = statusSnapshot.data ?? false;

        return Column(
          children: [
            // Top Row: Temp & Humidity (Standard Cards)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 1.4,
              children: [
                _sensorCard(
                  "Temperature",
                  iotService.tempStream,
                  "°C",
                  Icons.thermostat,
                  isOnline,
                  defaultColors: [Colors.orangeAccent, Colors.deepOrange],
                ),
                _sensorCard(
                  "Humidity",
                  iotService.humidityStream,
                  "%",
                  Icons.water_drop,
                  isOnline,
                  defaultColors: [Colors.cyanAccent, Colors.blueAccent],
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Full Width: Soil Moisture (Animated Liquid)
            _buildSoilCard(iotService.soilStream, isOnline),
          ],
        );
      },
    );
  }

  // New Special Card for Soil
  Widget _buildSoilCard(Stream<DatabaseEvent> stream, bool isOnline) {
    return StreamBuilder<DatabaseEvent>(
      stream: stream,
      builder: (context, snapshot) {
        double value = 0;
        if (isOnline &&
            snapshot.hasData &&
            snapshot.data!.snapshot.value != null) {
          value =
              double.tryParse(snapshot.data!.snapshot.value.toString()) ?? 0;
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "SOIL MOISTURE",
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${value.toInt()}%",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isOnline
                        ? (value < 30 ? "Dry • Needs Water" : "Moist • Optimal")
                        : "Offline",
                    style: GoogleFonts.poppins(
                      color: isOnline
                          ? (value < 30
                                ? Colors.orangeAccent
                                : Colors.greenAccent)
                          : Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              // The Animation
              LiquidProgress(
                value: value,
                maxValue: 100,
                size: 100, // Size of the circle
              ),
            ],
          ),
        );
      },
    );
  }

  // Standard Card (Kept same as before)
  Widget _sensorCard(
    String title,
    Stream<DatabaseEvent> stream,
    String unit,
    IconData icon,
    bool isOnline, {
    List<Color>? defaultColors,
  }) {
    return StreamBuilder<DatabaseEvent>(
      stream: stream,
      builder: (context, snapshot) {
        String valueStr = "--";
        if (isOnline &&
            snapshot.hasData &&
            snapshot.data!.snapshot.value != null) {
          valueStr = snapshot.data!.snapshot.value.toString();
        }

        List<Color> gradientColors =
            defaultColors ?? [Colors.grey, Colors.grey];
        if (!isOnline) gradientColors = [Colors.grey[800]!, Colors.grey[900]!];

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors
                  .map((c) => c.withValues(alpha: 0.8))
                  .toList(),
            ),
            boxShadow: isOnline
                ? [
                    BoxShadow(
                      color: gradientColors.last.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(
                  icon,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 16, color: Colors.white),
                    ),
                    Text(
                      "$valueStr$unit",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          const Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      title.toUpperCase(),
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
