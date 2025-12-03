import 'dart:math';

import 'package:flutter/material.dart';

/// Painter for cutting a notch at the bottom of a widget.
///
/// This file is committed **only as a reference** so that it can be
/// retrieved from GitHub if needed in the future.
///
/// ⚠️ It will be removed before the next release to avoid unused files.
///
// Todo(rio): Remove this before the update
class OnboardingBackgroundPainter extends CustomPainter {
  OnboardingBackgroundPainter({
    required this.radius,
    double borderRadius = 15.0,
  }) : br = borderRadius;
  final double radius;
  final double br; // borderRadius

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path();

    final rect = Offset.zero & size;

    path
      ..moveTo(0, 0)
      ..lineTo(rect.right, 0)
      ..lineTo(rect.right, rect.bottom - br)
      ..relativeArcToPoint(Offset(-br, br), radius: Radius.circular(br))
      ..lineTo(rect.bottomCenter.dx + radius + br, size.height)
      ..relativeArcToPoint(Offset(-br, -br), radius: Radius.circular(br))
      ..arcTo(
        Rect.fromCircle(
          center: rect.bottomCenter.translate(0, -br),
          radius: radius,
        ),
        0,
        -pi,
        false,
      )
      ..relativeArcToPoint(Offset(-br, br), radius: Radius.circular(br))
      ..lineTo(rect.left + br, rect.bottom)
      ..relativeArcToPoint(Offset(-br, -br), radius: Radius.circular(br))
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawShadow(
      path,
      Colors.grey.withValues(alpha: 0.1),
      6.0, // Shadow radius
      true, // Whether to include the shape itself in the shadow calculation
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
