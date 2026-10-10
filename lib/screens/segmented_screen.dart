import 'package:flutter/material.dart';
import '../diagrams.dart';
import '../store.dart';
import '../units.dart';
import '../widgets.dart';

/// Segmented 90° bend (sweep): divide a 90° bend into equal shots for
/// large conduit or when a tight 90° would kink.
///
/// Math: each shot bends (90 / shots) degrees; marks are spaced evenly
/// along the developed arc: spacing = (pi/2 * radius) / shots.
class SegmentedScreen extends StatefulWidget {
  const SegmentedScreen({super.key});

  @override
  State<SegmentedScreen> createState() => _SegmentedScreenState();
}

class _SegmentedScreenState extends State<SegmentedScreen> {
  final _radiusCtrl = TextEditingController();
  int _shots = 5;

  @override
  void dispose() {
    _radiusCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CalcScaffold(
      title: 'Segmented 90°',
      subtitle:
          'Split a 90° bend into equal shots for a smooth sweep — no kinks in large conduit.',
      builder: (context, mode) {
        final r = AppUnits.parseInput(_radiusCtrl.text, mode);
        final perShot = 90.0 / _shots;
        final developed = r == null ? null : (3.14159265 / 2) * r;
        final spacing = developed == null ? null : developed / _shots;

        final fields = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LengthField(
              label: 'Centerline radius',
              controller: _radiusCtrl,
              mode: mode,
              onChanged: () => setState(() {}),
            ),
            const SectionLabel('NUMBER OF SHOTS'),
            Wrap(
              spacing: 8,
              children: [3, 4, 5, 6, 8, 10].map((n) {
                final sel = n == _shots;
                return ChoiceChip(
                  label: Text('$n'),
                  selected: sel,
                  onSelected: (_) => setState(() => _shots = n),
                  selectedColor: kAccent,
                  labelStyle: TextStyle(
                    color: sel ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        );

        if (r == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              fields,
              const HintCard(
                  'Enter the centerline radius to lay out the shots.'),
            ],
          );
        }

        final summary =
            'Segmented 90°: radius ${AppUnits.format(r, mode)}, $_shots shots → ${AppUnits.format(spacing!, mode)} apart, ${perShot.toStringAsFixed(1)}° each';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            fields,
            DiagramCard(
              painter: SegmentedBendPainter(
                shots: _shots,
                spacingLabel: AppUnits.format(spacing!, mode),
                radiusLabel: AppUnits.format(r, mode),
              ),
              height: 210,
            ),
            const SizedBox(height: 12),
            ResultCard(
              label: 'Spacing between shot marks',
              value: AppUnits.format(spacing!, mode),
              inchesValue: spacing!,
              mode: mode,
              note:
                  '$_shots shots × ${perShot.toStringAsFixed(1)}° each · total arc ${AppUnits.format(developed!, mode)}',
              onSave: () => HistoryStore.add('Segmented 90°', summary).then(
                  (_) => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved to history')))),
            ),
            const SizedBox(height: 12),
            StepsCard(
              title: 'Marking steps',
              steps: [
                'Mark shot 1 where the bend begins.',
                'Measure ${AppUnits.format(spacing!, mode)} and mark each next shot — $_shots shots total.',
                'Set the bender on each mark in order and bend ${perShot.toStringAsFixed(1)}° — use a protractor or angle finder.',
                'Work from one end to the other without flipping the conduit.',
                'Check the sweep against your radius — adjust the last shot if needed.',
              ],
            ),
          ],
        );
      },
    );
  }
}
