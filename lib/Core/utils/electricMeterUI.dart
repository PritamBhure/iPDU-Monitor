
// --- CUSTOM PAINTER FOR SPEEDOMETER (No External Package Needed) ---
import 'dart:math';

import 'package:flutter/material.dart';

// --- GAUGE PAINTER ---
class GaugePainter extends CustomPainter {
  final double value;
  final double maxValue;
  final Color color;

  GaugePainter({required this.value, required this.maxValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    const startAngle = 135 * pi / 180;
    const sweepAngle = 270 * pi / 180;

    // Background Arc
    final bgPaint = Paint()..color = Colors.white10..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = 10;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, bgPaint);

    // Foreground Arc (Animated Value)
    double pct = (value / maxValue).clamp(0.0, 1.0);
    final activePaint = Paint()..color = color..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = 10..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle * pct, false, activePaint);

    // Needle Indicator
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(startAngle + (sweepAngle * pct));
    canvas.drawCircle(Offset(radius, 0), 4, Paint()..color = Colors.white);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GaugePainter oldDelegate) => oldDelegate.value != value || oldDelegate.color != color;
}