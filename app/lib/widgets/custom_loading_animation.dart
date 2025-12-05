import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class CustomLoadingAnimation extends StatelessWidget {
  final double size;

  const CustomLoadingAnimation({
    super.key,
    this.size = 50,
  }); // Default size 50 is better for buttons

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LoadingAnimationWidget.staggeredDotsWave(
        color: Colors.cyanAccent,
        size: size,
      ),
    );
  }
}
