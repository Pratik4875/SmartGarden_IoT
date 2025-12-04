import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/iot_service.dart';

class SchedulerCard extends StatefulWidget {
  final IoTService iotService;
  const SchedulerCard({super.key, required this.iotService});

  @override
  State<SchedulerCard> createState() => _SchedulerCardState();
}

class _SchedulerCardState extends State<SchedulerCard> {
  final TextEditingController _durationController = TextEditingController();

  bool _isEnabled = false;
  String _timeUtc = "00:00";
  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    // Listen to Duration Stream to populate initial value
    widget.iotService.scheduleDurationStream.listen((event) {
      if (mounted && event.snapshot.value != null) {
        // Prevent overwriting while user is typing
        if (_isInit) {
          _durationController.text = event.snapshot.value.toString();
          _isInit = false;
        }
      }
    });
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  // Helper to validate and save
  void _validateAndSave(String value) {
    int? dur = int.tryParse(value);

    // STRICT VALIDATION
    if (dur == null || dur <= 0) {
      // Show Error immediately
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "⚠️ Invalid Duration: Please enter a whole number (e.g., 5, 15)",
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return; // Do NOT save to DB
    }

    // If valid, save
    widget.iotService.setSchedule(_isEnabled, null, dur);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ Saved duration: ${dur}s"),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.cyanAccent.withValues(alpha: 0.1),
        ), // Subtle border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header & Toggle Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.access_time_filled,
                    color: Colors.cyanAccent,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Daily Schedule",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              StreamBuilder<DatabaseEvent>(
                stream: widget.iotService.scheduleEnabledStream,
                builder: (context, snapshot) {
                  _isEnabled =
                      (snapshot.hasData &&
                      snapshot.data!.snapshot.value == true);
                  return Switch(
                    value: _isEnabled,
                    activeTrackColor: Colors.cyanAccent, // CYAN
                    thumbColor: WidgetStateProperty.all(
                      Colors.black,
                    ), // BLACK KNOB
                    onChanged: (val) {
                      // Also validate before toggling ON
                      int? dur = int.tryParse(_durationController.text);
                      if (dur == null || dur <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "⚠️ Fix Duration first: Enter a whole number.",
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return; // Block toggle
                      }

                      widget.iotService.setSchedule(val, null, dur);
                    },
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 2. Time Display & Edit Button
          StreamBuilder<DatabaseEvent>(
            stream: widget.iotService.scheduleTimeStream,
            builder: (context, snapshot) {
              String displayTime = "Not Set";
              if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                _timeUtc = snapshot.data!.snapshot.value.toString();
                try {
                  int h = int.parse(_timeUtc.split(":")[0]);
                  int m = int.parse(_timeUtc.split(":")[1]);
                  DateTime now = DateTime.now().toUtc();
                  // Create a DateTime object in UTC
                  DateTime utcDate = DateTime.utc(
                    now.year,
                    now.month,
                    now.day,
                    h,
                    m,
                  );
                  // Convert to Local (Mumbai)
                  displayTime = DateFormat.jm().format(utcDate.toLocal());
                } catch (e) {
                  displayTime = "Error";
                }
              }

              return Row(
                children: [
                  Text(
                    displayTime,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.edit, color: Colors.cyanAccent),
                    label: Text(
                      "CHANGE",
                      style: GoogleFonts.poppins(color: Colors.cyanAccent),
                    ),
                    onPressed: () async {
                      TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        final now = DateTime.now();
                        DateTime localDT = DateTime(
                          now.year,
                          now.month,
                          now.day,
                          picked.hour,
                          picked.minute,
                        );

                        // Validate current duration text before saving time
                        int? dur = int.tryParse(_durationController.text);
                        if (dur == null || dur <= 0) {
                          // Default to 15 if invalid, but ideally we warn
                          dur = 15;
                        }
                        widget.iotService.setSchedule(true, localDT, dur);
                      }
                    },
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 10),

          // 3. Duration Input Field
          TextField(
            controller: _durationController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: false,
            ), // Hint to keyboard
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Run Duration (Seconds)",
              labelStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(
                Icons.timer_outlined,
                color: Colors.cyanAccent,
              ),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.cyanAccent),
              ),
            ),
            onSubmitted: (value) {
              _validateAndSave(value); // Calls strict validation
            },
          ),
        ],
      ),
    );
  }
}
