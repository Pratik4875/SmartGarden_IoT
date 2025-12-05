import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/iot_service.dart';
import 'smart_garden_screen.dart'; // Ensure this file exists
import 'profile_screen.dart';
import 'ble_hub_screen.dart'; // Ensure this file exists

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late IoTService _iot;

  @override
  void initState() {
    super.initState();
    // Initialize Service (Loads saved URL automatically)
    _iot = IoTService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Don't show back button on Hub
        title: Row(
          children: [
            // Ensure you have assets/logo.svg
            SvgPicture.asset('assets/logo.svg', height: 30),
            const SizedBox(width: 10),
            Text(
              "EcoSync Hub",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.cyanAccent,
              backgroundImage: _iot.photoUrl != null
                  ? NetworkImage(_iot.photoUrl!)
                  : null,
              child: _iot.photoUrl == null
                  ? const Icon(Icons.person, size: 20, color: Colors.black)
                  : null,
            ),
            onPressed: () {
              // Navigate to Profile and refresh state when returning
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(iotService: _iot),
                ),
              ).then((_) {
                setState(() {
                  // Triggers rebuild to update Name/Photo if changed
                });
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome back,\n${_iot.userName}",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 30),

            Text(
              "WI-FI PROJECTS",
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 15),

            // 1. Smart Garden Card (Reactive Status)
            StreamBuilder<bool>(
              stream: _iot.onlineStatusStream,
              initialData: false,
              builder: (context, snapshot) {
                final bool isOnline = snapshot.data ?? false;
                final bool isConfigured = _iot.isConnected;

                String statusText = "Setup Required";
                Color statusColor = Colors.grey;

                if (isConfigured) {
                  statusText = isOnline
                      ? "Online • Pump Standby"
                      : "Offline (Last seen > 2m ago)";
                  statusColor = isOnline
                      ? Colors.greenAccent
                      : Colors.redAccent;
                }

                return _buildProjectCard(
                  title: "Smart Garden",
                  subtitle: statusText,
                  icon: Icons.grass,
                  color: statusColor,
                  onTap: () {
                    if (isConfigured) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SmartGardenScreen(iotService: _iot),
                        ),
                      );
                    } else {
                      _showSetupDialog();
                    }
                  },
                );
              },
            ),

            const SizedBox(height: 15),

            // 2. Home Automation Card
            _buildProjectCard(
              title: "Home Automation",
              subtitle: "Lights & Switches",
              icon: Icons.home,
              color: Colors.orangeAccent,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Coming in Phase 2!")),
                );
              },
            ),

            const SizedBox(height: 30),
            Text(
              "LOCAL CONTROL (BLE)",
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 15),

            // 3. Bluetooth Hub Card
            _buildProjectCard(
              title: "Bluetooth Hub",
              subtitle: "Car, LED & Terminal",
              icon: Icons.bluetooth,
              color: Colors.blueAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BleHubScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(20),
          // Updated: withValues(alpha: ...) handles opacity correctly
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
          ],
        ),
      ),
    );
  }

  void _showSetupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text(
          "Setup Required",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Please link your Firebase Database in Profile to use Wi-Fi features.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text("GO TO PROFILE"),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(iotService: _iot),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
