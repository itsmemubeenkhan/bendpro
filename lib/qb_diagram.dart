import 'dart:math';
import 'package:flutter/material.dart';
import 'pro_widgets.dart';

/// Professional conduit diagram renderer — original design inspired by
/// the clarity of pro bending apps: technical drawing aesthetic with
/// highlighted bend zones, dashed bend paths, and dimension lines.
///
/// This is original code and styling — not a copy of any app's assets.
class QBDiagram extends StatelessWidget {
  final CustomPainter painter;
  final double height;

  const QBDiagram({
    super.key,
    required this.painter,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF11161D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ProTheme.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CustomPaint(
          size: Size(double.infinity, height),
          painter: painter,
        ),
      ),
    );
  }
}

/// Floating result card — label on top, big fraction value below.
/// Positioned over the diagram near the relevant measurement.
class QBResultCard extends StatelessWidget {
  final String label;
  final String value;
  final String? hint;
  final VoidCallback? onTap;

  const QBResultCard({
    super.key,
    required this.label,
    required this.value,
    this.hint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ProTheme.surface2,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ProTheme.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: ProTheme.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (hint != null)
                Text(
                  hint!,
                  style: const TextStyle(
                    color: ProTheme.textDim,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared conduit drawing: technical style with bend-zone highlights.
class QBConduit {
  static const pipeColor = Color(0xFFB8C2CC);
  static const pipeDark = Color(0xFF7A8794);
  static const bendGreen = Color(0xFF22C55E);
  static const dashColor = Color(0xFF5B8DEF);

  /// Draws the conduit body along [points].
  static void drawPipe(Canvas canvas, List<Offset> pts,
      {double w = 16}) {
    if (pts.length < 2) return;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    // Shadow/outline.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w + 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF05070A),
    );
    // Body.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = pipeColor,
    );
    // Top highlight for depth.
    final hl = Path()..moveTo(pts.first.dx, pts.first.dy - w * 0.3);
    for (var i = 1; i < pts.length; i++) {
      hl.lineTo(pts[i].dx, pts[i].dy - w * 0.3);
    }
    canvas.drawPath(
      hl,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.25
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withOpacity(0.5),
    );
  }

  /// Highlights a bend zone (segment from a to b) in green.
  static void bendZone(Canvas canvas, Offset a, Offset b,
      {double w = 16}) {
    canvas.drawLine(
      a,
      b,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.butt
        ..color = bendGreen,
    );
    canvas.drawLine(
      a,
      b,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.25
        ..strokeCap = StrokeCap.butt
        ..color = Colors.white.withOpacity(0.35),
    );
  }

  /// Dashed bend path (the arc the conduit follows).
  static void dashedArc(Canvas canvas, Offset center, double radius,
      double startAngle, double sweep) {
    final path = Path();
    const steps = 24;
    for (var i = 0; i <= steps; i++) {
      final a = startAngle + sweep * i / steps;
      final p = Offset(
        center.dx + radius * cos(a),
        center.dy + radius * sin(a),
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = dashColor
        ..strokeCap = StrokeCap.round,
    );
    // Manual dashes via path dashing.
    _drawDashed(canvas, path, dashColor);
  }

  static void _drawDashed(Canvas canvas, Path path, Color color) {
    // Draw as segments for dashed effect.
    final metrics = path.computeMetrics().toList();
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color;
    for (final m in metrics) {
      var dist = 0.0;
      while (dist < m.length) {
        final seg = m.extractPath(dist, dist + 6);
        canvas.drawPath(seg, paint);
        dist += 12;
      }
    }
  }

  /// Dashed straight line.
  static void dashedLine(Canvas canvas, Offset a, Offset b) {
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy);
    _drawDashed(canvas, path, dashColor);
  }

  /// Dimension line with arrows and centered label.
  static void dimension(Canvas canvas, Offset a, Offset b, String label,
      {bool vertical = false}) {
    final paint = Paint()
      ..color = const Color(0xFF8A94A0)
      ..strokeWidth = 1.2;
    canvas.drawLine(a, b, paint);
    // Arrowheads.
    final dir = (b - a) / (b - a).distance;
    final perp = Offset(-dir.dy, dir.dx);
    for (final tip in [a, b]) {
      final d = tip == a ? dir : -dir;
      canvas.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(tip.dx - d.dx * 7 + perp.dx * 3.5,
              tip.dy - d.dy * 7 + perp.dy * 3.5)
          ..lineTo(tip.dx - d.dx * 7 - perp.dx * 3.5,
              tip.dy - d.dy * 7 - perp.dy * 3.5)
          ..close(),
        Paint()..color = const Color(0xFF8A94A0),
      );
    }
    // Label.
    final mid = (a + b) / 2;
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: ProTheme.accent,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          backgroundColor: Color(0xFF11161D),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
        canvas,
        Offset(mid.dx - tp.width / 2,
            mid.dy - tp.height / 2 + (vertical ? 0 : -2)));
  }

  /// Bend mark dot with number.
  static void markDot(Canvas canvas, Offset pt, String tag) {
    canvas.drawCircle(
        pt, 10, Paint()..color = bendGreen.withOpacity(0.3));
    canvas.drawCircle(pt, 6, Paint()..color = bendGreen);
    final tp = TextPainter(
      text: TextSpan(
        text: tag,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset(pt.dx - tp.width / 2, pt.dy - tp.height / 2));
  }
}
