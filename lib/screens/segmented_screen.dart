import 'package:flutter/material.dart';
import '../pro_widgets.dart';
import '../store.dart';
import '../units.dart';

/// Segmented 90° — pro layout.
class SegmentedScreen extends StatefulWidget {
  const SegmentedScreen({super.key});

  @override
  State<SegmentedScreen> createState() => _SegmentedScreenState();
}

class _SegmentedScreenState extends State<SegmentedScreen> {
  final _radiusCtrl = TextEditingController(text: '12');
  int _shots = 5;

  @override
  void dispose() {
    _radiusCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MeasureMode>(
      valueListenable: AppUnits.mode,
      builder: (context, mode, _) {
        final r = AppUnits.parseInput(_radiusCtrl.text, mode);
        final perShot = 90.0 / _shots;
        final spacing =
            r == null ? null : (3.14159265 / 2 * r) / _shots;

        return ProCalcScaffold(
          title: 'Segmented 90°',
          inputBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProLengthInput(
                label: 'Centerline radius',
                controller: _radiusCtrl,
                mode: mode,
                onChanged: () => setState(() {}),
                step: 1,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 6,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final n = [3, 4, 5, 6, 8, 10][i];
                    final sel = n == _shots;
                    return ChoiceChip(
                      label: Text('$n shots'),
                      selected: sel,
                      onSelected: (_) => setState(() => _shots = n),
                      selectedColor: ProTheme.accent,
                      backgroundColor: ProTheme.surface,
                      side: BorderSide(
                          color: sel ? ProTheme.accent : ProTheme.border),
                      labelStyle: TextStyle(
                        color: sel ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          body: spacing == null
              ? const Center(
                  child: Text('Enter the radius',
                      style: TextStyle(color: ProTheme.textDim)))
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${perShot.toStringAsFixed(1)}°',
                        style: const TextStyle(
                          color: ProTheme.accent,
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('per shot',
                          style: TextStyle(
                              color: ProTheme.textDim, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                        '$_shots shots × ${AppUnits.format(spacing, mode)} apart',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
          resultBar: spacing == null
              ? const ProResultBar(label: 'Spacing between shots', value: '—')
              : ProResultBar(
                  label: 'Spacing between shots',
                  value: AppUnits.format(spacing, mode),
                  fraction: (mode != MeasureMode.centimeters)
                      ? AppUnits.fraction(spacing)
                      : null,
                  onSave: () {
                    final summary =
                        'Segmented 90° r=${AppUnits.format(r!, mode)} $_shots shots → ${AppUnits.format(spacing, mode)} apart';
                    HistoryStore.add('Segmented 90°', summary).then((_) =>
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Saved to history'))));
                  },
                  onSteps: () => showStepsSheet(context, 'Marking steps', [
                    'Mark shot 1 where the bend begins.',
                    'Space each mark ${AppUnits.format(spacing, mode)} apart — $_shots total.',
                    'Bend ${perShot.toStringAsFixed(1)}° at each mark, in order.',
                    'Do not flip the conduit between shots.',
                  ]),
                ),
        );
      },
    );
  }
}
