import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ota_update/ota_update.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/iot_service.dart';
import 'login_screen.dart';
import 'history_screen.dart';

// Import New Widgets
import '../widgets/status_header.dart';
import '../widgets/sensor_grid.dart';
import '../widgets/scheduler_card.dart';
import '../widgets/pump_control.dart';
import '../widgets/insights_card.dart';

class DashboardScreen extends StatefulWidget {
  final String databaseUrl;
  final IoTService? iotServiceOverride;

  const DashboardScreen({
    super.key,
    required this.databaseUrl,
    this.iotServiceOverride,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late IoTService _iot;

  @override
  void initState() {
    super.initState();
    _iot = widget.iotServiceOverride ?? IoTService(widget.databaseUrl);
  }

  void _runUpdate(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Starting Update... Check Notification Panel"),
      ),
    );
    _iot.updateApp().listen(
      (OtaEvent event) {
        debugPrint("OTA Status: ${event.status} : ${event.value}");
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Update Error: $error"),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: Text(
          'EcoSync',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.logout),
          tooltip: "Switch Hub",
          onPressed: () => _logout(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart),
            tooltip: "History",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => HistoryScreen(iotService: _iot),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.system_update),
            onPressed: () => _runUpdate(context),
            tooltip: "Check for Updates",
          ),
        ],
      ),
      body: FutureBuilder(
        future: _iot.ready,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.greenAccent),
                  SizedBox(height: 20),
                  Text(
                    "Authenticating Securely...",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Security Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusHeader(iotService: _iot),
                const SizedBox(height: 30),
                InsightsCard(iotService: _iot),
                const SizedBox(height: 30),
                SensorGrid(iotService: _iot),
                const SizedBox(height: 30),
                SchedulerCard(iotService: _iot),
                const SizedBox(height: 30),
                PumpControl(iotService: _iot),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
