import 'dart:math';
import 'package:flutter/material.dart';
import 'widgets.dart' show kAccent;

/// Original hand-drawn-style bend diagrams for each calculator.
/// Every painter receives pre-formatted label strings so it stays dumb.

class _D {
  static final pipePaint = Paint()
    ..color = kAccent
    ..strokeWidth = 9
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static final dimPaint = Paint()..color = const Color(0xFF9AA0A6)..strokeWidth = 1.2;
  static final arrowPaint = Paint()..color = const Color(0xFF9AA0A6);
  static const labelColor = Color(0xFF2196F3);

  static void pipe(Canvas c, List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    c.drawPath(path, pipePaint);
  }

  static void text(
    Canvas c,
    String s,
    Offset at, {
    double size = 12,
    Color color = const Color(0xFFBDC1C6),
    bool bold = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(at.dx - tp.width / 2, at.dy - tp.height / 2));
  }

  /// Bend mark: blue dot with a number tag above it.
  static void mark(Canvas c, Offset pt, String tag) {
    c.drawCircle(pt, 7, Paint()..color = kAccent);
    c.drawCircle(pt, 3, Paint()..color = Colors.black);
    text(c, tag, pt + const Offset(0, -24),
        size: 13, color: labelColor, bold: true);
  }

  static void _arrowH(Canvas c, Offset tip, double dir) {
    c.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(tip.dx - 8 * dir, tip.dy - 4.5)
        ..lineTo(tip.dx - 8 * dir, tip.dy + 4.5)
        ..close(),
      arrowPaint,
    );
  }

  static void _arrowV(Canvas c, Offset tip, double dir) {
    c.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(tip.dx - 4.5, tip.dy - 8 * dir)
        ..lineTo(tip.dx + 4.5, tip.dy - 8 * dir)
        ..close(),
      arrowPaint,
    );
  }

  /// Horizontal dimension line with arrows and a centered label.
  static void hDim(Canvas c, double x1, double x2, double y, String label) {
    c.drawLine(Offset(x1, y), Offset(x2, y), dimPaint);
    _arrowH(c, Offset(x1 + 1, y), 1);
    _arrowH(c, Offset(x2 - 1, y), -1);
    text(c, label, Offset((x1 + x2) / 2, y - 15),
        size: 11.5, color: labelColor, bold: true);
  }

  /// Vertical dimension line with arrows and a centered label.
  static void vDim(Canvas c, double y1, double y2, double x, String label) {
    c.drawLine(Offset(x, y1), Offset(x, y2), dimPaint);
    _arrowV(c, Offset(x, y1 + 1), 1);
    _arrowV(c, Offset(x, y2 - 1), -1);
    text(c, label, Offset(x + 4, (y1 + y2) / 2),
        size: 11.5, color: labelColor, bold: true);
  }

  static void dashed(Canvas c, Offset a, Offset b) {
    final p = Paint()..color = const Color(0xFF5F6368)..strokeWidth = 1;
    final total = (b - a).distance;
    if (total <= 0) return;
    final dir = (b - a) / total;
    const dash = 5.0, gap = 4.0;
    var d = 0.0;
    while (d < total) {
      final e = min(d + dash, total);
      c.drawLine(a + dir * d, a + dir * e, p);
      d += dash + gap;
    }
  }

  static void hatchRect(Canvas c, Rect r) {
    c.save();
    c.clipRect(r);
    c.drawRect(r, Paint()..color = const Color(0xFF3A3F45));
    final p = Paint()..color = const Color(0xFF70757A)..strokeWidth = 1;
    for (var x = r.left - r.height; x < r.right + r.height; x += 9) {
      c.drawLine(Offset(x, r.bottom), Offset(x + r.height, r.top), p);
    }
    c.restore();
    c.drawRect(r, Paint()..color = const Color(0xFF9AA0A6)..style = PaintingStyle.stroke..strokeWidth = 1.2);
  }
}

/// Offset: two bends, dimension between marks + offset height.
class OffsetDiagramPainter extends CustomPainter {
  final String distLabel;
  final String heightLabel;
  OffsetDiagramPainter({required this.distLabel, required this.heightLabel});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final y0 = 128.0, y1 = 74.0;
    final m1x = w * 0.36, m2x = w * 0.64;
    _D.pipe(canvas, [Offset(14, y0), Offset(m1x, y0), Offset(m2x, y1), Offset(w - 14, y1)]);
    _D.dashed(canvas, Offset(m1x, y0), Offset(m2x, y0));
    _D.mark(canvas, Offset(m1x, y0), '1');
    _D.mark(canvas, Offset(m2x, y1), '2');
    _D.hDim(canvas, m1x, m2x, 30, distLabel);
    _D.vDim(canvas, y1, y0, w - 26, heightLabel);
  }

  @override
  bool shouldRepaint(covariant OffsetDiagramPainter old) =>
      old.distLabel != distLabel || old.heightLabel != heightLabel;
}

/// Rolling offset: offset pipe + rise/roll/true-offset triangle inset.
class RollingOffsetDiagramPainter extends CustomPainter {
  final String distLabel;
  final String riseLabel;
  final String rollLabel;
  final String trueLabel;
  RollingOffsetDiagramPainter({
    required this.distLabel,
    required this.riseLabel,
    required this.rollLabel,
    required this.trueLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final y0 = 96.0, y1 = 52.0;
    final m1x = w * 0.38, m2x = w * 0.66;
    _D.pipe(canvas, [Offset(14, y0), Offset(m1x, y0), Offset(m2x, y1), Offset(w - 14, y1)]);
    _D.mark(canvas, Offset(m1x, y0), '1');
    _D.mark(canvas, Offset(m2x, y1), '2');
    _D.hDim(canvas, m1x, m2x, 22, distLabel);
    // Triangle inset: rise (vertical), roll (horizontal), true (hypotenuse).
    const tx = 30.0, ty = 168.0;
    const riseH = 34.0, rollW = 52.0;
    final p = Paint()..color = const Color(0xFF9AA0A6)..strokeWidth = 1.4;
    canvas.drawLine(Offset(tx, ty), Offset(tx, ty - riseH), p);
    canvas.drawLine(Offset(tx, ty), Offset(tx + rollW, ty), p);
    canvas.drawLine(Offset(tx, ty - riseH), Offset(tx + rollW, ty),
        Paint()..color = kAccent..strokeWidth = 1.8);
    _D.text(canvas, riseLabel, Offset(tx - 24, ty - riseH / 2), size: 10.5);
    _D.text(canvas, rollLabel, Offset(tx + rollW / 2, ty + 13), size: 10.5);
    _D.text(canvas, 'true $trueLabel', Offset(tx + rollW / 2 + 8, ty - riseH / 2 - 12),
        size: 10.5, color: _D.labelColor, bold: true);
  }

  @override
  bool shouldRepaint(covariant RollingOffsetDiagramPainter old) =>
      old.distLabel != distLabel || old.trueLabel != trueLabel;
}

/// 90° stub-up: mark measured from the end, riser to finished height.
class StubUpDiagramPainter extends CustomPainter {
  final String markLabel;
  final String stubLabel;
  final String deductLabel;
  StubUpDiagramPainter({
    required this.markLabel,
    required this.stubLabel,
    required this.deductLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    const endX = 16.0, bendX = 150.0, baseY = 138.0, topY = 34.0;
    _D.pipe(canvas, [Offset(endX, baseY), Offset(bendX, baseY), Offset(bendX, topY)]);
    _D.mark(canvas, Offset(bendX, baseY), 'mark');
    _D.hDim(canvas, endX, bendX, baseY + 28, markLabel);
    _D.vDim(canvas, topY, baseY, w - 30, stubLabel);
    _D.text(canvas, 'deduct $deductLabel', Offset(bendX + 62, baseY - 26),
        size: 11, color: const Color(0xFFBDC1C6));
  }

  @override
  bool shouldRepaint(covariant StubUpDiagramPainter old) =>
      old.markLabel != markLabel || old.stubLabel != stubLabel;
}

/// Three-point saddle: A/C/B marks over a hatched obstruction.
class ThreePointSaddlePainter extends CustomPainter {
  final String outerLabel;
  final String depthLabel;
  ThreePointSaddlePainter({required this.outerLabel, required this.depthLabel});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    const baseY = 118.0, peakY = 66.0;
    final cx = w / 2;
    final ax = cx - 62, bx = cx + 62;
    // Obstruction box under the peak.
    _D.hatchRect(canvas, Rect.fromLTWH(cx - 42, baseY + 6, 84, 44));
    _D.text(canvas, 'obstruction $depthLabel', Offset(cx, baseY + 66), size: 10.5);
    _D.pipe(canvas, [
      Offset(14, baseY),
      Offset(ax, baseY),
      Offset(cx, peakY),
      Offset(bx, baseY),
      Offset(w - 14, baseY),
    ]);
    _D.mark(canvas, Offset(ax, baseY), 'A');
    _D.mark(canvas, Offset(cx, peakY), 'C');
    _D.mark(canvas, Offset(bx, baseY), 'B');
    _D.hDim(canvas, ax, bx, 26, outerLabel);
  }

  @override
  bool shouldRepaint(covariant ThreePointSaddlePainter old) =>
      old.outerLabel != outerLabel || old.depthLabel != depthLabel;
}

/// Four-point saddle: M1..M4 with per-segment spacing labels.
class FourPointSaddlePainter extends CustomPainter {
  /// x positions of the four marks as fractions of width.
  final List<double> fx;
  final List<String> segLabels;
  final List<String> tags;
  FourPointSaddlePainter({
    required this.fx,
    required this.segLabels,
    this.tags = const ['M1', 'M2', 'M3', 'M4'],
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    const baseY = 112.0, upY = 66.0;
    final xs = fx.map((f) => f * w).toList();
    _D.pipe(canvas, [
      const Offset(12, baseY),
      Offset(xs[0], baseY),
      Offset(xs[1], upY),
      Offset(xs[2], upY),
      Offset(xs[3], baseY),
      Offset(w - 12, baseY),
    ]);
    for (var i = 0; i < 4; i++) {
      _D.mark(canvas, Offset(xs[i], i == 1 || i == 2 ? upY : baseY), tags[i]);
    }
    for (var i = 0; i < 3; i++) {
      _D.text(canvas, segLabels[i],
          Offset((xs[i] + xs[i + 1]) / 2, baseY + 26),
          size: 11, color: _D.labelColor, bold: true);
    }
  }

  @override
  bool shouldRepaint(covariant FourPointSaddlePainter old) =>
      old.segLabels.join() != segLabels.join() || old.fx.join() != fx.join();
}

/// Kick: single bend near the end; mark distance + kick depth.
class KickDiagramPainter extends CustomPainter {
  final String markLabel;
  final String depthLabel;
  final double angleDeg;
  KickDiagramPainter({
    required this.markLabel,
    required this.depthLabel,
    required this.angleDeg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    const endX = 16.0, markX = 190.0, baseY = 128.0;
    final rad = angleDeg * pi / 180;
    final tip = Offset(markX + 74 * cos(rad), baseY - 74 * sin(rad));
    _D.pipe(canvas, [Offset(endX, baseY), Offset(markX, baseY), tip]);
    _D.mark(canvas, Offset(markX, baseY), 'mark');
    _D.hDim(canvas, endX, markX, baseY + 28, markLabel);
    _D.vDim(canvas, tip.dy, baseY, min(tip.dx + 26, w - 24), depthLabel);
    _D.text(canvas, '${angleDeg == angleDeg.roundToDouble() ? angleDeg.toInt() : angleDeg}°',
        tip + const Offset(20, -16),
        size: 12, color: _D.labelColor, bold: true);
  }

  @override
  bool shouldRepaint(covariant KickDiagramPainter old) =>
      old.markLabel != markLabel || old.angleDeg != angleDeg;
}

/// Double 90° (U-bend): two legs, spacing across the top.
class UBendDiagramPainter extends CustomPainter {
  final String legLabel;
  final String spacingLabel;
  UBendDiagramPainter({required this.legLabel, required this.spacingLabel});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final x1 = w * 0.28, x2 = w * 0.72;
    const topY = 52.0, botY = 150.0;
    _D.pipe(canvas, [
      Offset(x1, botY),
      Offset(x1, topY),
      Offset(x2, topY),
      Offset(x2, botY),
    ]);
    _D.mark(canvas, Offset(x1, topY), 'A');
    _D.mark(canvas, Offset(x2, topY), 'B');
    _D.vDim(canvas, topY, botY, x1 - 34, legLabel);
    _D.hDim(canvas, x1, x2, 24, spacingLabel);
  }

  @override
  bool shouldRepaint(covariant UBendDiagramPainter old) =>
      old.legLabel != legLabel || old.spacingLabel != spacingLabel;
}
