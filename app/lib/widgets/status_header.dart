import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/iot_service.dart';
import 'package:firebase_database/firebase_database.dart';

class StatusHeader extends StatelessWidget {
  final IoTService iotService;

  const StatusHeader({super.key, required this.iotService});

  String _formatTimestamp(int timestamp) {
    if (timestamp <= 0) return "Never";

    // Auto-detect Milliseconds vs Seconds
    // 1600000000 is approx Year 2020 in seconds.
    // If it's larger than 100 billion, it's definitely milliseconds.
    int timeInMs = timestamp;
    if (timestamp < 100000000000) {
      timeInMs = timestamp * 1000;
    }

    final dt = DateTime.fromMillisecondsSinceEpoch(timeInMs);
    final now = DateTime.now();

    // Check if the date is absurdly far in the future (e.g. wrong scaling)
    if (dt.year > now.year + 1) return "Invalid Date";

    final diff = now.difference(dt);

    if (diff.inMinutes < 1) {
      return "Just now";
    }
    if (diff.inMinutes < 60) {
      return "${diff.inMinutes}m ago";
    }
    if (diff.inHours < 24) {
      return "${diff.inHours}h ago";
    }
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder<bool>(
          stream: iotService.onlineStatusStream,
          initialData: false,
          builder: (context, onlineSnap) {
            final bool isOnline = onlineSnap.data ?? false;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: isOnline
                    ? Colors.greenAccent.withValues(alpha: 0.1)
                    : Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isOnline
                      ? Colors.greenAccent.withValues(alpha: 0.3)
                      : Colors.redAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isOnline ? Icons.wifi : Icons.wifi_off,
                        color: isOnline ? Colors.greenAccent : Colors.redAccent,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isOnline ? "System Online" : "System Offline",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            isOnline
                                ? "Connected to Hub"
                                : "Last seen > 2 min ago",
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // LAST RUN DISPLAY (With Fallback Logic)
                  StreamBuilder<DatabaseEvent>(
                    stream: iotService.lastWateredStream,
                    builder: (context, waterSnap) {
                      // 1. Try fetching official "Last Watered" time (from ESP)
                      int? waterTs;
                      if (waterSnap.hasData &&
                          waterSnap.data!.snapshot.value != null) {
                        final val = waterSnap.data!.snapshot.value;
                        if (val is int)
                          waterTs = val;
                        else if (val is String)
                          waterTs = int.tryParse(val);
                      }

                      // 2. Fetch "Last Requested" time (from App) as fallback
                      return StreamBuilder<DatabaseEvent>(
                        stream: iotService.requestTimeStream,
                        builder: (context, reqSnap) {
                          int? reqTs;
                          if (reqSnap.hasData &&
                              reqSnap.data!.snapshot.value != null) {
                            final val = reqSnap.data!.snapshot.value;
                            if (val is int)
                              reqTs = val;
                            else if (val is String)
                              reqTs = int.tryParse(val);
                          }

                          // LOGIC: Prefer 'Watered' time if it looks valid (> 2020).
                          // Otherwise, use 'Requested' time if valid.
                          String timeText = "Never";

                          // 1600000000 is ~Year 2020 in seconds
                          if (waterTs != null && waterTs > 1600000000) {
                            timeText = _formatTimestamp(waterTs);
                          } else if (reqTs != null && reqTs > 1600000000) {
                            // If falling back to request time, append "(Req)" so user knows it's an estimate
                            timeText = "${_formatTimestamp(reqTs)} (Req)";
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "LAST RUN",
                                style: GoogleFonts.poppins(
                                  color: Colors.white38,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                timeText,
                                style: GoogleFonts.poppins(
                                  color: Colors.cyanAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
