import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/iot_service.dart';

class PumpControl extends StatelessWidget {
  final IoTService iotService;

  const PumpControl({super.key, required this.iotService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: iotService.pumpStatusStream,
      builder: (context, snapshot) {
        bool isPumpOn = false;
        if (snapshot.hasData && snapshot.data!.snapshot.value == true) {
          isPumpOn = true;
        }

        // Active = Cyan/Blue Gradient
        // Inactive = Dark Grey
        final gradientColors = isPumpOn
            ? [Colors.cyanAccent, Colors.blueAccent]
            : [Colors.grey.shade800, Colors.grey.shade900];

        final textColor = isPumpOn ? Colors.black : Colors.white54;

        // Add a glow effect when ON
        final List<BoxShadow> shadows = isPumpOn
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
          onTap: () => iotService.togglePump(!isPumpOn),
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
              border: isPumpOn
                  ? null
                  : Border.all(color: Colors.white10, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPumpOn ? Icons.water_drop : Icons.water_drop_outlined,
                  color: textColor,
                  size: 32,
                ),
                const SizedBox(width: 15),
                Text(
                  isPumpOn ? "PUMP ACTIVE" : "START PUMP",
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
  }
}
