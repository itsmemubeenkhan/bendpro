import 'dart:math';
import 'package:flutter/material.dart';
import '../diagrams.dart';
import '../store.dart';
import '../units.dart';
import '../widgets.dart';

/// Rolling offset: the obstacle is off to the side as well as up/down,
/// so the true offset is the hypotenuse of rise and roll.
///
/// Math: true offset = sqrt(rise² + roll²);
/// distance between marks = true offset × multiplier(angle).
class RollingOffsetScreen extends StatefulWidget {
  const RollingOffsetScreen({super.key});

  @override
  State<RollingOffsetScreen> createState() => _RollingOffsetScreenState();
}

class _RollingOffsetScreenState extends State<RollingOffsetScreen> {
  final _riseCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  double _angle = 30;

  @override
  void dispose() {
    _riseCtrl.dispose();
    _rollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CalcScaffold(
      title: 'Rolling Offset',
      subtitle:
          'When the obstacle is offset sideways too, combine the vertical rise and horizontal roll into one true offset.',
      builder: (context, mode) {
        final rise = AppUnits.parseInput(_riseCtrl.text, mode);
        final roll = AppUnits.parseInput(_rollCtrl.text, mode);
        final m = AppUnits.multipliers[_angle]!;
        final trueOffset = (rise == null || roll == null)
            ? null
            : sqrt(rise * rise + roll * roll);
        final dist = trueOffset == null ? null : trueOffset * m;

        final fields = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LengthField(
              label: 'Vertical rise',
              controller: _riseCtrl,
              mode: mode,
              onChanged: () => setState(() {}),
            ),
            LengthField(
              label: 'Horizontal roll',
              controller: _rollCtrl,
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
                  'Enter both the rise and the roll to get the true offset.'),
            ],
          );
        }

        final summary =
            'Rolling offset rise ${AppUnits.format(rise!, mode)} roll ${AppUnits.format(roll!, mode)} @ ${AppUnits.angleLabel(_angle)} → marks ${AppUnits.format(dist, mode)} apart';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            fields,
            DiagramCard(
              painter: RollingOffsetDiagramPainter(
                distLabel: AppUnits.format(dist, mode),
                riseLabel: AppUnits.format(rise!, mode),
                rollLabel: AppUnits.format(roll!, mode),
                trueLabel: AppUnits.format(trueOffset!, mode),
              ),
            ),
            const SizedBox(height: 12),
            ResultCard(
              label: 'Distance between bend marks',
              value: AppUnits.format(dist, mode),
              inchesValue: dist,
              mode: mode,
              note:
                  'True offset ${AppUnits.format(trueOffset, mode)} × multiplier ${AppUnits.multLabel(m)}',
              onSave: () => HistoryStore.add('Rolling Offset', summary).then(
                  (_) => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved to history')))),
            ),
            const SizedBox(height: 12),
            StepsCard(
              title: 'Marking steps',
              steps: [
                'Mark 1 where the first bend begins.',
                'Measure ${AppUnits.format(dist, mode)} from Mark 1 and make Mark 2.',
                'Roll the bender so the bend plane lines up with the true-offset direction, then bend Mark 1 to ${AppUnits.angleLabel(_angle)}.',
                'Rotate the conduit 180° around its own axis, set the bender on Mark 2, and bend to ${AppUnits.angleLabel(_angle)} the opposite way.',
                'Check the run: it should rise ${AppUnits.format(rise!, mode)} and roll ${AppUnits.format(roll!, mode)} off the original line.',
              ],
            ),
          ],
        );
      },
    );
  }
}
