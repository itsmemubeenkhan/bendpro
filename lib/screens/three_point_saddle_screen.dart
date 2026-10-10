import 'package:flutter/material.dart';
import '../pro_diagram.dart';
import '../pro_widgets.dart';
import '../store.dart';
import '../units.dart';

/// Three-Point Saddle — pro layout with drag-to-adjust depth.
class ThreePointSaddleScreen extends StatefulWidget {
  const ThreePointSaddleScreen({super.key});

  @override
  State<ThreePointSaddleScreen> createState() =>
      _ThreePointSaddleScreenState();
}

class _ThreePointSaddleScreenState extends State<ThreePointSaddleScreen> {
  final _depthCtrl = TextEditingController(text: '4');

  @override
  void dispose() {
    _depthCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MeasureMode>(
      valueListenable: AppUnits.mode,
      builder: (context, mode, _) {
        final d = AppUnits.parseInput(_depthCtrl.text, mode);
        final outer = d == null ? null : d * 2.5;
        final half = outer == null ? null : outer / 2;

        return ProCalcScaffold(
          title: 'Three-Point Saddle',
          inputBar: ProLengthInput(
            label: 'Obstruction depth',
            controller: _depthCtrl,
            mode: mode,
            onChanged: () => setState(() {}),
          ),
          body: d == null
              ? const Center(
                  child: Text('Enter obstruction depth',
                      style: TextStyle(color: ProTheme.textDim)))
              : ProDragDiagram(
                  painter: _SaddlePainter(
                    depthIn: d,
                    outerLabel: AppUnits.format(outer!, mode),
                  ),
                  onDragY: (dy, size) {
                    final frac = ((138 - dy) / 72).clamp(0.04, 1.0);
                    var v = (frac * 12).clamp(0.5, 12.0);
                    v = (v * 2).round() / 2;
                    _depthCtrl.text = AppUnits.formatInput(v, mode);
                    setState(() {});
                  },
                ),
          resultBar: outer == null
              ? const ProResultBar(label: 'Outer marks apart', value: '—')
              : ProResultBar(
                  label: 'Outer marks apart',
                  value: AppUnits.format(outer, mode),
                  fraction: (mode != MeasureMode.centimeters)
                      ? AppUnits.fraction(outer)
                      : null,
                  onSave: () {
                    final summary =
                        '3-pt saddle ${AppUnits.format(d, mode)} → outer ${AppUnits.format(outer, mode)} apart';
                    HistoryStore.add('Three-Point Saddle', summary).then(
                        (_) => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Saved to history'))));
                  },
                  onSteps: () => showStepsSheet(context, 'Marking steps', [
                    'Center the obstruction, mark C on the conduit.',
                    'Measure ${AppUnits.format(half!, mode)} each way — mark A and B.',
                    'Bend center C to 45° first.',
                    'Bend A and B to 22.5° each, opposite direction.',
                  ]),
                ),
        );
      },
    );
  }
}

class _SaddlePainter extends CustomPainter {
  final double depthIn;
  final String outerLabel;
  _SaddlePainter({required this.depthIn, required this.outerLabel});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    const baseY = 138.0;
    final frac = (depthIn / 12).clamp(0.06, 1.0);
    final peakY = baseY - frac * 72;
    final cx = w / 2, ax = cx - 62, bx = cx + 62;
    // Obstruction.
    final r = Rect.fromLTWH(cx - 42, baseY + 8, 84, 40);
    canvas.drawRect(r, Paint()..color = const Color(0xFF2A3138));
    canvas.drawRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0xFF5F6B76));
    ProPipe.draw(canvas, [
      Offset(14, baseY),
      Offset(ax, baseY),
      Offset(cx, peakY),
      Offset(bx, baseY),
      Offset(w - 14, baseY),
    ]);
    ProPipe.mark(canvas, Offset(ax, baseY), 'A');
    ProPipe.mark(canvas, Offset(cx, peakY), 'C');
    ProPipe.mark(canvas, Offset(bx, baseY), 'B');
    ProPipe.dim(canvas, Offset(ax, 26), Offset(bx, 26), outerLabel);
    ProPipe.label(canvas, 'drag peak ↕', Offset(w / 2, size.height - 16),
        size: 11, color: ProTheme.textDim);
  }

  @override
  bool shouldRepaint(covariant _SaddlePainter old) =>
      old.depthIn != depthIn || old.outerLabel != outerLabel;
}
