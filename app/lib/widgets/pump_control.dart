import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/iot_service.dart';

class PumpControl extends StatelessWidget {
  final IoTService iotService;

  const PumpControl({super.key, required this.iotService});

  void _showOfflineMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Device is offline. Cannot send control commands."),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Outer StreamBuilder checks device online status
    return StreamBuilder<bool>(
      stream: iotService.onlineStatusStream,
      initialData: false,
      builder: (context, onlineSnap) {
        final bool isOnline = onlineSnap.data ?? false;

        // Inner StreamBuilder checks pump status
        return StreamBuilder<DatabaseEvent>(
          stream: iotService.pumpStatusStream,
          builder: (context, snapshot) {
            bool isPumpOn = false;
            if (snapshot.hasData && snapshot.data!.snapshot.value == true) {
              isPumpOn = true;
            }

            // Determine if control is available
            final bool isControlAvailable = isOnline;

            // Active = Cyan/Blue Gradient
            // Inactive = Dark Grey
            final gradientColors = isPumpOn && isControlAvailable
                ? [Colors.cyanAccent, Colors.blueAccent]
                : isControlAvailable
                ? [Colors.grey.shade800, Colors.grey.shade900]
                : [Colors.black54, Colors.black87]; // Offline colors

            final textColor = isPumpOn && isControlAvailable
                ? Colors.black
                : isControlAvailable
                ? Colors.white54
                : Colors.redAccent;

            final List<BoxShadow> shadows = isPumpOn && isControlAvailable
                ? [
                    BoxShadow(
                      color: Colors.cyanAccent.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [
                    const BoxShadow(
                      color: Colors.black54,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ];

            return GestureDetector(
              key: const Key('pumpControl'), // <-- test key
              // Block the onTap if offline
              onTap: isControlAvailable
                  ? () => iotService.togglePump(!isPumpOn)
                  : () => _showOfflineMessage(context),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: shadows,
                  border: isPumpOn && isControlAvailable
                      ? null
                      : Border.all(color: Colors.white10, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isControlAvailable
                          ? (isPumpOn
                                ? Icons.water_drop
                                : Icons.water_drop_outlined)
                          : Icons
                                .power_off, // Show a power off icon when unavailable
                      color: textColor,
                      size: 32,
                    ),
                    const SizedBox(width: 15),
                    Text(
                      isControlAvailable
                          ? (isPumpOn ? "PUMP ACTIVE" : "START PUMP")
                          : "DEVICE OFFLINE",
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
