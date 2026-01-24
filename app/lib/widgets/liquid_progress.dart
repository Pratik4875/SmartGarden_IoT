import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LiquidProgress extends StatefulWidget {
  final double value; // 0 to 100
  final double maxValue;
  final double size;

  const LiquidProgress({
    super.key,
    required this.value,
    this.maxValue = 100,
    this.size = 150,
  });

  @override
  State<LiquidProgress> createState() => _LiquidProgressState();
}

class _LiquidProgressState extends State<LiquidProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- DYNAMIC LOGIC ---
    double percentage = (widget.value / widget.maxValue).clamp(0.0, 1.0);

    // Default Colors (Blue/Cyan for Wet)
    List<Color> liquidColors = [
      const Color(0xff7639FB),
      const Color(0xff00E5FF),
    ];
    List<Color> ringColors = [const Color(0xff7639FB), const Color(0xff00E5FF)];
    IconData? statusIcon;
    String statusText = "WET";

    if (percentage <= 0.05) {
      // CRITICAL (< 5%)
      liquidColors = [Colors.red.shade900, Colors.red.shade700];
      ringColors = [Colors.red, Colors.redAccent];
      statusIcon = Icons.error_outline;
      statusText = "ERROR";
    } else if (percentage <= 0.30) {
      // DRY (< 30%)
      liquidColors = [const Color(0xffFF7A01), const Color(0xffFF0069)];
      ringColors = [Colors.orange, Colors.deepOrange];
      statusIcon = Icons.warning_amber_rounded;
      statusText = "DRY";
    } else if (percentage <= 0.70) {
      // MOIST (30-70%)
      liquidColors = [Colors.green, Colors.teal];
      ringColors = [Colors.greenAccent, Colors.tealAccent];
      statusText = "MOIST";
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              // 1. Liquid Fill
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: CustomPaint(
                  painter: LiquidPainter(
                    widget.value,
                    widget.maxValue,
                    _controller.value,
                    liquidColors,
                  ),
                ),
              ),

              // 2. Radial Ring
              CustomPaint(
                painter: RadialProgressPainter(
                  value: widget.value,
                  maxValue: widget.maxValue,
                  gradientColors: ringColors,
                ),
              ),

              // 3. Status Text & Icon Overlay
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (statusIcon != null)
                    Icon(
                      statusIcon,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 24,
                      shadows: [
                        BoxShadow(color: Colors.black45, blurRadius: 5),
                      ],
                    ),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      statusText,
                      key: ValueKey(statusText),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          const Shadow(color: Colors.black45, blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class RadialProgressPainter extends CustomPainter {
  final double value;
  final double maxValue;
  final List<Color> gradientColors;

  RadialProgressPainter({
    required this.value,
    required this.maxValue,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double diameter = min(size.height, size.width);
    final double radius = diameter / 2;
    final double centerX = radius;
    final double centerY = radius;
    const double strokeWidth = 6;

    final Paint trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final Gradient gradient = SweepGradient(
      colors: [...gradientColors, gradientColors.first],
      startAngle: -pi / 2,
      endAngle: 3 * pi / 2,
      tileMode: TileMode.clamp,
    );

    final Paint progressPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(centerX, centerY), radius, trackPaint);

    double startAngle = -pi / 2;
    double sweepAngle = 2 * pi * (value / maxValue).clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RadialProgressPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.gradientColors != gradientColors;
}

class LiquidPainter extends CustomPainter {
  final double value;
  final double maxValue;
  final double wavePhase;
  final List<Color> colors;

  LiquidPainter(this.value, this.maxValue, this.wavePhase, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    double diameter = min(size.height, size.width);
    // Removed unused 'radius' variable here

    double fillRatio = (value / maxValue).clamp(0.0, 1.0);
    double pointY = diameter - (diameter * fillRatio);

    Path path = Path();
    path.moveTo(0, pointY);

    double amplitude = 6;

    for (double i = 0; i <= diameter; i++) {
      path.lineTo(
        i,
        pointY +
            amplitude * sin((i / diameter * 2 * pi) + (wavePhase * 2 * pi)),
      );
    }

    path.lineTo(diameter, diameter);
    path.lineTo(0, diameter);
    path.close();

    Paint paint = Paint()
      ..shader = LinearGradient(
        colors: colors.map((c) => c.withValues(alpha: 0.7)).toList(),
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, diameter, diameter))
      ..style = PaintingStyle.fill;

    Path circleClip = Path()..addOval(Rect.fromLTWH(0, 0, diameter, diameter));
    canvas.clipPath(circleClip);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LiquidPainter oldDelegate) {
    return oldDelegate.wavePhase != wavePhase ||
        oldDelegate.value != value ||
        oldDelegate.colors != colors;
  }
}
