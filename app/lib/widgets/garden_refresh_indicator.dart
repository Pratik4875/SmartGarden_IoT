import 'package:flutter/material.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:rive/rive.dart';

class GardenRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  // The distance the user pulls to trigger the refresh (similar to video)
  static const double _indicatorSize = 150.0;

  const GardenRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      offsetToArmed: _indicatorSize,
      onRefresh: onRefresh,
      builder:
          (BuildContext context, Widget child, IndicatorController controller) {
            return Stack(
              children: [
                // 1. The Rive Animation Background
                // It stays fixed at the top but is revealed as we drag
                AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    // Hide when not pulling to save resources
                    if (controller.value == 0.0) return const SizedBox();

                    return SizedBox(
                      height: _indicatorSize * controller.value,
                      width: double.infinity,
                      child: const RiveAnimation.asset(
                        'assets/rive/refresh.riv',
                        fit: BoxFit.cover,
                        // If your Rive file has a specific state machine,
                        // you can specify it here. Otherwise, it plays the default.
                      ),
                    );
                  },
                ),

                // 2. The List Content
                // It translates (moves) down as you pull
                AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    return Transform.translate(
                      offset: Offset(0.0, _indicatorSize * controller.value),
                      child: child,
                    );
                  },
                ),
              ],
            );
          },
      child: child,
    );
  }
}
