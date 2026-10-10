import 'package:flutter/material.dart';
import '../diagrams.dart';
import '../store.dart';
import '../units.dart';
import '../widgets.dart';

/// Kick (a single bend): moves the end of the conduit off the mounting
/// surface by the kick depth.
///
/// Math: mark distance from the end = kick depth × multiplier(angle),
/// then bend once to the chosen angle with the bender arrow on the mark.
class KickScreen extends StatefulWidget {
  const KickScreen({super.key});

  @override
  State<KickScreen> createState() => _KickScreenState();
}

class _KickScreenState extends State<KickScreen> {
  final _depthCtrl = TextEditingController();
  double _angle = 30;

  @override
  void dispose() {
    _depthCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CalcScaffold(
      title: 'Kick (90°)',
      subtitle:
          'A single bend near the end of the conduit that kicks it off the mounting surface by the depth you need.',
      builder: (context, mode) {
        final d = AppUnits.parseInput(_depthCtrl.text, mode);
        final m = AppUnits.multipliers[_angle]!;
        final dist = d == null ? null : d * m;

        final fields = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LengthField(
              label: 'Kick depth',
              controller: _depthCtrl,
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

        if (dist == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              fields,
              const HintCard(
                  'Enter the kick depth to find where to mark the bend.'),
            ],
          );
        }

        final summary =
            'Kick ${AppUnits.format(d!, mode)} @ ${AppUnits.angleLabel(_angle)} → mark ${AppUnits.format(dist, mode)} from end';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            fields,
            DragDiagramCard(
              painter: KickDiagramPainter(
                markLabel: AppUnits.format(dist, mode),
                depthLabel: AppUnits.format(d!, mode),
                angleDeg: _angle,
              ),
              onDrag: (pos, size) {
                final raw = KickDiagramPainter.angleFromDrag(pos);
                // Snap to the nearest standard bender angle.
                double best = AppUnits.angles.first;
                var bestDiff = (raw - best).abs();
                for (final a in AppUnits.angles) {
                  final diff = (raw - a).abs();
                  if (diff < bestDiff) {
                    bestDiff = diff;
                    best = a;
                  }
                }
                if (best != _angle) setState(() => _angle = best);
              },
            ),
            const SizedBox(height: 12),
            ResultCard(
              label: 'Mark distance from the end',
              value: AppUnits.format(dist, mode),
              inchesValue: dist,
              mode: mode,
              note:
                  '${AppUnits.format(d!, mode)} kick × multiplier ${AppUnits.multLabel(m)}',
              onSave: () => HistoryStore.add('Kick', summary).then(
                  (_) => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved to history')))),
            ),
            const SizedBox(height: 12),
            StepsCard(
              title: 'Marking steps',
              steps: [
                'Measure ${AppUnits.format(dist, mode)} from the end of the conduit and mark it.',
                'Set the bender arrow exactly on the mark.',
                'Pull the bend to ${AppUnits.angleLabel(_angle)}, keeping the conduit flat in the bender.',
                'Check the kick — the end should sit ${AppUnits.format(d!, mode)} off the surface.',
              ],
            ),
          ],
        );
      },
    );
  }
}
