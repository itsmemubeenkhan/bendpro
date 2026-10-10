import 'package:flutter/material.dart';
import '../diagrams.dart';
import '../store.dart';
import '../units.dart';
import '../widgets.dart';

/// Three-point saddle: jump over an obstruction with three bends —
/// a 45° center bend and two 22.5° outer bends.
///
/// Math (standard 45° saddle):
///   distance between the two outer marks = obstruction depth × 2.5
///   center mark sits exactly in the middle
///   shrink (run pulls back) = depth × 3/16 (0.1875) per inch of depth
class ThreePointSaddleScreen extends StatefulWidget {
  const ThreePointSaddleScreen({super.key});

  @override
  State<ThreePointSaddleScreen> createState() =>
      _ThreePointSaddleScreenState();
}

class _ThreePointSaddleScreenState extends State<ThreePointSaddleScreen> {
  final _depthCtrl = TextEditingController();

  @override
  void dispose() {
    _depthCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CalcScaffold(
      title: 'Three-Point Saddle',
      subtitle:
          'Three bends that hop the conduit over an obstruction and bring it back parallel — 45° in the middle, 22.5° on each side.',
      builder: (context, mode) {
        final d = AppUnits.parseInput(_depthCtrl.text, mode);
        final outer = d == null ? null : d * 2.5;
        final half = outer == null ? null : outer / 2;
        final shrink = d == null ? null : d * 0.1875;

        final fields = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LengthField(
              label: 'Obstruction depth',
              controller: _depthCtrl,
              mode: mode,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 4),
          ],
        );

        if (d == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              fields,
              const HintCard(
                  'Enter the obstruction depth to lay out the three marks.'),
            ],
          );
        }

        final summary =
            '3-pt saddle depth ${AppUnits.format(d, mode)} → outer marks ${AppUnits.format(outer!, mode)} apart';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            fields,
            DiagramCard(
              painter: ThreePointSaddlePainter(
                outerLabel: AppUnits.format(outer!, mode),
                depthLabel: AppUnits.format(d, mode),
              ),
            ),
            const SizedBox(height: 12),
            ResultCard(
              label: 'Distance between outer marks',
              value: AppUnits.format(outer!, mode),
              inchesValue: outer!,
              mode: mode,
              note: '${AppUnits.format(d, mode)} depth × 2.5 (45° saddle)',
              onSave: () =>
                  HistoryStore.add('Three-Point Saddle', summary).then(
                      (_) => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Saved to history')))),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 10),
                    _markRow('Mark A — first outer bend', 'start (0)'),
                    _markRow('Mark C — center bend (45°)',
                        AppUnits.format(half!, mode)),
                    _markRow('Mark B — second outer bend',
                        AppUnits.format(outer!, mode)),
                    const Divider(height: 20, color: Colors.white12),
                    Row(
                      children: [
                        const Icon(Icons.compress, color: kAccent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Shrink: the run pulls back ${AppUnits.format(shrink!, mode)} — start Mark A that far before your measured point.',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            StepsCard(
              title: 'Marking steps',
              steps: [
                'Find the center of the obstruction, transfer it to the conduit, and mark it C.',
                'Measure ${AppUnits.format(half!, mode)} each way from C and mark the outer bends A and B.',
                'Bend the center mark C to 45° first.',
                'Bend A and B to 22.5° each, in the opposite direction of the center bend.',
                'Lay it over the obstruction and check the fit — allow ${AppUnits.format(shrink!, mode)} of shrink in your layout.',
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
