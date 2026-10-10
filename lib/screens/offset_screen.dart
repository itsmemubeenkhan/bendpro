import 'package:flutter/material.dart';
import '../pro_bender.dart';
import '../pro_widgets.dart';
import '../store.dart';
import '../units.dart';

/// Offset bend — pro layout: compact input, interactive bender,
/// pinned result bar. No scrolling.
class OffsetScreen extends StatefulWidget {
  const OffsetScreen({super.key});

  @override
  State<OffsetScreen> createState() => _OffsetScreenState();
}

class _OffsetScreenState extends State<OffsetScreen> {
  final _heightCtrl = TextEditingController(text: '6');
  double _angle = 30;

  @override
  void dispose() {
    _heightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MeasureMode>(
      valueListenable: AppUnits.mode,
      builder: (context, mode, _) {
        final h = AppUnits.parseInput(_heightCtrl.text, mode);
        final m = AppUnits.multipliers[_angle]!;
        final dist = h == null ? null : h * m;

        return ProCalcScaffold(
          title: 'Offset Bend',
          inputBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProLengthInput(
                label: 'Offset height',
                controller: _heightCtrl,
                mode: mode,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 10),
              ProAngleChips(
                selected: _angle,
                onSelected: (a) => setState(() => _angle = a),
              ),
            ],
          ),
          body: ProBender(
            angleDeg: _angle,
            onAngleChanged: (a) => setState(() => _angle = a),
          ),
          resultBar: dist == null
              ? const ProResultBar(
                  label: 'Distance between marks',
                  value: '—',
                )
              : ProResultBar(
                  label: 'Distance between marks',
                  value: AppUnits.format(dist, mode),
                  fraction:
                      (mode != MeasureMode.centimeters) ? AppUnits.fraction(dist) : null,
                  onSave: () {
                    final summary =
                        'Offset ${AppUnits.format(h!, mode)} @ ${AppUnits.angleLabel(_angle)} → marks ${AppUnits.format(dist, mode)} apart';
                    HistoryStore.add('Offset Bend', summary).then((_) =>
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Saved to history'))));
                  },
                  onSteps: () => showStepsSheet(context, 'Marking steps', [
                    'Mark 1 where the first bend begins.',
                    'Measure ${AppUnits.format(dist, mode)} from Mark 1 and make Mark 2.',
                    'Set the bender arrow on Mark 1 and bend to ${AppUnits.angleLabel(_angle)}.',
                    'Flip the conduit over, set the bender on Mark 2, and bend to ${AppUnits.angleLabel(_angle)} the opposite way.',
                    'Lay the conduit flat and check the offset — it should measure ${AppUnits.format(h!, mode)}.',
                  ]),
                ),
        );
      },
    );
  }
}
