import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ble_led_screen.dart';
import 'ble_terminal_screen.dart'; // <--- Add this line
import 'classic_car_screen.dart';

class BleHubScreen extends StatelessWidget {
  const BleHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: Text(
          "Bluetooth Control",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          children: [
            _buildBleOption(
              context,
              "LED Control",
              Icons.lightbulb,
              Colors.yellowAccent,
              () {
                // NAVIGATE TO THE FUNCTIONAL SCREEN
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BleLedScreen()),
                );
              },
            ),
            // ... inside build() ...
            _buildBleOption(
              context,
              "RC Car",
              Icons.directions_car,
              Colors.redAccent,
              () {
                // Navigate to the CLASSIC car screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClassicCarScreen(),
                  ),
                );
              },
            ),
            _buildBleOption(
              context,
              "Terminal",
              Icons.terminal,
              Colors.greenAccent,
              () {
                // This tells Flutter to open the Terminal Screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BleTerminalScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBleOption(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(20),
          // FIXED: Replaced withOpacity(0.3) -> withValues(alpha: 0.3)
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 15),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
