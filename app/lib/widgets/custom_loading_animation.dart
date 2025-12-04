import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class CustomLoadingAnimation extends StatelessWidget {
  final double size;

  const CustomLoadingAnimation({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return LoadingAnimationWidget.staggeredDotsWave(
      // Use Cyan/Green from your theme, or fallback to primary
      color: Colors.cyanAccent,
      size: size,
    );
  }
}
