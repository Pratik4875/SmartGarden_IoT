import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/iot_service.dart';
import 'iot_car_screen.dart';
import 'iot_terminal_screen.dart';
import 'iot_led_screen.dart';
import 'profile_screen.dart'; // Import Profile Screen for navigation

class IoTHubScreen extends StatelessWidget {
  final IoTService iotService;

  const IoTHubScreen({super.key, required this.iotService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          "CLOUD LAB",
          style: GoogleFonts.robotoMono(
            color: Colors.purpleAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: !iotService.isConnected
          ? _buildErrorView(context)
          : GridView.count(
              padding: const EdgeInsets.all(20),
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              children: [
                _buildCard(
                  context,
                  "CLOUD CAR",
                  Icons.directions_car_filled,
                  Colors.cyanAccent,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => IoTCarScreen(iotService: iotService),
                    ),
                  ),
                ),

                _buildCard(
                  context,
                  "TERMINAL",
                  Icons.terminal,
                  Colors.greenAccent,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => IoTTerminalScreen(iotService: iotService),
                    ),
                  ),
                ),

                _buildCard(
                  context,
                  "SMART LED",
                  Icons.lightbulb,
                  Colors.yellowAccent,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => IoTLedScreen(iotService: iotService),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCard(
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
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          // FIX: withValues instead of withOpacity
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 15),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 15),
            Text(
              title,
              style: GoogleFonts.robotoMono(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.link_off, size: 80, color: Colors.redAccent),
          const SizedBox(height: 20),
          Text(
            "OFFLINE",
            style: GoogleFonts.robotoMono(
              color: Colors.redAccent,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Database Not Linked",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(iotService: iotService),
                ),
              );
            },
            child: const Text("CONFIGURE IN PROFILE"),
          ),
        ],
      ),
    );
  }
}
