import 'package:flutter/material.dart';
import '../store.dart';
import '../units.dart';
import '../widgets.dart';

/// Shrink reference: how much a bend pulls the run back, per inch of
/// offset, for every standard bender angle. The numbers off the handle.
class ShrinkScreen extends StatelessWidget {
  const ShrinkScreen({super.key});

  /// Shrink per inch of offset for standard angles (multiplier − cosecant
  /// relationship reduced to the trade table values). (Non-const: double keys
  /// are not allowed in const maps.)
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
    return CalcScaffold(
      title: 'Shrink Chart',
      subtitle:
          'How much each bend pulls your run back — per inch of offset, by angle.',
      builder: (context, mode) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HintCard(
                'Shrink = offset × the factor below. Start your first mark that far before the measured point.'),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SHRINK PER INCH OF OFFSET',
                      style: TextStyle(
                        color: kAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...shrinkPerInch.entries.map((e) {
                      final perInch = e.value;
                      final perInchDisplay = mode == MeasureMode.centimeters
                          ? '${(perInch * AppUnits.inchToCm).toStringAsFixed(2)} cm/cm'
                          : '${perInch.toStringAsFixed(2)}"/in';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 52,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 6, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: kAccent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    AppUnits.angleLabel(e.key),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: kAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '× ${AppUnits.multLabel(AppUnits.multipliers[e.key]!)} mult',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                            Text(
                              perInchDisplay,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'HOW TO USE IT',
                      style: TextStyle(
                        color: kAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '1. Measure where the bend should land.\n'
                      '2. Multiply your offset by the shrink factor.\n'
                      '3. Make your first mark that far BEFORE the measured point.\n'
                      '4. The bend will pull the conduit back exactly onto your mark.',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 14, height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
