import 'package:flutter/material.dart';
import '../pro_diagram.dart';
import '../pro_widgets.dart';
import '../store.dart';
import '../units.dart';
import 'dart:math';

/// Rolling Offset — pro layout with drag-to-adjust rise.
class RollingOffsetScreen extends StatefulWidget {
  const RollingOffsetScreen({super.key});

  @override
  State<RollingOffsetScreen> createState() => _RollingOffsetScreenState();
}

class _RollingOffsetScreenState extends State<RollingOffsetScreen> {
  final _riseCtrl = TextEditingController(text: '6');
  final _rollCtrl = TextEditingController(text: '6');
  double _angle = 30;

  @override
  void dispose() {
    _riseCtrl.dispose();
    _rollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MeasureMode>(
      valueListenable: AppUnits.mode,
      builder: (context, mode, _) {
        final rise = AppUnits.parseInput(_riseCtrl.text, mode);
        final roll = AppUnits.parseInput(_rollCtrl.text, mode);
        final m = AppUnits.multipliers[_angle]!;
        final trueOff = (rise == null || roll == null)
            ? null
            : sqrt(rise * rise + roll * roll);
        final dist = trueOff == null ? null : trueOff * m;

        return ProCalcScaffold(
          title: 'Rolling Offset',
          inputBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ProLengthInput(
                      label: 'Rise',
                      controller: _riseCtrl,
                      mode: mode,
                      onChanged: () => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ProLengthInput(
                      label: 'Roll',
                      controller: _rollCtrl,
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
          body: dist == null
              ? const Center(
                  child: Text('Enter rise and roll',
                      style: TextStyle(color: ProTheme.textDim)))
              : ProDragDiagram(
                  painter: _RollingPainter(
                    riseIn: rise!,
                    distLabel: AppUnits.format(dist, mode),
                    riseLabel: AppUnits.format(rise, mode),
                  ),
                  onDragY: (dy, size) {
                    final frac =
                        ((150 - dy) / 110).clamp(0.02, 1.0);
                    var v = (frac * 24).clamp(0.5, 24.0);
                    v = (v * 2).round() / 2;
                    _riseCtrl.text = AppUnits.formatInput(v, mode);
                    setState(() {});
                  },
                ),
          resultBar: dist == null
              ? const ProResultBar(label: 'Between marks', value: '—')
              : ProResultBar(
                  label: 'Between marks',
                  value: AppUnits.format(dist, mode),
                  fraction: (mode != MeasureMode.centimeters)
                      ? AppUnits.fraction(dist)
                      : null,
                  onSave: () {
                    final summary =
                        'Rolling offset rise ${AppUnits.format(rise!, mode)} roll ${AppUnits.format(roll!, mode)} → ${AppUnits.format(dist, mode)} apart';
                    HistoryStore.add('Rolling Offset', summary).then((_) =>
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Saved to history'))));
                  },
                  onSteps: () => showStepsSheet(context, 'Marking steps', [
                    'True offset = ${AppUnits.format(trueOff!, mode)} (rise² + roll²).',
                    'Mark 1, then measure ${AppUnits.format(dist, mode)} for Mark 2.',
                    'Bend both to ${AppUnits.angleLabel(_angle)}, rolling the conduit between bends.',
                    'Rotate the conduit so the offset kicks toward your target.',
                  ]),
                ),
        );
      },
    );
  }
}

class _RollingPainter extends CustomPainter {
  final double riseIn;
  final String distLabel;
  final String riseLabel;
  _RollingPainter(
      {required this.riseIn, required this.distLabel, required this.riseLabel});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    const y0 = 150.0;
    final frac = (riseIn / 24).clamp(0.04, 1.0);
    final y1 = y0 - frac * 110;
    final m1x = w * 0.36, m2x = w * 0.64;
    ProPipe.draw(canvas, [
      Offset(14, y0),
      Offset(m1x, y0),
      Offset(m2x, y1),
      Offset(w - 14, y1),
    ]);
    ProPipe.mark(canvas, Offset(m1x, y0), '1');
    ProPipe.mark(canvas, Offset(m2x, y1), '2');
    ProPipe.dim(canvas, Offset(m1x, 28), Offset(m2x, 28), distLabel);
    ProPipe.dim(canvas, Offset(w - 30, y1), Offset(w - 30, y0), riseLabel);
    ProPipe.label(canvas, 'drag pipe ↕', Offset(w / 2, size.height - 16),
        size: 11, color: ProTheme.textDim);
  }

  @override
  bool shouldRepaint(covariant _RollingPainter old) =>
      old.riseIn != riseIn || old.distLabel != distLabel;
}
