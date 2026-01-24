import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
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

  // NEW: Helper to showing blocking dialogs
  void _showBlockingDialog(String title, String message, IconData icon, Color color) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(message, style: GoogleFonts.poppins(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () {
                 Navigator.of(context).pop(); // Try to dismiss (will fail if condition persists in build)
                 Navigator.of(context).pop(); // Go back to Home
              },
              child: const Text("GO BACK"),
            )
          ],
        ),
      ),
    );
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
      body: StreamBuilder<DatabaseEvent>(
        stream: widget.iotService.requestTimeStream, // Heartbeat Stream
        builder: (context, beatSnap) {
           // 1. Connection / Timeout Logic
           bool isOffline = false;
           if (beatSnap.hasData && beatSnap.data!.snapshot.value != null) {
              final val = beatSnap.data!.snapshot.value;
              int ts = 0;
              
              if (val is Map) {
                ts = int.tryParse(val['timestamp'].toString()) ?? 0;
              } else if (val is int) {
                ts = val;
              } else {
                 ts = int.tryParse(val.toString()) ?? 0;
              }
              
              // Check if > 2 mins old (120 seconds)
              int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
              if (ts > 0 && (now - ts > 120)) {
                 isOffline = true;
              }
           } else {
              // No data yet? Assume offline or connecting.
              // For better UX during load, maybe don't block immediately.
           }

           if (isOffline) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, size: 80, color: Colors.orange),
                    const SizedBox(height: 20),
                    Text("ESP Offline", style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text("Last seen > 2 mins ago", style: GoogleFonts.poppins(color: Colors.grey)),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Go Back"), 
                    )
                  ],
                ),
              );
           }

           // 2. Database Error Logic (Implicit in stream error or null)
           if (beatSnap.hasError) {
              return Center(child: Text("Database Error: ${beatSnap.error}", style: const TextStyle(color: Colors.red)));
           }

           return FutureBuilder(
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
          );
        }
      ),
    );
  }
}
