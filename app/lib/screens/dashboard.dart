import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ota_update/ota_update.dart'; // Import OTA
import '../services/iot_service.dart';

class DashboardScreen extends StatelessWidget {
  final IoTService _iot = IoTService();

  DashboardScreen({super.key});

  // Function to trigger update
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: Text(
          'Smart Garden',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          // UPDATE BUTTON
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
              _buildSchedulerCard(context),
              const SizedBox(height: 30),
              _buildPumpControl(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ... (Keep _buildStatusHeader, _buildSensorGrid, _sensorCard, _buildSchedulerCard, _buildPumpControl exactly the same) ...
  // (Paste the rest of the widgets here from previous steps)
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

  Widget _buildSchedulerCard(BuildContext context) {
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
                stream: _iot.scheduleEnabledStream,
                builder: (context, snapshot) {
                  bool isEnabled = false;
                  if (snapshot.hasData &&
                      snapshot.data!.snapshot.value == true) {
                    isEnabled = true;
                  }
                  return Switch(
                    value: isEnabled,
                    activeColor: Colors.greenAccent,
                    onChanged: (val) =>
                        _iot.setSchedule(val, null), // Toggle only
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          StreamBuilder<DatabaseEvent>(
            stream: _iot.scheduleTimeStream,
            builder: (context, snapshot) {
              String displayTime = "Not Set";
              if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                // DB has UTC "HH:MM". We must convert to Local.
                String utcStr = snapshot.data!.snapshot.value.toString();
                try {
                  int h = int.parse(utcStr.split(":")[0]);
                  int m = int.parse(utcStr.split(":")[1]);
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
                      "EDIT",
                      style: GoogleFonts.poppins(color: Colors.greenAccent),
                    ),
                    onPressed: () async {
                      TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        // Create a DateTime to help with conversion
                        final now = DateTime.now();
                        DateTime localDT = DateTime(
                          now.year,
                          now.month,
                          now.day,
                          picked.hour,
                          picked.minute,
                        );
                        _iot.setSchedule(true, localDT); // Save and Enable
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
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
