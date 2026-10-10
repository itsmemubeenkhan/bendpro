import 'dart:math';
import 'package:flutter/material.dart';

/// Professional interactive bender: a realistic bender shoe with the
/// conduit wrapped around it. Drag the conduit end to bend.
///
/// This is the centerpiece interaction — it should feel like holding
/// a real bender, not dragging an abstract line.
class ProBender extends StatefulWidget {
  /// Current bend angle in degrees (0-90).
  final double angleDeg;
  /// Called as the user drags, with the new angle.
  final ValueChanged<double> onAngleChanged;
  /// Labels to show on the shoe degree markings.
  final List<double> snapAngles;
  /// Height of the widget.
  final double height;

  const ProBender({
    super.key,
    required this.angleDeg,
    required this.onAngleChanged,
    this.snapAngles = const [10, 15, 22.5, 30, 45, 60],
    this.height = 280,
  });

  @override
  State<ProBender> createState() => _ProBenderState();
}

class _ProBenderState extends State<ProBender> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (d) => _handleDrag(d.globalPosition),
      onPanUpdate: (d) => _handleDrag(d.globalPosition),
      child: CustomPaint(
        size: Size(double.infinity, widget.height),
        painter: _BenderPainter(
          angleDeg: widget.angleDeg,
          snapAngles: widget.snapAngles,
        ),
      ),
    );
  }

  void _handleDrag(Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final local = box.globalToLocal(global);
    final size = box.size;
    // Bender shoe center.
    final cx = size.width * 0.42;
    final cy = size.height * 0.62;
    // Angle from the drag position relative to shoe center.
    // 0° = conduit pointing left (unbent), 90° = pointing up.
    var deg = atan2(cy - local.dy, local.dx - cx) * 180 / pi;
    // Clamp to 0-90 range; ignore drags in wrong quadrants.
    if (local.dx < cx - 10) {
      deg = 0;
    } else {
      deg = deg.clamp(0.0, 90.0);
    }
    // Snap to standard angles when close.
    var snapped = deg;
    var bestDiff = 4.0;
    for (final a in widget.snapAngles) {
      final diff = (deg - a).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        snapped = a;
      }
    }
    widget.onAngleChanged(snapped);
  }
}

class _BenderPainter extends CustomPainter {
  final double angleDeg;
  final List<double> snapAngles;

  _BenderPainter({required this.angleDeg, required this.snapAngles});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.42;
    final cy = size.height * 0.62;
    const shoeR = 64.0; // bender shoe radius
    const pipeW = 13.0; // conduit width

    // --- Bender shoe (the grooved head) ---
    final shoePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF2A3138);
    final shoeEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF4A5560);
    // Shoe body: a disc with the conduit groove.
    canvas.drawCircle(Offset(cx, cy), shoeR, shoePaint);
    canvas.drawCircle(Offset(cx, cy), shoeR, shoeEdge);
    // Inner hub.
    canvas.drawCircle(
        Offset(cx, cy), 14, Paint()..color = const Color(0xFF1A1F24));
    canvas.drawCircle(Offset(cx, cy), 14, shoeEdge);
    // Degree markings around the shoe.
    for (final a in [0, 10, 15, 22.5, 30, 45, 60, 90]) {
      final rad = a * pi / 180;
      final isSnap = snapAngles.contains(a);
      final p1 = Offset(
        cx + (shoeR - (isSnap ? 16 : 10)) * cos(rad),
        cy - (shoeR - (isSnap ? 16 : 10)) * sin(rad),
      );
      final p2 = Offset(
        cx + (shoeR - 4) * cos(rad),
        cy - (shoeR - 4) * sin(rad),
      );
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = isSnap ? const Color(0xFF2196F3) : const Color(0xFF5F6B76)
          ..strokeWidth = isSnap ? 2.5 : 1.5,
      );
      if (isSnap && a != 0) {
        final tp = TextPainter(
          text: TextSpan(
            text: a == a.roundToDouble() ? '${a.toInt()}°' : '${a}°',
            style: const TextStyle(
              color: Color(0xFF8A94A0),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final lp = Offset(
          cx + (shoeR - 30) * cos(rad) - tp.width / 2,
          cy - (shoeR - 30) * sin(rad) - tp.height / 2,
        );
        tp.paint(canvas, lp);
      }
    }

    // --- Handle (extends down-left from shoe) ---
    final handlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF232A31);
    canvas.drawLine(
      Offset(cx - 14, cy + 14),
      Offset(cx - 84, cy + 84),
      handlePaint,
    );

    // --- Conduit (metallic pipe bending around the shoe) ---
    final rad = angleDeg * pi / 180;
    // Pipe path: straight lead-in from left, wraps around shoe, exits at angle.
    final pipePath = Path();
    final leadStart = Offset(8, cy);
    final tangentPt = Offset(cx - shoeR - pipeW / 2 - 2, cy);
    pipePath.moveTo(leadStart.dx, leadStart.dy);
    pipePath.lineTo(tangentPt.dx, tangentPt.dy);
    // Arc around the shoe from 180° to (180° - angle).
    final arcRect = Rect.fromCircle(
      center: Offset(cx, cy),
      radius: shoeR + pipeW / 2 + 2,
    );
    pipePath.arcTo(arcRect, pi, -rad, false);
    // Straight exit after the bend.
    final exitStart = Offset(
      cx + (shoeR + pipeW / 2 + 2) * cos(pi - rad),
      cy + (shoeR + pipeW / 2 + 2) * sin(pi - rad),
    );
    final exitDir = Offset(cos(-rad), sin(-rad));
    final exitEnd = exitStart + exitDir * 90;
    pipePath.lineTo(exitEnd.dx, exitEnd.dy);

    // Metallic pipe: layered strokes for depth.
    // 1. Dark outline.
    canvas.drawPath(
      pipePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = pipeW + 3
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF0D1117),
    );
    // 2. Steel body.
    canvas.drawPath(
      pipePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = pipeW
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF9AA7B4),
    );
    // 3. Highlight stripe (offset up-left for light source).
    final hlPath = Path();
    hlPath.moveTo(leadStart.dx, leadStart.dy - 3.5);
    hlPath.lineTo(tangentPt.dx, tangentPt.dy - 3.5);
    hlPath.arcTo(
      Rect.fromCircle(
        center: Offset(cx, cy - 3.5),
        radius: shoeR + pipeW / 2 + 2,
      ),
      pi,
      -rad,
      false,
    );
    final hlEnd = Offset(
      cx + (shoeR + pipeW / 2 + 2) * cos(pi - rad),
      cy - 3.5 + (shoeR + pipeW / 2 + 2) * sin(pi - rad),
    );
    hlPath.lineTo(hlEnd.dx + exitDir.dx * 90, hlEnd.dy + exitDir.dy * 90);
    canvas.drawPath(
      hlPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFD5DDE5).withOpacity(0.85),
    );

    // --- Drag handle at the conduit end ---
    final knobPaint = Paint()..color = const Color(0xFF2196F3);
    final knobEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white;
    canvas.drawCircle(exitEnd, 16, knobPaint);
    canvas.drawCircle(exitEnd, 16, knobEdge);
    // Grip icon.
    final grip = TextPainter(
      text: const TextSpan(
        text: '↔',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    grip.paint(
        canvas, Offset(exitEnd.dx - grip.width / 2, exitEnd.dy - grip.height / 2));

    // --- Angle readout ---
    final angleText = TextPainter(
      text: TextSpan(
        text: angleDeg == angleDeg.roundToDouble()
            ? '${angleDeg.toInt()}°'
            : '${angleDeg.toStringAsFixed(1)}°',
        style: const TextStyle(
          color: Color(0xFF2196F3),
          fontSize: 34,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    angleText.paint(
      canvas,
      Offset(cx - angleText.width / 2, cy - shoeR - 52),
    );

    // Hint.
    final hint = TextPainter(
      text: const TextSpan(
        text: 'Drag the blue knob to bend',
        style: TextStyle(color: Color(0xFF5F6B76), fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    hint.paint(
      canvas,
      Offset(size.width / 2 - hint.width / 2, size.height - 22),
    );
  }

  @override
  bool shouldRepaint(covariant _BenderPainter old) =>
      old.angleDeg != angleDeg;
}
