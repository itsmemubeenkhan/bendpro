import 'package:flutter/material.dart';
import '../diagrams.dart';
import '../store.dart';
import '../units.dart';
import '../widgets.dart';

/// Concentric 90° bends: bend 2–4 conduits so they run parallel with
/// even spacing — the pro look for exposed runs.
///
/// Math: each outer conduit's stub grows by the spacing, and its mark
/// moves out by (spacing × pi/2) to account for the longer 90° arc.
class ConcentricScreen extends StatefulWidget {
  const ConcentricScreen({super.key});

  @override
  State<ConcentricScreen> createState() => _ConcentricScreenState();
}

class _ConcentricScreenState extends State<ConcentricScreen> {
  final _stubCtrl = TextEditingController();
  final _spacingCtrl = TextEditingController();
  int _count = 3;
  String _size = '3/4"';
  Map<String, double> _deducts = Map.of(ProfileStore.standardDeducts);
  String? _profileName;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final deducts = await ProfileStore.activeDeducts();
    final active = await ProfileStore.activeName();
    if (mounted) {
      setState(() {
        _deducts = deducts;
        _profileName = active;
      });
    }
  }

  @override
  void dispose() {
    _stubCtrl.dispose();
    _spacingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CalcScaffold(
      title: 'Concentric 90°s',
      subtitle:
          'Bend multiple conduits in parallel with even spacing — the clean, professional look.',
      builder: (context, mode) {
        final stub = AppUnits.parseInput(_stubCtrl.text, mode);
        final sp = AppUnits.parseInput(_spacingCtrl.text, mode);
        final deduct = _deducts[_size]!;
        final ready = stub != null && sp != null && sp > 0;

        final fields = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LengthField(
              label: 'First (inner) stub height',
              controller: _stubCtrl,
              mode: mode,
              onChanged: () => setState(() {}),
            ),
            LengthField(
              label: 'Center-to-center spacing',
              controller: _spacingCtrl,
              mode: mode,
              onChanged: () => setState(() {}),
            ),
            const SectionLabel('NUMBER OF CONDUITS'),
            Wrap(
              spacing: 8,
              children: [2, 3, 4].map((n) {
                final sel = n == _count;
                return ChoiceChip(
                  label: Text('$n'),
                  selected: sel,
                  onSelected: (_) => setState(() => _count = n),
                  selectedColor: kAccent,
                  labelStyle: TextStyle(
                    color: sel ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
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
                  'Enter the first stub height and the spacing to lay out every conduit.'),
            ],
          );
        }

        final s = stub!, spacing = sp!;
        final rows = List.generate(_count, (i) {
          final stubH = s + i * spacing;
          final mark = stubH - deduct;
          return (n: i + 1, stubH: stubH, mark: mark);
        });
        final summary =
            'Concentric 90°s ×$_count, spacing ${AppUnits.format(spacing, mode)} → marks ${rows.map((r) => AppUnits.format(r.mark, mode)).join(', ')}';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            fields,
            DiagramCard(
              painter: ConcentricBendPainter(
                count: _count,
                spacingLabel: AppUnits.format(spacing, mode),
              ),
              height: 210,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MARK PER CONDUIT',
                      style: TextStyle(
                        color: kAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...rows.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Conduit ${r.n} — stub ${AppUnits.format(r.stubH, mode)}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14)),
                              Text('mark ${AppUnits.format(r.mark, mode)}',
                                  style: const TextStyle(
                                      color: kAccent,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )),
                    const Divider(height: 20, color: Colors.white12),
                    Text(
                      'Bend the outer conduits first — they need the most room. Deduct ${AppUnits.format(deduct, mode)} ($_size).',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ResultCard(
              label: 'First mark (conduit 1)',
              value: AppUnits.format(rows.first.mark, mode),
              inchesValue: rows.first.mark,
              mode: mode,
              note: 'Each outer conduit adds ${AppUnits.format(spacing, mode)} to stub and mark',
              onSave: () => HistoryStore.add('Concentric 90°s', summary).then(
                  (_) => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved to history')))),
            ),
          ],
        );
      },
    );
  }
}
