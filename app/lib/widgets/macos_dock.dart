import 'dart:ui';
import 'package:flutter/material.dart';

class MacosDock<T extends Object> extends StatefulWidget {
  const MacosDock({
    super.key,
    this.items = const [],
    required this.builder,
    this.onItemTap,
  });

  final List<T> items;
  final Widget Function(T item, double scale) builder;
  final void Function(T item)? onItemTap;

  @override
  State<MacosDock<T>> createState() => MacosDockState<T>();
}

class MacosDockState<T extends Object> extends State<MacosDock<T>> {
  late final List<T> _items = widget.items.toList();
  int? _hoveredIndex;
  int? _draggedIndex;

  double calculateValue({
    required int index,
    required double initialValue,
    required double maxValue,
    required double nonHoveredMaxValue,
  }) {
    late final double finalValue;

    if (_hoveredIndex == null) {
      return initialValue;
    }

    final distance = (_hoveredIndex! - index).abs();
    final itemsAffected = _items.length;

    if (distance == 0) {
      finalValue = maxValue;
    } else if (distance == 1) {
      finalValue = lerpDouble(initialValue, maxValue, 0.5)!;
    } else if (distance == 2) {
      finalValue = lerpDouble(initialValue, maxValue, 0.25)!;
    } else if (distance < 3 && distance <= itemsAffected) {
      finalValue = lerpDouble(initialValue, nonHoveredMaxValue, .15)!;
    } else {
      finalValue = initialValue;
    }
    return finalValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.black54,
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            // FIXED: Replaced withOpacity(0.5) -> withValues(alpha: 0.5)
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          final calculatedSize = calculateValue(
            index: index,
            initialValue: 48,
            maxValue: 64,
            nonHoveredMaxValue: 36,
          );

          // Gap Logic
          final bool isHoveredDropTarget =
              _draggedIndex != null && _hoveredIndex == index;

          return GestureDetector(
            onTap: () => widget.onItemTap?.call(item),
            child: DragTarget<T>(
              onAcceptWithDetails: (droppedItem) {
                setState(() {
                  final draggedIndex = _items.indexOf(droppedItem.data);
                  if (draggedIndex != -1) {
                    _items.removeAt(draggedIndex);
                    _items.insert(index, droppedItem.data);
                  }
                  _draggedIndex = null;
                  _hoveredIndex = null;
                });
              },
              onWillAcceptWithDetails: (droppedItem) {
                final draggedIndex = _items.indexOf(droppedItem.data);
                setState(() {
                  _hoveredIndex = index;
                  _draggedIndex = draggedIndex;
                });
                return true;
              },
              onLeave: (_) {
                setState(() {
                  _hoveredIndex = null;
                  _draggedIndex = null;
                });
              },
              builder: (context, candidateData, rejectedData) {
                return Draggable<T>(
                  data: item,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Transform.scale(
                      scale: 1.2,
                      child: widget.builder(item, calculatedSize / 48),
                    ),
                  ),
                  childWhenDragging: const PlaceholderWidget(),
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _hoveredIndex = index),
                    onExit: (_) => setState(() => _hoveredIndex = null),
                    child: AnimatedContainer(
                      duration: Durations.short3,
                      margin: EdgeInsets.symmetric(
                        horizontal: isHoveredDropTarget ? 24 : 6,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 36,
                        maxWidth: calculatedSize,
                        maxHeight: calculatedSize,
                      ),
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          calculateValue(
                            index: index,
                            initialValue: 0,
                            maxValue: -10,
                            nonHoveredMaxValue: -2,
                          ),
                        ),
                        child: widget.builder(item, calculatedSize / 48),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class PlaceholderWidget extends StatelessWidget {
  const PlaceholderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      duration: Durations.medium2,
      tween: Tween<double>(begin: 48, end: 0),
      builder: (BuildContext context, double value, Widget? child) {
        return SizedBox(width: value, height: value);
      },
    );
  }
}
