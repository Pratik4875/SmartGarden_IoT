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

        // Active = Cyan/Blue Gradient, Inactive = Dark Grey
        final gradientColors = isPumpOn
            ? [Colors.cyanAccent, Colors.blueAccent]
            : [Colors.grey.shade800, Colors.grey.shade900];

        final textColor = isPumpOn ? Colors.black : Colors.white54;
        final shadowColor = isPumpOn
            ? Colors.cyanAccent.withValues(alpha: 0.4)
            : Colors.black;

        return GestureDetector(
          onTap: () => iotService.togglePump(!isPumpOn),
          child: Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
              border: isPumpOn ? null : Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPumpOn ? Icons.water_drop : Icons.water_drop_outlined,
                  color: textColor,
                  size: 30,
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
