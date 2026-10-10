import 'package:flutter/material.dart';
import '../pro_bender.dart';
import '../pro_widgets.dart';
import '../store.dart';
import '../units.dart';

/// Kick — pro layout: depth input, interactive bender for angle,
/// pinned result bar. No scrolling.
class KickScreen extends StatefulWidget {
  const KickScreen({super.key});

  @override
  State<KickScreen> createState() => _KickScreenState();
}

class _KickScreenState extends State<KickScreen> {
  final _depthCtrl = TextEditingController(text: '4');
  double _angle = 30;

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
        final m = AppUnits.multipliers[_angle]!;
        final dist = d == null ? null : d * m;

        return ProCalcScaffold(
          title: 'Kick',
          inputBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProLengthInput(
                label: 'Kick depth',
                controller: _depthCtrl,
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
              ? const ProResultBar(label: 'Mark from the end', value: '—')
              : ProResultBar(
                  label: 'Mark from the end',
                  value: AppUnits.format(dist, mode),
                  fraction: (mode != MeasureMode.centimeters)
                      ? AppUnits.fraction(dist)
                      : null,
                  onSave: () {
                    final summary =
                        'Kick ${AppUnits.format(d!, mode)} @ ${AppUnits.angleLabel(_angle)} → mark ${AppUnits.format(dist, mode)} from end';
                    HistoryStore.add('Kick', summary).then((_) =>
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Saved to history'))));
                  },
                  onSteps: () => showStepsSheet(context, 'Marking steps', [
                    'Measure ${AppUnits.format(dist, mode)} from the end and mark it.',
                    'Set the bender arrow exactly on the mark.',
                    'Pull the bend to ${AppUnits.angleLabel(_angle)}, keeping the conduit flat.',
                    'Check the kick — the end should sit ${AppUnits.format(d!, mode)} off the surface.',
                  ]),
                ),
        );
      },
    );
  }
}
