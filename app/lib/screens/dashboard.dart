import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ota_update/ota_update.dart';
import '../services/iot_service.dart';
import 'login_screen.dart';
import 'history_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String databaseUrl;
  final IoTService? iotServiceOverride; // INJECTION POINT

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
    // Use the override if provided (for tests), otherwise create real service
    _iot = widget.iotServiceOverride ?? IoTService(widget.databaseUrl);
  }

  // ... (REST OF THE FILE REMAINS EXACTLY THE SAME AS BEFORE) ...
  // Paste the rest of the Dashboard code here (build method, helpers, SchedulerCard, etc.)
  // ensuring you don't lose the existing logic.

  void _runUpdate(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Starting Update... Check Notification Panel"),
      ),
    );
    _iot.updateApp().listen(
      (OtaEvent event) {
        print("OTA Status: ${event.status} : ${event.value}");
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Update Error: $error"),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  void _logout(BuildContext context) {
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusHeader(),
              const SizedBox(height: 30),
              _buildSensorGrid(),
              const SizedBox(height: 30),
              SchedulerCard(iotService: _iot),
              const SizedBox(height: 30),
              _buildPumpControl(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return StreamBuilder<DatabaseEvent>(
      stream: _iot.lastWateredStream,
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
        return Column(
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
        );
      },
    );
  }

  Widget _buildSensorGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1.5,
      children: [
        _sensorCard("Temperature", _iot.tempStream, "°C", Colors.orange),
        _sensorCard("Humidity", _iot.humidityStream, "%", Colors.blue),
        _sensorCard("Soil Moisture", _iot.soilStream, "%", Colors.green),
      ],
    );
  }

  Widget _sensorCard(
    String title,
    Stream<DatabaseEvent> stream,
    String unit,
    Color color,
  ) {
    return StreamBuilder<DatabaseEvent>(
      stream: stream,
      builder: (context, snapshot) {
        String value = "--";
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          value = snapshot.data!.snapshot.value.toString();
        }
        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.circle, size: 10, color: color),
              Text(
                "$value$unit",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPumpControl() {
    return StreamBuilder<DatabaseEvent>(
      stream: _iot.pumpStatusStream,
      builder: (context, snapshot) {
        bool isPumpOn = false;
        if (snapshot.hasData && snapshot.data!.snapshot.value == true) {
          isPumpOn = true;
        }

        return GestureDetector(
          onTap: () => _iot.togglePump(!isPumpOn),
          child: Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              color: isPumpOn ? Colors.redAccent : Colors.greenAccent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (isPumpOn ? Colors.red : Colors.green).withOpacity(
                    0.4,
                  ),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Text(
                isPumpOn ? "STOP PUMP" : "START PUMP",
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Daily Schedule",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              StreamBuilder<DatabaseEvent>(
                stream: widget.iotService.scheduleEnabledStream,
                builder: (context, snapshot) {
                  _isEnabled =
                      (snapshot.hasData &&
                      snapshot.data!.snapshot.value == true);
                  return Switch(
                    value: _isEnabled,
                    activeColor: Colors.greenAccent,
                    onChanged: (val) {
                      int dur = int.tryParse(_durationController.text) ?? 15;
                      widget.iotService.setSchedule(val, null, dur);
                    },
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 10),

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
                  DateTime utcDate = DateTime.utc(
                    now.year,
                    now.month,
                    now.day,
                    h,
                    m,
                  );
                  displayTime = DateFormat.jm().format(utcDate.toLocal());
                } catch (e) {
                  displayTime = "Error";
                }
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    displayTime,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[300],
                      fontSize: 24,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.edit, color: Colors.greenAccent),
                    label: Text(
                      "EDIT TIME",
                      style: GoogleFonts.poppins(color: Colors.greenAccent),
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
                        int dur = int.tryParse(_durationController.text) ?? 15;
                        widget.iotService.setSchedule(true, localDT, dur);
                      }
                    },
                  ),
                ],
              );
            },
          ),

          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Duration (Seconds)",
                labelStyle: const TextStyle(color: Colors.grey),
                hintText: "e.g., 15",
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.greenAccent),
                ),
                prefixIcon: const Icon(Icons.timer, color: Colors.greenAccent),
                suffixText: "sec",
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
              ),
              onSubmitted: (value) {
                int dur = int.tryParse(value) ?? 15;
                widget.iotService.setSchedule(_isEnabled, null, dur);
              },
            ),
          ),
        ],
      ),
    );
  }
}
