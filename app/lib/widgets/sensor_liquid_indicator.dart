import 'package:flutter/material.dart';
import 'dart:math';

class SensorLiquidIndicator extends StatefulWidget {
  final double value;
  final double maxValue;
  final Color baseColor; // Renamed from color to baseColor
  final double size;

  const SensorLiquidIndicator({
    super.key,
    required this.value,
    required this.maxValue,
    required this.baseColor,
    this.size = 100,
  });

  @override
  State<SensorLiquidIndicator> createState() => _SensorLiquidIndicatorState();
}

class _SensorLiquidIndicatorState extends State<SensorLiquidIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- DYNAMIC COLOR & ICON LOGIC ---
    Color dynamicColor = widget.baseColor;
    IconData? alertIcon;

    // Calculate percentage (0.0 to 1.0)
    double percentage = (widget.value / widget.maxValue).clamp(0.0, 1.0);

    if (percentage <= 0.3) {
      // DRY / CRITICAL
      dynamicColor = Colors.redAccent;
      alertIcon = Icons.priority_high_rounded; // Exclamation mark
    } else if (percentage <= 0.6) {
      // MOIST / WARNING
      dynamicColor = Colors.orangeAccent;
    } else {
      // WET / GOOD
      // Keep the passed baseColor (usually Cyan/Blue)
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          height: widget.size,
          width: widget.size,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              // Liquid Fill
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: CustomPaint(
                  painter: _LiquidPainter(
                    widget.value,
                    widget.maxValue,
                    dynamicColor, // Use calculated color
                    _controller.value,
                  ),
                ),
              ),

              // Radial Ring
              CustomPaint(
                painter: _RadialProgressPainter(
                  value: widget.value,
                  maxValue: widget.maxValue,
                  color: dynamicColor, // Use calculated color
                ),
              ),

              // ALERT ICON (Only shows if critical)
              if (alertIcon != null)
                Icon(
                  alertIcon,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: widget.size * 0.4, // Scale relative to container
                  shadows: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 10,
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

class _RadialProgressPainter extends CustomPainter {
  final double value;
  final double maxValue;
  final Color color;

  _RadialProgressPainter({
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double diameter = min(size.height, size.width);
    final double radius = diameter / 2;
    final double centerX = radius;
    final double centerY = radius;

    const double strokeWidth = 6;

    final Paint trackPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Paint progressPaint = Paint()
      ..shader =
          SweepGradient(
            colors: [
              color.withValues(alpha: 0.5),
              color,
              color.withValues(alpha: 0.8),
            ],
            startAngle: -pi / 2,
            endAngle: 3 * pi / 2,
            tileMode: TileMode.repeated,
          ).createShader(
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LiquidPainter extends CustomPainter {
  final double value;
  final double maxValue;
  final Color color;
  final double animationValue;

  _LiquidPainter(this.value, this.maxValue, this.color, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    double diameter = min(size.height, size.width);
    double radius = diameter / 2;

    double fillPercentage = (value / maxValue).clamp(0.0, 1.0);
    double pointY = diameter - (diameter * fillPercentage);

    Path path = Path();
    path.moveTo(0, pointY);

    double amplitude = 5;
    double period = 1.0;
    double phaseShift = animationValue * 2 * pi;

    for (double i = 0; i <= diameter; i++) {
      path.lineTo(
        i,
        pointY + amplitude * sin((i / diameter * 2 * pi * period) + phaseShift),
      );
    }

    path.lineTo(diameter, diameter);
    path.lineTo(0, diameter);
    path.close();

    Paint paint = Paint()
      ..shader =
          LinearGradient(
            colors: [
              color.withValues(alpha: 0.6),
              color.withValues(alpha: 0.3),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(
            Rect.fromCircle(center: Offset(radius, radius), radius: radius),
          )
      ..style = PaintingStyle.fill;

    Path circleClip = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(radius, radius),
          width: diameter,
          height: diameter,
        ),
      );
    canvas.clipPath(circleClip, doAntiAlias: true);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
