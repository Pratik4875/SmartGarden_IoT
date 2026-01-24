import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../services/iot_service.dart';

class PumpControl extends StatefulWidget {
  final IoTService iotService;

  const PumpControl({super.key, required this.iotService});

  @override
  State<PumpControl> createState() => _PumpControlState();
}

class _PumpControlState extends State<PumpControl> {
  bool _isLocked = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  StreamSubscription<DatabaseEvent>? _pumpSubscription;
  bool? _lastPumpState;

  @override
  void initState() {
    super.initState();
    _subscribeToPumpStatus();
  }

  void _subscribeToPumpStatus() {
    _pumpSubscription = widget.iotService.pumpStatusStream.listen((event) {
      if (event.snapshot.value == null) return;
      
      bool currentPumpState = event.snapshot.value == true;
      
      // Check for ON -> OFF transition
      if (_lastPumpState == true && currentPumpState == false) {
           _triggerCooldown();
      }
      
      _lastPumpState = currentPumpState;
    });
  }

  void _triggerCooldown() {
    setState(() {
      _isLocked = true;
      _cooldownSeconds = 5;
    });

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _cooldownSeconds--;
      });

      if (_cooldownSeconds <= 0) {
        timer.cancel();
        setState(() {
          _isLocked = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _pumpSubscription?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _showOfflineMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Device is offline. Cannot send control commands."),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Outer StreamBuilder checks device online status
    return StreamBuilder<bool>(
      stream: widget.iotService.onlineStatusStream,
      initialData: false,
      builder: (context, onlineSnap) {
        final bool isOnline = onlineSnap.data ?? false;

        // Inner StreamBuilder checks pump status
        return StreamBuilder<DatabaseEvent>(
          stream: widget.iotService.pumpStatusStream,
          builder: (context, snapshot) {
            bool isPumpOn = false;
            if (snapshot.hasData && snapshot.data!.snapshot.value == true) {
              isPumpOn = true;
            }

            // Determine if control is available
            final bool isControlAvailable = isOnline && !_isLocked;

            // Active = Cyan/Blue Gradient
            // Inactive = Dark Grey
            // Locked = Grey/Red hint
            List<Color> gradientColors;
             if (_isLocked) {
                gradientColors = [Colors.grey.shade700, Colors.grey.shade800];
             } else if (isPumpOn && isOnline) {
                gradientColors = [Colors.cyanAccent, Colors.blueAccent];
             } else if (isOnline) {
                gradientColors = [Colors.grey.shade800, Colors.grey.shade900];
             } else {
                gradientColors = [Colors.black54, Colors.black87]; // Offline
             }

            final textColor = (isPumpOn && isOnline && !_isLocked)
                ? Colors.black
                : (isOnline && !_isLocked)
                ? Colors.white54
                : Colors.white38;

            final List<BoxShadow> shadows = (isPumpOn && isOnline && !_isLocked)
                ? [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [
                    const BoxShadow(
                      color: Colors.black54,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ];

            String buttonText;
            if (!isOnline) {
              buttonText = "DEVICE OFFLINE";
            } else if (_isLocked) {
              buttonText = "COOLING DOWN ($_cooldownSeconds)";
            } else if (isPumpOn) {
              buttonText = "PUMP ACTIVE";
            } else {
              buttonText = "START PUMP";
            }
            
            IconData icon;
            if (!isOnline) {
               icon = Icons.power_off;
            } else if (_isLocked) {
               icon = Icons.lock_clock;
            } else if (isPumpOn) {
               icon = Icons.water_drop;
            } else {
               icon = Icons.water_drop_outlined;
            }

            return GestureDetector(
              key: const Key('pumpControl'), 
              // Block the onTap if offline or locked
              onTap: isControlAvailable
                  ? () => widget.iotService.togglePump(!isPumpOn)
                  : () {
                     if (!isOnline) _showOfflineMessage(context);
                     // If locked, do nothing (or show toast?)
                  },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: shadows,
                  border: (isPumpOn && isControlAvailable)
                      ? null
                      : Border.all(color: Colors.white10, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: textColor,
                      size: 32,
                    ),
                    const SizedBox(width: 15),
                    Text(
                      buttonText,
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
