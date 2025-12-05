import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/iot_service.dart';
import 'package:firebase_database/firebase_database.dart';

class StatusHeader extends StatelessWidget {
  final IoTService iotService;

  const StatusHeader({super.key, required this.iotService});

  String _formatTimestamp(int timestamp) {
    // FIX: Filter out 0 or "epoch 0" timestamps
    if (timestamp < 1600000000) return "Never";

    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
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

                  // LAST RUN DISPLAY
                  StreamBuilder<DatabaseEvent>(
                    stream: iotService.lastWateredStream,
                    builder: (context, waterSnap) {
                      String lastRun = "Never";
                      if (waterSnap.hasData &&
                          waterSnap.data!.snapshot.value != null) {
                        final val = waterSnap.data!.snapshot.value;
                        if (val is int) {
                          lastRun = _formatTimestamp(val);
                        } else if (val is String) {
                          lastRun = _formatTimestamp(int.tryParse(val) ?? 0);
                        }
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
                            lastRun,
                            style: GoogleFonts.poppins(
                              color: Colors.cyanAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
