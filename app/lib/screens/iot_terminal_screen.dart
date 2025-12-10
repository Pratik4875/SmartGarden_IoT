import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // For timestamps
import '../services/iot_service.dart';

class IoTTerminalScreen extends StatefulWidget {
  final IoTService iotService;
  const IoTTerminalScreen({super.key, required this.iotService});

  @override
  State<IoTTerminalScreen> createState() => _IoTTerminalScreenState();
}

class _IoTTerminalScreenState extends State<IoTTerminalScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final List<String> _logs = []; // Local log history
  final ScrollController _scrollController = ScrollController();

  void _send() {
    if (_ctrl.text.trim().isEmpty) return;

    String cmd = _ctrl.text.trim();

    // 1. Send to Firebase
    widget.iotService.setGenericData('terminal/input', cmd);

    // 2. Add to Local Log (Visual Feedback)
    String timestamp = DateFormat('HH:mm:ss').format(DateTime.now());
    setState(() {
      _logs.insert(0, "[$timestamp] TX > $cmd");
    });

    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D), // Cyberpunk Black
      appBar: AppBar(
        title: Text(
          "SYSTEM TERMINAL",
          style: GoogleFonts.robotoMono(
            color: Colors.greenAccent,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.greenAccent),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => setState(() => _logs.clear()),
            tooltip: "Clear Logs",
          ),
        ],
      ),
      body: Column(
        children: [
          // --- LOG DISPLAY AREA ---
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF121212), // Slightly lighter black
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.greenAccent.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: _logs.isEmpty
                  ? Center(
                      child: Text(
                        "READY FOR COMMANDS...",
                        style: GoogleFonts.firaCode(
                          color: Colors.greenAccent.withValues(alpha: 0.3),
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      reverse:
                          true, // Auto-scroll to bottom behavior (newest first)
                      itemCount: _logs.length,
                      itemBuilder: (ctx, i) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            _logs[i],
                            style: GoogleFonts.firaCode(
                              color: Colors.greenAccent,
                              fontSize: 14,
                              height: 1.2,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),

          // --- ROBUST INPUT BAR ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.greenAccent,
                  size: 20,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: GoogleFonts.firaCode(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    cursorColor: Colors.greenAccent,
                    decoration: InputDecoration(
                      hintText: "ENTER COMMAND...",
                      hintStyle: GoogleFonts.firaCode(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.greenAccent.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.greenAccent,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
