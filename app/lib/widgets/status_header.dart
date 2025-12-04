import 'dart:async'; // Required for Timer
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/iot_service.dart';

class StatusHeader extends StatefulWidget {
  final IoTService iotService;

  const StatusHeader({super.key, required this.iotService});

  @override
  State<StatusHeader> createState() => _StatusHeaderState();
}

class _StatusHeaderState extends State<StatusHeader> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Force UI to rebuild every 5 seconds to update "Offline" status
    // even if no new data comes from the ESP.
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: widget.iotService.lastWateredStream,
      builder: (context, snapshot) {
        String timeText = "Never";
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          int timestamp =
              int.tryParse(snapshot.data!.snapshot.value.toString()) ?? 0;
          if (timestamp > 0) {
            DateTime date = DateTime.fromMillisecondsSinceEpoch(
              timestamp * 1000,
            );
            timeText = DateFormat('MMM d, h:mm a').format(date);
          }
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Last Watered",
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
                Text(
                  timeText,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            _buildOnlineStatus(),
          ],
        );
      },
    );
  }

  Widget _buildOnlineStatus() {
    return StreamBuilder<DatabaseEvent>(
      stream: widget.iotService.deviceLastSeenStream,
      builder: (context, snapshot) {
        bool isOnline = false;
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          int lastSeenTs =
              int.tryParse(snapshot.data!.snapshot.value.toString()) ?? 0;

          // Compare UTC to UTC
          int now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

          // If update was less than 120s ago, we are online
          if ((now - lastSeenTs).abs() < 120) {
            isOnline = true;
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (isOnline ? Colors.green : Colors.red).withValues(
              alpha: 0.2,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isOnline ? Colors.green : Colors.red),
          ),
          child: Row(
            children: [
              Icon(
                Icons.circle,
                size: 10,
                color: isOnline ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 6),
              Text(
                isOnline ? "ONLINE" : "OFFLINE",
                style: GoogleFonts.poppins(
                  color: isOnline ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
