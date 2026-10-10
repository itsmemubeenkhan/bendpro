import 'package:flutter/material.dart';
import '../diagrams.dart';
import '../store.dart';
import '../units.dart';
import '../widgets.dart';

/// Offset bend: two equal bends that shift the conduit around an obstacle
/// while keeping it parallel to the original run.
///
/// Math: distance between bend marks = offset height × multiplier,
/// where multiplier = 1 / sin(angle).
class OffsetScreen extends StatefulWidget {
  const OffsetScreen({super.key});

  @override
  State<OffsetScreen> createState() => _OffsetScreenState();
}

class _OffsetScreenState extends State<OffsetScreen> {
  final _heightCtrl = TextEditingController();
  double _angle = 30;

  @override
  void dispose() {
    _heightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CalcScaffold(
      title: 'Offset Bend',
      subtitle:
          'Two equal bends that move the conduit around an obstacle while keeping it parallel to the run.',
      builder: (context, mode) {
        final h = AppUnits.parseInput(_heightCtrl.text, mode);
        final m = AppUnits.multipliers[_angle]!;
        final dist = h == null ? null : h * m;

        final fields = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LengthField(
              label: 'Offset height',
              controller: _heightCtrl,
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
                  'Enter the offset height above to get the mark spacing.'),
            ],
          );
        }

        final summary =
            'Offset ${AppUnits.format(h!, mode)} @ ${AppUnits.angleLabel(_angle)} → marks ${AppUnits.format(dist, mode)} apart';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            fields,
            DiagramCard(
              painter: OffsetDiagramPainter(
                distLabel: AppUnits.format(dist, mode),
                heightLabel: AppUnits.format(h!, mode),
              ),
            ),
            const SizedBox(height: 12),
            ResultCard(
              label: 'Distance between bend marks',
              value: AppUnits.format(dist, mode),
              inchesValue: dist,
              mode: mode,
              note:
                  'Multiplier ${AppUnits.multLabel(m)} × ${AppUnits.format(h!, mode)} offset',
              onSave: () => HistoryStore.add('Offset Bend', summary).then(
                  (_) => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved to history')))),
            ),
            const SizedBox(height: 12),
            StepsCard(
              title: 'Marking steps',
              steps: [
                'Mark 1 where the first bend begins.',
                'Measure ${AppUnits.format(dist, mode)} from Mark 1 and make Mark 2.',
                'Set the bender arrow on Mark 1 and bend to ${AppUnits.angleLabel(_angle)}.',
                'Flip the conduit over, set the bender on Mark 2, and bend to ${AppUnits.angleLabel(_angle)} the opposite way.',
                'Lay the conduit flat and check the offset — it should measure ${AppUnits.format(h!, mode)}.',
              ],
            ),
          ],
        );
      },
    );
  }
}
