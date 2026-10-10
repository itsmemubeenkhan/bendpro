import 'package:flutter/material.dart';
import '../diagrams.dart';
import '../store.dart';
import '../units.dart';
import '../widgets.dart';

/// Four-point saddle: cross a wide, low obstruction with what is
/// effectively two offsets back to back.
///
/// Math: each offset's mark spacing = obstruction depth × multiplier(angle).
/// Layout from the start of the saddle:
///   M1 at 0 → M2 at (depth × multiplier) → M3 at M2 + width →
///   M4 at M3 + (depth × multiplier)
class FourPointSaddleScreen extends StatefulWidget {
  const FourPointSaddleScreen({super.key});

  @override
  State<FourPointSaddleScreen> createState() => _FourPointSaddleScreenState();
}

class _FourPointSaddleScreenState extends State<FourPointSaddleScreen> {
  final _depthCtrl = TextEditingController();
  final _widthCtrl = TextEditingController();
  double _angle = 30;

  @override
  void dispose() {
    _depthCtrl.dispose();
    _widthCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CalcScaffold(
      title: 'Four-Point Saddle',
      subtitle:
          'Two offsets back to back that carry the conduit over a wide obstruction and return it parallel.',
      builder: (context, mode) {
        final d = AppUnits.parseInput(_depthCtrl.text, mode);
        final w = AppUnits.parseInput(_widthCtrl.text, mode);
        final m = AppUnits.multipliers[_angle]!;
        final each = d == null ? null : d * m;
        final ready = each != null && w != null;
        // Fractions of diagram width for the four marks.
        List<double> fx = const [0.18, 0.40, 0.62, 0.84];

        final fields = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LengthField(
              label: 'Obstruction depth',
              controller: _depthCtrl,
              mode: mode,
              onChanged: () => setState(() {}),
            ),
            LengthField(
              label: 'Obstruction width',
              controller: _widthCtrl,
              mode: mode,
              onChanged: () => setState(() {}),
            ),
            const SectionLabel('BEND ANGLE'),
            AngleChips(
              selected: _angle,
              onSelected: (a) => setState(() => _angle = a),
            ),
            const SizedBox(height: 16),
          ],
        );

        if (!ready) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              fields,
              const HintCard(
                  'Enter the obstruction depth and width to lay out the four marks.'),
            ],
          );
        }

        final e = each!;
        final ww = w!;
        final m2 = e;
        final m3 = e + ww;
        final m4 = 2 * e + ww;
        final summary =
            '4-pt saddle depth ${AppUnits.format(d!, mode)} width ${AppUnits.format(ww, mode)} @ ${AppUnits.angleLabel(_angle)} → M1–M4 span ${AppUnits.format(m4, mode)}';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            fields,
            DragDiagramCard(
              painter: FourPointSaddlePainter(
                fx: fx,
                segLabels: [
                  AppUnits.format(e, mode),
                  AppUnits.format(ww, mode),
                  AppUnits.format(e, mode),
                ],
                depthInches: d!,
              ),
              onDrag: (pos, size) {
                final v = FourPointSaddlePainter.depthFromDragY(pos.dy);
                final snapped = mode == MeasureMode.centimeters
                    ? (v * AppUnits.inchToCm).roundToDouble() / AppUnits.inchToCm
                    : (v * 2).round() / 2;
                _depthCtrl.text = AppUnits.formatInput(snapped, mode);
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'MARK LAYOUT',
                          style: TextStyle(
                            color: kAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.8,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Save to history',
                          icon: const Icon(Icons.bookmark_add_outlined,
                              color: kAccent),
                          onPressed: () =>
                              HistoryStore.add('Four-Point Saddle', summary)
                                  .then((_) => ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                          content:
                                              Text('Saved to history')))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _markRow('Mark 1 — first bend', 'start (0)'),
                    _markRow(
                        'Mark 2 — second bend', AppUnits.format(m2, mode)),
                    _markRow(
                        'Mark 3 — third bend', AppUnits.format(m3, mode)),
                    _markRow(
                        'Mark 4 — fourth bend', AppUnits.format(m4, mode)),
                    const Divider(height: 20, color: Colors.white12),
                    Text(
                      'Each offset spans ${AppUnits.format(e, mode)} (${AppUnits.format(d!, mode)} × ${AppUnits.multLabel(m)}) with ${AppUnits.format(ww, mode)} of level run between them.',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            StepsCard(
              title: 'Marking steps',
              steps: [
                'Mark 1 at 0, where the saddle starts.',
                'Mark 2 at ${AppUnits.format(m2, mode)} from Mark 1. Bend Mark 1 to ${AppUnits.angleLabel(_angle)}, then Mark 2 to ${AppUnits.angleLabel(_angle)} the opposite way — the conduit now runs level above the obstruction.',
                'Mark 3 at ${AppUnits.format(m3, mode)} from Mark 1 (${AppUnits.format(ww, mode)} past Mark 2). Bend Mark 3 to ${AppUnits.angleLabel(_angle)} downward.',
                'Mark 4 at ${AppUnits.format(m4, mode)} from Mark 1. Bend Mark 4 to ${AppUnits.angleLabel(_angle)} the opposite way to come back parallel with the run.',
                'Set it over the obstruction and check that it clears with room to spare.',
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _markRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  color: kAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
