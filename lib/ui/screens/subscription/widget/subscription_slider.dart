import 'dart:math';

import 'package:flutter/material.dart';

class SubscriptionSlider extends StatefulWidget {
  const SubscriptionSlider({
    required this.itemCount,
    required this.itemBuilder,
    super.key,
  });

  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;

  @override
  State<SubscriptionSlider> createState() => _SubscriptionSliderState();
}

class _SubscriptionSliderState extends State<SubscriptionSlider> {
  final PageController _controller = PageController(viewportFraction: .8);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      child: FractionallySizedBox(
        heightFactor: .8,
        child: PageView.builder(
          controller: _controller,
          itemBuilder: (context, index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                double itemOffset = 0.0;

                final position = _controller.position;
                if (position.hasPixels && position.hasContentDimensions) {
                  itemOffset = _controller.page! - index;
                } else {
                  itemOffset = (_controller.initialPage - index).toDouble();
                }
                final distortionRatio = (1 - (itemOffset.abs() * 0.7)).clamp(
                  0.0,
                  1.0,
                );
                final distortionValue = Curves.easeOut.transform(
                  distortionRatio,
                );

                return Transform.scale(
                  //to limit minimum size to 0.2
                  scale: max(distortionValue, 0.9),
                  child: widget.itemBuilder(context, index),
                );
              },
            );
          },
          itemCount: widget.itemCount,
        ),
      ),
    );
  }
}
