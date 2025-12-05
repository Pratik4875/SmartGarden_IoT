import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/iot_service.dart';
import 'history_screen.dart';

// Widgets
import '../widgets/status_header.dart';
import '../widgets/sensor_grid.dart';
import '../widgets/schedule_list.dart';
import '../widgets/pump_control.dart';
import '../widgets/insights_card.dart';
import '../widgets/custom_loading_animation.dart';

class SmartGardenScreen extends StatelessWidget {
  final IoTService iotService;

  const SmartGardenScreen({super.key, required this.iotService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Smart Garden',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Graph / History Button
          IconButton(
            icon: const Icon(Icons.show_chart, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HistoryScreen(iotService: iotService),
              ),
            ),
          ),
        ],
      ),
      // Wait for Auth/Connection before showing data to prevent "Permission Denied"
      body: FutureBuilder(
        future: iotService.ready,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CustomLoadingAnimation(size: 50));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                StatusHeader(iotService: iotService),
                const SizedBox(height: 30),
                InsightsCard(iotService: iotService),
                const SizedBox(height: 30),
                SensorGrid(iotService: iotService),
                const SizedBox(height: 30),
                ScheduleList(iotService: iotService),
                const SizedBox(height: 30),
                PumpControl(iotService: iotService),
              ],
            ),
          );
        },
      ),
    );
  }
}
