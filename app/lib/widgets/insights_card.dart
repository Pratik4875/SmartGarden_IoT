import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/iot_service.dart';

class InsightsCard extends StatelessWidget {
  final IoTService iotService;

  const InsightsCard({super.key, required this.iotService});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: iotService.getDailyInsights(),
      builder: (context, snapshot) {
        double minT = 0, maxT = 0;
        if (snapshot.hasData) {
          minT = snapshot.data!['minTemp'] ?? 0;
          maxT = snapshot.data!['maxTemp'] ?? 0;
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blueAccent.withValues(alpha: 0.2),
                Colors.purpleAccent.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.amberAccent),
                  const SizedBox(width: 10),
                  Text(
                    "24h Insights",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn(
                    "Night Low",
                    "${minT.toStringAsFixed(1)}°C",
                    Icons.bedtime,
                    Colors.blue,
                  ),
                  Container(width: 1, height: 40, color: Colors.white10),
                  _buildStatColumn(
                    "Day Peak",
                    "${maxT.toStringAsFixed(1)}°C",
                    Icons.wb_sunny,
                    Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 5),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}
