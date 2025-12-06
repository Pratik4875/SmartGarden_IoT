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
import '../widgets/garden_refresh_indicator.dart'; // NEW IMPORT

class SmartGardenScreen extends StatefulWidget {
  final IoTService iotService;

  const SmartGardenScreen({super.key, required this.iotService});

  @override
  State<SmartGardenScreen> createState() => _SmartGardenScreenState();
}

class _SmartGardenScreenState extends State<SmartGardenScreen> {
  // Future that controls the initial load and manual refresh state
  late Future<void> _refreshFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the future by waiting for the service to be ready and then forcing a refresh
    _refreshFuture = widget.iotService.ready.then(
      (_) => _refreshData(silent: true),
    );
  }

  Future<void> _refreshData({bool silent = false}) async {
    // 1. Force fetch data from Firebase (Updates local cache)
    final statusMsg = await widget.iotService.forceStatusRefresh();

    // 2. Trigger UI Rebuild to show the new cached data
    if (mounted) {
      setState(() {
        // This setState is critical to update widgets reading from Streams
        // that might have received new values during the forceRefresh
      });

      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(statusMsg),
            backgroundColor: statusMsg.contains("Online")
                ? Colors.green
                : Colors.orange,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

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
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          // Graph / History Button
          IconButton(
            icon: const Icon(Icons.show_chart, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HistoryScreen(iotService: widget.iotService),
              ),
            ),
          ),
        ],
      ),
      // Use _refreshFuture to manage the global loading state
      body: FutureBuilder(
        future: _refreshFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CustomLoadingAnimation(size: 50));
          }

          // NEW: Use the Custom GardenRefreshIndicator
          return GardenRefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  StatusHeader(iotService: widget.iotService),
                  const SizedBox(height: 30),
                  InsightsCard(iotService: widget.iotService),
                  const SizedBox(height: 30),
                  SensorGrid(iotService: widget.iotService),
                  const SizedBox(height: 30),
                  ScheduleList(iotService: widget.iotService),
                  const SizedBox(height: 30),
                  PumpControl(iotService: widget.iotService),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
