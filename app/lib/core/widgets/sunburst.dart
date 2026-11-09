import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The "sunburst" decoration from the Figma kit: a very thick circle stroke
/// with a short dash pattern, which renders as radial wedges.
///
/// Drawn in code because SVG `stroke-dasharray` isn't rendered reliably by
/// flutter_svg. Geometry matches the SVG (centre, radius, stroke width,
/// dash/gap measured along the circle at [radius]).
class Sunburst extends StatelessWidget {
  const Sunburst({
    super.key,
    required this.radius,
    required this.strokeWidth,
    required this.dash,
    this.color,
    this.gradient,
    this.progress = 1,
  });

  final double radius;
  final double strokeWidth;
  final double dash;
  final Color? color;
  final Gradient? gradient;

  /// 0..1: fraction of wedges drawn (for the splash intro animation).
  final double progress;

  double get outer => radius + strokeWidth / 2;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(outer * 2),
      painter: _SunburstPainter(this),
    );
  }
}

class _SunburstPainter extends CustomPainter {
  _SunburstPainter(this.s);
  final Sunburst s;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: c, radius: s.radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.strokeWidth
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;
    if (s.gradient != null) {
      paint.shader = s.gradient!.createShader(
        Rect.fromCircle(center: c, radius: s.outer),
      );
    } else {
      paint.color = s.color ?? Colors.black;
    }
    final step = (s.dash * 2) / s.radius; // dash + equal gap, in radians
    final sweep = s.dash / s.radius;
    final count = (2 * math.pi / step).floor();
    final drawn = (count * s.progress.clamp(0, 1)).round();
    final path = Path();
    for (var i = 0; i < drawn; i++) {
      path.addArc(rect, -math.pi / 2 + i * step, sweep);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SunburstPainter old) =>
      old.s.progress != s.progress ||
      old.s.radius != s.radius ||
      old.s.color != s.color;
}
