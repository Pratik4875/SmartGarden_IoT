import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptic Feedback
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/iot_service.dart';

class IoTLedScreen extends StatelessWidget {
  final IoTService iotService;
  const IoTLedScreen({super.key, required this.iotService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          "CLOUD COMMANDER",
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
      body: Column(
        children: [
          // 1. STATUS BAR
          StreamBuilder<DatabaseEvent>(
            stream: iotService.listenGenericData('led/status'),
            builder: (context, snapshot) {
              String statusText = "SYNCING...";
              Color statusColor = Colors.grey;

              if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                final val = snapshot.data!.snapshot.value;
                bool isOn =
                    (val == true || val == "true" || val == 1 || val == "1");
                statusText = isOn ? "ACTIVE" : "STANDBY";
                statusColor = isOn ? Colors.greenAccent : Colors.redAccent;
              }

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 20,
                ),
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
                    // Pulsing Dot
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.6),
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
                          "SYSTEM STATUS",
                          style: GoogleFonts.robotoMono(
                            color: Colors.grey,
                            fontSize: 10,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          statusText,
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
              );
            },
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
                onTap: () => iotService.toggleLed(true),
              ),
              const SizedBox(width: 30),
              _buildRobustButton(
                label: "OFF",
                color: Colors.redAccent,
                icon: Icons.power_off,
                onTap: () => iotService.toggleLed(false),
              ),
            ],
          ),

          const Spacer(),

          Text(
            "SECURE LINK v2.0",
            style: GoogleFonts.robotoMono(color: Colors.white10, fontSize: 10),
          ),
          const SizedBox(height: 20),
        ],
      ),
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
