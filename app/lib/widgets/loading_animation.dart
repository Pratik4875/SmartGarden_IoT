import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class EcoLoader extends StatelessWidget {
  final double size;
  final Color color;

  const EcoLoader({
    super.key,
    this.size = 50.0,
    this.color = Colors.greenAccent,
  });

  @override
  Widget build(BuildContext context) {
    // Choose a professional animation style
    return SpinKitRipple(color: color, size: size, borderWidth: 3.0);
  }
}
