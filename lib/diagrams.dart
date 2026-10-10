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
/// [offsetInches] drives the visual rise so the pipe moves while dragging.
class OffsetDiagramPainter extends CustomPainter {
  final String distLabel;
  final String heightLabel;
  final double offsetInches;
  OffsetDiagramPainter({
    required this.distLabel,
    required this.heightLabel,
    this.offsetInches = 6,
  });

  static const double baseY = 150.0;
  static const double maxRisePx = 110.0;
  static const double maxOffsetIn = 24.0;

  /// Visual Y of the raised pipe for a given offset.
  static double raisedY(double offsetIn) {
    final frac = (offsetIn / maxOffsetIn).clamp(0.04, 1.0);
    return baseY - frac * maxRisePx;
  }

  /// Inverse: drag Y position -> offset inches.
  static double offsetFromDragY(double dragY) {
    final frac = ((baseY - dragY) / maxRisePx).clamp(0.02, 1.0);
    return (frac * maxOffsetIn).clamp(0.5, maxOffsetIn);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final y0 = baseY, y1 = raisedY(offsetInches);
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
      old.distLabel != distLabel ||
      old.heightLabel != heightLabel ||
      old.offsetInches != offsetInches;
}

/// Rolling offset: offset pipe + rise/roll/true-offset triangle inset.
/// [riseInches] drives the visual rise so the pipe moves while dragging.
class RollingOffsetDiagramPainter extends CustomPainter {
  final String distLabel;
  final String riseLabel;
  final String rollLabel;
  final String trueLabel;
  final double riseInches;
  RollingOffsetDiagramPainter({
    required this.distLabel,
    required this.riseLabel,
    required this.rollLabel,
    required this.trueLabel,
    this.riseInches = 6,
  });

  static const double baseY = 118.0;
  static const double maxRisePx = 70.0;
  static const double maxRiseIn = 24.0;

  static double raisedY(double riseIn) {
    final frac = (riseIn / maxRiseIn).clamp(0.04, 1.0);
    return baseY - frac * maxRisePx;
  }

  static double riseFromDragY(double dragY) {
    final frac = ((baseY - dragY) / maxRisePx).clamp(0.02, 1.0);
    return (frac * maxRiseIn).clamp(0.5, maxRiseIn);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final y0 = baseY, y1 = raisedY(riseInches);
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
      old.distLabel != distLabel ||
      old.trueLabel != trueLabel ||
      old.riseInches != riseInches;
}

/// 90° stub-up: mark measured from the end, riser to finished height.
/// [stubInches] drives the riser height so the pipe moves while dragging.
class StubUpDiagramPainter extends CustomPainter {
  final String markLabel;
  final String stubLabel;
  final String deductLabel;
  final double stubInches;
  StubUpDiagramPainter({
    required this.markLabel,
    required this.stubLabel,
    required this.deductLabel,
    this.stubInches = 24,
  });

  static const double baseY = 158.0;
  static const double maxRisePx = 120.0;
  static const double maxStubIn = 60.0;

  static double topY(double stubIn) {
    final frac = (stubIn / maxStubIn).clamp(0.05, 1.0);
    return baseY - frac * maxRisePx;
  }

  static double stubFromDragY(double dragY) {
    final frac = ((baseY - dragY) / maxRisePx).clamp(0.03, 1.0);
    return (frac * maxStubIn).clamp(1, maxStubIn);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    const endX = 16.0, bendX = 150.0;
    final baseYv = baseY, topYv = topY(stubInches);
    _D.pipe(canvas, [Offset(endX, baseYv), Offset(bendX, baseYv), Offset(bendX, topYv)]);
    _D.mark(canvas, Offset(bendX, baseYv), 'mark');
    _D.hDim(canvas, endX, bendX, baseYv + 28, markLabel);
    _D.vDim(canvas, topYv, baseYv, w - 30, stubLabel);
    _D.text(canvas, 'deduct $deductLabel', Offset(bendX + 62, baseYv - 26),
        size: 11, color: const Color(0xFFBDC1C6));
  }

  @override
  bool shouldRepaint(covariant StubUpDiagramPainter old) =>
      old.markLabel != markLabel ||
      old.stubLabel != stubLabel ||
      old.stubInches != stubInches;
}

/// Three-point saddle: A/C/B marks over a hatched obstruction.
/// [depthInches] drives the peak height so the pipe moves while dragging.
class ThreePointSaddlePainter extends CustomPainter {
  final String outerLabel;
  final String depthLabel;
  final double depthInches;
  ThreePointSaddlePainter({
    required this.outerLabel,
    required this.depthLabel,
    this.depthInches = 4,
  });

  static const double baseY = 138.0;
  static const double maxPeakPx = 72.0;
  static const double maxDepthIn = 12.0;

  static double peakY(double depthIn) {
    final frac = (depthIn / maxDepthIn).clamp(0.06, 1.0);
    return baseY - frac * maxPeakPx;
  }

  static double depthFromDragY(double dragY) {
    final frac = ((baseY - dragY) / maxPeakPx).clamp(0.04, 1.0);
    return (frac * maxDepthIn).clamp(0.5, maxDepthIn);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final baseYv = baseY, peakYv = peakY(depthInches);
    final cx = w / 2;
    final ax = cx - 62, bx = cx + 62;
    // Obstruction box under the peak.
    _D.hatchRect(canvas, Rect.fromLTWH(cx - 42, baseYv + 6, 84, 44));
    _D.text(canvas, 'obstruction $depthLabel', Offset(cx, baseYv + 66), size: 10.5);
    _D.pipe(canvas, [
      Offset(14, baseYv),
      Offset(ax, baseYv),
      Offset(cx, peakYv),
      Offset(bx, baseYv),
      Offset(w - 14, baseYv),
    ]);
    _D.mark(canvas, Offset(ax, baseYv), 'A');
    _D.mark(canvas, Offset(cx, peakYv), 'C');
    _D.mark(canvas, Offset(bx, baseYv), 'B');
    _D.hDim(canvas, ax, bx, 26, outerLabel);
  }

  @override
  bool shouldRepaint(covariant ThreePointSaddlePainter old) =>
      old.outerLabel != outerLabel ||
      old.depthLabel != depthLabel ||
      old.depthInches != depthInches;
}

/// Four-point saddle: M1..M4 with per-segment spacing labels.
/// [depthInches] drives the raised section so the pipe moves while dragging.
class FourPointSaddlePainter extends CustomPainter {
  /// x positions of the four marks as fractions of width.
  final List<double> fx;
  final List<String> segLabels;
  final List<String> tags;
  final double depthInches;
  FourPointSaddlePainter({
    required this.fx,
    required this.segLabels,
    this.tags = const ['M1', 'M2', 'M3', 'M4'],
    this.depthInches = 4,
  });

  static const double baseY = 132.0;
  static const double maxUpPx = 64.0;
  static const double maxDepthIn = 12.0;

  static double upY(double depthIn) {
    final frac = (depthIn / maxDepthIn).clamp(0.06, 1.0);
    return baseY - frac * maxUpPx;
  }

  static double depthFromDragY(double dragY) {
    final frac = ((baseY - dragY) / maxUpPx).clamp(0.04, 1.0);
    return (frac * maxDepthIn).clamp(0.5, maxDepthIn);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final baseYv = baseY, upYv = upY(depthInches);
    final xs = fx.map((f) => f * w).toList();
    _D.pipe(canvas, [
      const Offset(12, baseY),
      Offset(xs[0], baseYv),
      Offset(xs[1], upYv),
      Offset(xs[2], upYv),
      Offset(xs[3], baseYv),
      Offset(w - 12, baseYv),
    ]);
    for (var i = 0; i < 4; i++) {
      _D.mark(canvas, Offset(xs[i], i == 1 || i == 2 ? upYv : baseYv), tags[i]);
    }
    for (var i = 0; i < 3; i++) {
      _D.text(canvas, segLabels[i],
          Offset((xs[i] + xs[i + 1]) / 2, baseYv + 26),
          size: 11, color: _D.labelColor, bold: true);
    }
  }

  @override
  bool shouldRepaint(covariant FourPointSaddlePainter old) =>
      old.segLabels.join() != segLabels.join() ||
      old.fx.join() != fx.join() ||
      old.depthInches != depthInches;
}

/// Kick: single bend near the end; mark distance + kick depth.
/// Drag the pipe tip to change the bend angle.
class KickDiagramPainter extends CustomPainter {
  final String markLabel;
  final String depthLabel;
  final double angleDeg;
  KickDiagramPainter({
    required this.markLabel,
    required this.depthLabel,
    required this.angleDeg,
  });

  static const double markX = 190.0;
  static const double baseY = 148.0;
  static const double armLen = 74.0;

  /// Angle in degrees from a drag position relative to the bend mark.
  static double angleFromDrag(Offset dragPos) {
    final dx = dragPos.dx - markX;
    final dy = baseY - dragPos.dy;
    if (dx <= 4 && dy <= 4) return 30;
    var deg = atan2(dy, dx) * 180 / pi;
    return deg.clamp(10.0, 90.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    const endX = 16.0;
    final markXv = markX, baseYv = baseY;
    final rad = angleDeg * pi / 180;
    final tip = Offset(markXv + armLen * cos(rad), baseYv - armLen * sin(rad));
    _D.pipe(canvas, [Offset(endX, baseYv), Offset(markXv, baseYv), tip]);
    _D.mark(canvas, Offset(markXv, baseYv), 'mark');
    _D.hDim(canvas, endX, markXv, baseYv + 28, markLabel);
    _D.vDim(canvas, tip.dy, baseYv, min(tip.dx + 26, w - 24), depthLabel);
    _D.text(canvas, '${angleDeg == angleDeg.roundToDouble() ? angleDeg.toInt() : angleDeg}°',
        tip + const Offset(20, -16),
        size: 12, color: _D.labelColor, bold: true);
  }

  @override
  bool shouldRepaint(covariant KickDiagramPainter old) =>
      old.markLabel != markLabel || old.angleDeg != angleDeg;
}

/// Double 90° (U-bend): two legs, spacing across the top.
/// [legInches] drives the leg height so the pipe moves while dragging.
class UBendDiagramPainter extends CustomPainter {
  final String legLabel;
  final String spacingLabel;
  final double legInches;
  UBendDiagramPainter({
    required this.legLabel,
    required this.spacingLabel,
    this.legInches = 18,
  });

  static const double botY = 160.0;
  static const double maxLegPx = 110.0;
  static const double maxLegIn = 48.0;

  static double topY(double legIn) {
    final frac = (legIn / maxLegIn).clamp(0.08, 1.0);
    return botY - frac * maxLegPx;
  }

  static double legFromDragY(double dragY) {
    final frac = ((botY - dragY) / maxLegPx).clamp(0.05, 1.0);
    return (frac * maxLegIn).clamp(2, maxLegIn);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final x1 = w * 0.28, x2 = w * 0.72;
    final topYv = topY(legInches), botYv = botY;
    _D.pipe(canvas, [
      Offset(x1, botYv),
      Offset(x1, topYv),
      Offset(x2, topYv),
      Offset(x2, botYv),
    ]);
    _D.mark(canvas, Offset(x1, topYv), 'A');
    _D.mark(canvas, Offset(x2, topYv), 'B');
    _D.vDim(canvas, topYv, botYv, x1 - 34, legLabel);
    _D.hDim(canvas, x1, x2, 24, spacingLabel);
  }

  @override
  bool shouldRepaint(covariant UBendDiagramPainter old) =>
      old.legLabel != legLabel ||
      old.spacingLabel != spacingLabel ||
      old.legInches != legInches;
}
