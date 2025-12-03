import 'dart:ui';

import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:flutter/material.dart';

class PageIndicator extends StatelessWidget {
  const PageIndicator({
    required this.controller,
    required this.count,
    super.key,
  });

  final PageController controller;
  final int count;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          return AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              double offset = 0.0;

              final position = controller.position;
              if (position.hasPixels && position.hasContentDimensions) {
                offset = controller.page! - index;
              } else {
                offset = (controller.initialPage - index).toDouble();
              }

              // Active ratio (1 = fully active, 0 = fully inactive)
              final activeRatio = (1 - offset.abs()).clamp(0.0, 1.0);

              // Shape morph: circle -> stadium
              final width = lerpDouble(
                8,
                24,
                Curves.decelerate.transform(activeRatio),
              )!;
              final height = 8.0;

              // Color interpolation
              final inactiveColor = context.color.territoryColor.withValues(
                alpha: .1,
              );
              final activeColor = context.color.territoryColor;

              final color = Color.lerp(
                inactiveColor,
                activeColor,
                Curves.decelerate.transform(activeRatio),
              )!;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(50), // stadium effect
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
