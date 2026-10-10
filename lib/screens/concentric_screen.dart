import 'package:flutter/material.dart';
import '../pro_widgets.dart';
import '../store.dart';
import '../units.dart';

/// Concentric 90°s — pro layout.
class ConcentricScreen extends StatefulWidget {
  const ConcentricScreen({super.key});

  @override
  State<ConcentricScreen> createState() => _ConcentricScreenState();
}

class _ConcentricScreenState extends State<ConcentricScreen> {
  final _stubCtrl = TextEditingController(text: '24');
  final _spacingCtrl = TextEditingController(text: '2');
  int _count = 3;
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
    _stubCtrl.dispose();
    _spacingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MeasureMode>(
      valueListenable: AppUnits.mode,
      builder: (context, mode, _) {
        final stub = AppUnits.parseInput(_stubCtrl.text, mode);
        final sp = AppUnits.parseInput(_spacingCtrl.text, mode);
        final deduct = _deducts[_size] ?? 6.0;
        final ready = stub != null && sp != null && sp > 0;
        final rows = ready
            ? List.generate(_count, (i) {
                final stubH = stub! + i * sp!;
                return (n: i + 1, mark: stubH - deduct);
              })
            : <({int n, double mark})>[];

        return ProCalcScaffold(
          title: 'Concentric 90°s',
          inputBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ProLengthInput(
                      label: 'First stub',
                      controller: _stubCtrl,
                      mode: mode,
                      onChanged: () => setState(() {}),
                      step: 1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ProLengthInput(
                      label: 'Spacing',
                      controller: _spacingCtrl,
                      mode: mode,
                      onChanged: () => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final n = [2, 3, 4][i];
                    final sel = n == _count;
                    return ChoiceChip(
                      label: Text('$n conduits'),
                      selected: sel,
                      onSelected: (_) => setState(() => _count = n),
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
          body: !ready
              ? const Center(
                  child: Text('Enter stub and spacing',
                      style: TextStyle(color: ProTheme.textDim)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final r = rows[i];
                    return Container(
                      decoration: BoxDecoration(
                        color: ProTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ProTheme.border),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Conduit ${r.n}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          Text(
                              'mark ${AppUnits.format(r.mark, mode)}',
                              style: const TextStyle(
                                  color: ProTheme.accent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),
          resultBar: rows.isEmpty
              ? const ProResultBar(label: 'First mark', value: '—')
              : ProResultBar(
                  label: 'First mark (conduit 1)',
                  value: AppUnits.format(rows.first.mark, mode),
                  onSave: () {
                    final summary =
                        'Concentric ×$_count spacing ${AppUnits.format(sp!, mode)} → ${rows.map((r) => AppUnits.format(r.mark, mode)).join(', ')}';
                    HistoryStore.add('Concentric 90°s', summary).then((_) =>
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Saved to history'))));
                  },
                  onSteps: () => showStepsSheet(context, 'Marking steps', [
                    'Bend the OUTER conduit first (needs most room).',
                    ...rows.map((r) =>
                        'Conduit ${r.n}: mark at ${AppUnits.format(r.mark, mode)}.'),
                    'Bend each 90° with the arrow on its mark.',
                  ]),
                ),
        );
      },
    );
  }
}
