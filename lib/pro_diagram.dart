import 'dart:math';
import 'package:flutter/material.dart';
import '../pro_widgets.dart';

/// Compact interactive diagram for saddles/offsets: drag vertically
/// to change the depth/height. Professional pipe rendering.
class ProDragDiagram extends StatelessWidget {
  final CustomPainter painter;
  final void Function(double dragY, Size size) onDragY;
  final double height;

  const ProDragDiagram({
    super.key,
    required this.painter,
    required this.onDragY,
    this.height = 240,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: ProTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ProTheme.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Builder(
          builder: (ctx) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) => _handle(d.globalPosition, ctx),
            onPanUpdate: (d) => _handle(d.globalPosition, ctx),
            child: CustomPaint(
              size: Size(double.infinity, height),
              painter: painter,
            ),
          ),
        ),
      ),
    );
  }

  void _handle(Offset global, BuildContext ctx) {
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final local = box.globalToLocal(global);
    onDragY(local.dy, box.size);
  }
}

/// Professional pipe drawing helpers: metallic tube, not a flat line.
class ProPipe {
  /// Draws a metallic conduit along [points] with width [w].
  static void draw(Canvas canvas, List<Offset> points, {double w = 12}) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    // Outline.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w + 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF0D1117),
    );
    // Steel body.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF9AA7B4),
    );
    // Highlight.
    final hl = Path()..moveTo(points.first.dx, points.first.dy - w * 0.28);
    for (var i = 1; i < points.length; i++) {
      hl.lineTo(points[i].dx, points[i].dy - w * 0.28);
    }
    canvas.drawPath(
      hl,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.22
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFD5DDE5).withOpacity(0.7),
    );
  }

  /// Bend mark: glowing dot with tag.
  static void mark(Canvas canvas, Offset pt, String tag) {
    // Glow.
    canvas.drawCircle(
        pt, 11, Paint()..color = ProTheme.accent.withOpacity(0.25));
    canvas.drawCircle(pt, 7, Paint()..color = ProTheme.accent);
    canvas.drawCircle(pt, 2.5, Paint()..color = Colors.black);
    _label(canvas, tag, pt + const Offset(0, -22),
        color: ProTheme.accent, bold: true, size: 13);
  }

  static void _label(Canvas canvas, String s, Offset at,
      {double size = 12,
      Color color = const Color(0xFFBDC1C6),
      bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
            color: color,
            fontSize: size,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(at.dx - tp.width / 2, at.dy - tp.height / 2));
  }

  static void label(Canvas c, String s, Offset at,
          {double size = 12,
          Color color = const Color(0xFFBDC1C6),
          bool bold = false}) =>
      _label(c, s, at, size: size, color: color, bold: bold);

  /// Dimension line with arrows.
  static void dim(Canvas canvas, Offset a, Offset b, String text) {
    final p = Paint()
      ..color = const Color(0xFF5F6B76)
      ..strokeWidth = 1.2;
    canvas.drawLine(a, b, p);
    final dir = (b - a) / (b - a).distance;
    final perp = Offset(-dir.dy, dir.dx);
    for (final tip in [a, b]) {
      final d = tip == a ? dir : -dir;
      canvas.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(tip.dx - d.dx * 8 + perp.dx * 4,
              tip.dy - d.dy * 8 + perp.dy * 4)
          ..lineTo(tip.dx - d.dx * 8 - perp.dx * 4,
              tip.dy - d.dy * 8 - perp.dy * 4)
          ..close(),
        Paint()..color = const Color(0xFF5F6B76),
      );
    }
    final mid = (a + b) / 2 - perp * 14;
    _label(canvas, text, mid,
        size: 12, color: ProTheme.accent, bold: true);
  }
}
