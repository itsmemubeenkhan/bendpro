import 'package:flutter/material.dart';
import '../diagrams.dart';
import '../store.dart';
import '../units.dart';
import '../widgets.dart';

/// Back-to-back 90s: two 90° bends facing the same way with a straight
/// section between — for going up, across, and up again (or down twice).
///
/// Math: mark 1 at (leg − deduct) from the end; bend 90°; then measure
/// the between-bends distance from the back of bend 1 and mark 2.
class BackToBackScreen extends StatefulWidget {
  const BackToBackScreen({super.key});

  @override
  State<BackToBackScreen> createState() => _BackToBackScreenState();
}

class _BackToBackScreenState extends State<BackToBackScreen> {
  final _legCtrl = TextEditingController();
  final _betweenCtrl = TextEditingController();
  String _size = '3/4"';
  Map<String, double> _deducts = Map.of(ProfileStore.standardDeducts);

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final deducts = await ProfileStore.activeDeducts();
    if (mounted) setState(() => _deducts = deducts);
  }

  @override
  void dispose() {
    _legCtrl.dispose();
    _betweenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CalcScaffold(
      title: 'Back-to-Back 90s',
      subtitle:
          'Two 90° bends with a straight run between — up, across, and up again.',
      builder: (context, mode) {
        final leg = AppUnits.parseInput(_legCtrl.text, mode);
        final between = AppUnits.parseInput(_betweenCtrl.text, mode);
        final deduct = _deducts[_size]!;
        final mark1 = leg == null ? null : leg - deduct;
        final ready = mark1 != null && mark1 > 0 && between != null;

        final fields = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LengthField(
              label: 'Leg height (each end)',
              controller: _legCtrl,
              mode: mode,
              onChanged: () => setState(() {}),
            ),
            LengthField(
              label: 'Distance between bends',
              controller: _betweenCtrl,
              mode: mode,
              onChanged: () => setState(() {}),
            ),
            const SectionLabel('CONDUIT SIZE'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ProfileStore.sizes.map((s) {
                final sel = s == _size;
                return ChoiceChip(
                  label: Text(s),
                  selected: sel,
                  onSelected: (_) => setState(() => _size = s),
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

        if (!ready) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              fields,
              const HintCard(
                  'Enter the leg height and the distance between bends.'),
            ],
          );
        }

        final summary =
            'Back-to-back 90s: legs ${AppUnits.format(leg!, mode)}, ${AppUnits.format(between!, mode)} apart → mark 1 at ${AppUnits.format(mark1!, mode)}';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            fields,
            DiagramCard(
              painter: BackToBackPainter(
                betweenLabel: AppUnits.format(between!, mode),
                legLabel: AppUnits.format(leg!, mode),
              ),
              height: 210,
            ),
            const SizedBox(height: 12),
            ResultCard(
              label: 'Mark 1 (from the end)',
              value: AppUnits.format(mark1!, mode),
              inchesValue: mark1!,
              mode: mode,
              note:
                  '${AppUnits.format(leg!, mode)} leg − ${AppUnits.format(deduct, mode)} deduct',
              onSave: () => HistoryStore.add('Back-to-Back 90s', summary).then(
                  (_) => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved to history')))),
            ),
            const SizedBox(height: 12),
            StepsCard(
              title: 'Marking steps',
              steps: [
                'Measure ${AppUnits.format(mark1!, mode)} from the end and mark 1.',
                'Bend 90° with the bender arrow on mark 1.',
                'From the back of bend 1, measure ${AppUnits.format(between!, mode)} along the straight and mark 2.',
                'Flip the conduit end-for-end, set the arrow on mark 2, and bend 90° the same direction.',
                'Check both legs — each should stand ${AppUnits.format(leg!, mode)} tall.',
              ],
            ),
          ],
        );
      },
    );
  }
}
