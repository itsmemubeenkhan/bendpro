import 'package:flutter/material.dart';
import '../pro_widgets.dart';
import '../units.dart';

/// Shrink Chart — pro layout (reference table).
class ShrinkScreen extends StatelessWidget {
  const ShrinkScreen({super.key});

  static final Map<double, double> shrinkPerInch = {
    10: 0.06,
    15: 0.11,
    22.5: 0.20,
    30: 0.25,
    45: 0.41,
    60: 0.58,
  };

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MeasureMode>(
      valueListenable: AppUnits.mode,
      builder: (context, mode, _) {
        return Scaffold(
          backgroundColor: ProTheme.bg,
          appBar: AppBar(
            backgroundColor: ProTheme.bg,
            elevation: 0,
            title: const Text('Shrink Chart',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            actions: const [ProUnitToggle()],
          ),
          body: SafeArea(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: shrinkPerInch.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Pullback per inch of offset — start your first mark this far early.',
                      style: TextStyle(
                          color: ProTheme.textDim, fontSize: 14),
                    ),
                  );
                }
                final e = shrinkPerInch.entries.elementAt(i - 1);
                final display = mode == MeasureMode.centimeters
                    ? '${(e.value * 2.54).toStringAsFixed(2)} cm'
                    : '${e.value.toStringAsFixed(2)}"';
                return Container(
                  decoration: BoxDecoration(
                    color: ProTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ProTheme.border),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: ProTheme.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          AppUnits.angleLabel(e.key),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: ProTheme.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          '× ${AppUnits.multLabel(AppUnits.multipliers[e.key]!)} multiplier',
                          style: const TextStyle(
                              color: ProTheme.textDim, fontSize: 13),
                        ),
                      ),
                      Text(
                        display,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
