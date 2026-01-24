import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/iot_service.dart';

// Redefining as Stateful for better list management
class ScheduleList extends StatefulWidget {
  final IoTService iotService;
  const ScheduleList({super.key, required this.iotService});

  @override
  State<ScheduleList> createState() => _ScheduleListState();
}

class _ScheduleListState extends State<ScheduleList> {
  List<String> _currentSchedules = [];

  void _showOfflineMessage() {
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
      stream: widget.iotService.onlineStatusStream,
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
                        color: isOnline ? Colors.cyanAccent : Colors.grey,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Watering Times (Max 5)",
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle, color: isOnline ? Colors.cyanAccent : Colors.grey.shade600, size: 28),
                    onPressed: isOnline ? _handleAddNew : _showOfflineMessage,
                  ),
                ],
              ),
              const SizedBox(height: 15),

              StreamBuilder<DatabaseEvent>(
                stream: widget.iotService.schedulesStream,
                builder: (context, snapshot) {
                  // Keep local list updated
                  if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                     final val = snapshot.data!.snapshot.value;
                     if (val is List) {
                        _currentSchedules = val.map((e) => e.toString()).toList();
                     } else {
                        // Handle generic map case or empty
                         _currentSchedules = [];
                     }
                  } else {
                      // Fix: If null (deleted), clear the list
                      _currentSchedules = [];
                  }

                  if (_currentSchedules.isEmpty) return _buildEmptyState();

                  return Column(
                    children: _currentSchedules.asMap().entries.map((entry) {
                      return _buildScheduleItem(entry.key, entry.value, isOnline);
                    }).toList(),
                  );
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

  Widget _buildScheduleItem(int index, String rawStr, bool isOnline) {
    // rawStr format: "08:00" or "08:00|15"
    String timePart = rawStr;
    String durationPart = "15"; // Default

    if (rawStr.contains("|")) {
       final parts = rawStr.split("|");
       timePart = parts[0];
       if (parts.length > 1) durationPart = parts[1];
    }

    String displayTime = timePart;
    try {
      int h = int.parse(timePart.split(":")[0]);
      int m = int.parse(timePart.split(":")[1]);
      final dt = DateTime(2024, 1, 1, h, m);
      displayTime = DateFormat.jm().format(dt);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                displayTime,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.cyanAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text("$durationPart s", style: GoogleFonts.poppins(color: Colors.cyanAccent, fontSize: 12)),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: isOnline ? Colors.redAccent : Colors.grey.shade800),
            onPressed: isOnline
                ? () {
                    List<String> newList = List.from(_currentSchedules);
                    newList.removeAt(index);
                    widget.iotService.saveScheduleList(newList);
                  }
                : _showOfflineMessage,
          ),
        ],
      ),
    );
  }

  void _handleAddNew() async {
    if (_currentSchedules.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Max 5 schedules reached! Delete one first."), backgroundColor: Colors.red),
      );
      return;
    }

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

    if (picked == null || !mounted) return;

    _showDurationDialog(picked);
  }

  void _showDurationDialog(TimeOfDay picked) {
    TextEditingController durController = TextEditingController(text: "15");
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: Text("Set Duration (Sec)", style: GoogleFonts.poppins(color: Colors.white)),
        content: TextField(
          controller: durController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "Seconds",
            labelStyle: TextStyle(color: Colors.cyanAccent),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
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
                if (dur <= 0) dur = 5;
                Navigator.pop(context);
                _saveNewSchedule(picked, dur);
             },
             child: const Text("SAVE", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _saveNewSchedule(TimeOfDay picked, int duration) {
    String h = picked.hour.toString().padLeft(2, '0');
    String m = picked.minute.toString().padLeft(2, '0');
    
    // FORMAT: HH:mm|SS
    String newEntry = "$h:$m|$duration";
    
    // Check for duplicate TIMES (ignore duration)
    for (var s in _currentSchedules) {
       if (s.startsWith("$h:$m")) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Duplicate time!"), backgroundColor: Colors.red),
          );
          return;
       }
    }

    List<String> newList = List.from(_currentSchedules);
    newList.add(newEntry);
    newList.sort();
    
    widget.iotService.saveScheduleList(newList);
  }
}
