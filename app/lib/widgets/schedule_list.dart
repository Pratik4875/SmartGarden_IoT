//
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/iot_service.dart';

class ScheduleList extends StatelessWidget {
  final IoTService iotService;

  const ScheduleList({super.key, required this.iotService});

  void _showOfflineMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Device is offline. Cannot manage schedules."),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: iotService.onlineStatusStream,
      initialData: false,
      builder: (context, onlineSnap) {
        final bool isOnline = onlineSnap.data ?? false;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_filled,
                        color: isOnline
                            ? Colors.cyanAccent
                            : Colors.grey, // Visual indicator
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Schedules (Max 5)",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add_circle,
                      color: isOnline
                          ? Colors.cyanAccent
                          : Colors.grey.shade600, // Visual indicator
                      size: 28,
                    ),
                    // Block the onPressed if offline
                    onPressed: isOnline
                        ? () => _handleAddNew(context)
                        : () => _showOfflineMessage(context),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              StreamBuilder<DatabaseEvent>(
                stream: iotService.schedulesStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData ||
                      snapshot.data!.snapshot.value == null) {
                    return _buildEmptyState();
                  }

                  List<dynamic> rawList = [];
                  final value = snapshot.data!.snapshot.value;

                  if (value is List) {
                    rawList = value;
                  } else if (value is Map) {
                    var sortedKeys = value.keys.toList()..sort();
                    for (var key in sortedKeys) {
                      rawList.add(value[key]);
                    }
                  }

                  List<Widget> activeWidgets = [];
                  for (int i = 0; i < rawList.length; i++) {
                    var item = rawList[i];
                    if (item != null &&
                        item is Map &&
                        item['enabled'] == true) {
                      activeWidgets.add(
                        _buildScheduleItem(context, i, item, isOnline),
                      ); // Pass online status
                    }
                  }

                  if (activeWidgets.isEmpty) return _buildEmptyState();
                  return Column(children: activeWidgets);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          "No active schedules.\nTap + to add one.",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildScheduleItem(
    BuildContext context,
    int index,
    Map item,
    bool isOnline,
  ) {
    String utcTime = item['time_utc'] ?? "00:00";
    int duration = item['duration_sec'] ?? 15;

    String displayTime = utcTime;
    try {
      int h = int.parse(utcTime.split(":")[0]);
      int m = int.parse(utcTime.split(":")[1]);
      DateTime now = DateTime.now().toUtc();
      DateTime utcDate = DateTime.utc(now.year, now.month, now.day, h, m);
      displayTime = DateFormat.jm().format(utcDate.toLocal());
    } catch (e) {
      /* Fallback */
    }

    final bool canDelete = isOnline;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayTime,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Runs for ${duration}s",
                style: GoogleFonts.poppins(
                  color: Colors.cyanAccent,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: canDelete
                  ? Colors.redAccent
                  : Colors.grey.shade800, // Grey out if offline
            ),
            // Block deletion if offline
            onPressed: canDelete
                ? () => iotService.deleteScheduleSlot(index)
                : () => _showOfflineMessage(context),
          ),
        ],
      ),
    );
  }

  void _handleAddNew(BuildContext context) async {
    // ... (rest of _handleAddNew function remains unchanged)
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.cyanAccent,
            surface: Color(0xFF2C2C2C),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !context.mounted) return;
    _showDurationDialog(context, picked);
  }

  void _showDurationDialog(BuildContext context, TimeOfDay pickedTime) {
    // ... (rest of _showDurationDialog function remains unchanged)
    TextEditingController durController = TextEditingController(text: "15");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: Text(
          "Set Duration",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: TextField(
          controller: durController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "Seconds",
            labelStyle: TextStyle(color: Colors.cyanAccent),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.cyanAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              int dur = int.tryParse(durController.text) ?? 15;
              if (dur <= 0) dur = 15;
              Navigator.pop(context);
              _saveNewSchedule(context, pickedTime, dur);
            },
            child: const Text(
              "SAVE",
              style: TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveNewSchedule(
    BuildContext context,
    TimeOfDay time,
    int duration,
  ) async {
    // ... (rest of _saveNewSchedule function remains unchanged)
    // 1. Get current active schedules to check for duplicates
    List<dynamic> schedules = await iotService.getSchedulesOnce();

    // 2. Calculate the proposed UTC string (Validation Step)
    final now = DateTime.now();
    DateTime localDT = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    DateTime utc = localDT.toUtc();
    String proposedUtcStr =
        "${utc.hour.toString().padLeft(2, '0')}:${utc.minute.toString().padLeft(2, '0')}";

    // 3. Check for duplicates
    for (var item in schedules) {
      if (item != null && item is Map && item['enabled'] == true) {
        String existingUtc = item['time_utc'] ?? "";
        // If times match exactly in UTC, they are duplicates
        if (existingUtc == proposedUtcStr) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("⚠️ Duplicate Time! This schedule already exists."),
              backgroundColor: Colors.red,
            ),
          );
          return; // STOP HERE
        }
      }
    }

    // 4. Find empty slot
    int slotIndex = -1;
    for (int i = 0; i < 5; i++) {
      if (i >= schedules.length) {
        slotIndex = i;
        break;
      }
      var item = schedules[i];
      if (item == null || item['enabled'] == false) {
        slotIndex = i;
        break;
      }
    }

    if (!context.mounted) return;

    if (slotIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Max 5 schedules reached! Delete one first."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 5. Save (Pass Local DT, Service handles UTC conversion)
    await iotService.updateScheduleSlot(slotIndex, true, localDT, duration);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Schedule added to slot $slotIndex"),
        backgroundColor: Colors.green,
      ),
    );
  }
}
