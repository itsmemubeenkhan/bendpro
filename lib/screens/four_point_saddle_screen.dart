import 'package:flutter/material.dart';
import '../pro_diagram.dart';
import '../pro_widgets.dart';
import '../store.dart';
import '../units.dart';

/// Four-Point Saddle — pro layout.
class FourPointSaddleScreen extends StatefulWidget {
  const FourPointSaddleScreen({super.key});

  @override
  State<FourPointSaddleScreen> createState() => _FourPointSaddleScreenState();
}

class _FourPointSaddleScreenState extends State<FourPointSaddleScreen> {
  final _depthCtrl = TextEditingController(text: '4');
  final _widthCtrl = TextEditingController(text: '12');
  double _angle = 30;

  @override
  void dispose() {
    _depthCtrl.dispose();
    _widthCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MeasureMode>(
      valueListenable: AppUnits.mode,
      builder: (context, mode, _) {
        final d = AppUnits.parseInput(_depthCtrl.text, mode);
        final w = AppUnits.parseInput(_widthCtrl.text, mode);
        final m = AppUnits.multipliers[_angle]!;
        final each = d == null ? null : d * m;
        final ready = each != null && w != null;
        final m4 = ready ? 2 * each! + w! : null;

        return ProCalcScaffold(
          title: 'Four-Point Saddle',
          inputBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ProLengthInput(
                      label: 'Depth',
                      controller: _depthCtrl,
                      mode: mode,
                      onChanged: () => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ProLengthInput(
                      label: 'Width',
                      controller: _widthCtrl,
                      mode: mode,
                      onChanged: () => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ProAngleChips(
                selected: _angle,
                onSelected: (a) => setState(() => _angle = a),
              ),
            ],
          ),
          body: !ready
              ? const Center(
                  child: Text('Enter depth and width',
                      style: TextStyle(color: ProTheme.textDim)))
              : ProDragDiagram(
                  painter: _FourPtPainter(
                    depthIn: d!,
                    segLabel: AppUnits.format(each!, mode),
                  ),
                  onDragY: (dy, size) {
                    final frac = ((132 - dy) / 64).clamp(0.04, 1.0);
                    var v = (frac * 12).clamp(0.5, 12.0);
                    v = (v * 2).round() / 2;
                    _depthCtrl.text = AppUnits.formatInput(v, mode);
                    setState(() {});
                  },
                ),
          resultBar: m4 == null
              ? const ProResultBar(label: 'M1–M4 span', value: '—')
              : ProResultBar(
                  label: 'M1–M4 span',
                  value: AppUnits.format(m4, mode),
                  fraction: (mode != MeasureMode.centimeters)
                      ? AppUnits.fraction(m4)
                      : null,
                  onSave: () {
                    final summary =
                        '4-pt saddle ${AppUnits.format(d!, mode)} × ${AppUnits.format(w!, mode)} → span ${AppUnits.format(m4, mode)}';
                    HistoryStore.add('Four-Point Saddle', summary).then(
                        (_) => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Saved to history'))));
                  },
                  onSteps: () => showStepsSheet(context, 'Marking steps', [
                    'M1 at 0, M2 at ${AppUnits.format(each!, mode)}.',
                    'M3 at ${AppUnits.format(each! + w!, mode)} (M2 + width).',
                    'M4 at ${AppUnits.format(m4, mode)}.',
                    'Bend M1/M4 to ${AppUnits.angleLabel(_angle)} one way, M2/M3 the other.',
                  ]),
                ),
        );
      },
    );
  }
}

class _FourPtPainter extends CustomPainter {
  final double depthIn;
  final String segLabel;
  _FourPtPainter({required this.depthIn, required this.segLabel});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    const baseY = 132.0;
    final frac = (depthIn / 12).clamp(0.06, 1.0);
    final upY = baseY - frac * 64;
    final xs = [0.18, 0.40, 0.62, 0.84].map((f) => f * w).toList();
    ProPipe.draw(canvas, [
      Offset(12, baseY),
      Offset(xs[0], baseY),
      Offset(xs[1], upY),
      Offset(xs[2], upY),
      Offset(xs[3], baseY),
      Offset(w - 12, baseY),
    ]);
    const tags = ['M1', 'M2', 'M3', 'M4'];
    for (var i = 0; i < 4; i++) {
      ProPipe.mark(canvas,
          Offset(xs[i], (i == 1 || i == 2) ? upY : baseY), tags[i]);
    }
    ProPipe.label(canvas, segLabel, Offset((xs[0] + xs[1]) / 2, baseY + 22),
        color: ProTheme.accent, bold: true);
    ProPipe.label(canvas, 'drag ↕', Offset(w / 2, size.height - 16),
        size: 11, color: ProTheme.textDim);
  }

  @override
  bool shouldRepaint(covariant _FourPtPainter old) =>
      old.depthIn != depthIn || old.segLabel != segLabel;
}
