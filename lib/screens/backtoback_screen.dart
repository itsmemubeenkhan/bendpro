import 'package:flutter/material.dart';
import '../pro_widgets.dart';
import '../store.dart';
import '../units.dart';

/// Back-to-Back 90s — pro layout.
class BackToBackScreen extends StatefulWidget {
  const BackToBackScreen({super.key});

  @override
  State<BackToBackScreen> createState() => _BackToBackScreenState();
}

class _BackToBackScreenState extends State<BackToBackScreen> {
  final _legCtrl = TextEditingController(text: '18');
  final _betweenCtrl = TextEditingController(text: '24');
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
    return ValueListenableBuilder<MeasureMode>(
      valueListenable: AppUnits.mode,
      builder: (context, mode, _) {
        final leg = AppUnits.parseInput(_legCtrl.text, mode);
        final between = AppUnits.parseInput(_betweenCtrl.text, mode);
        final deduct = _deducts[_size] ?? 6.0;
        final mark1 = leg == null ? null : leg - deduct;
        final ready = mark1 != null && mark1 > 0 && between != null;

        return ProCalcScaffold(
          title: 'Back-to-Back',
          inputBar: Row(
            children: [
              Expanded(
                child: ProLengthInput(
                  label: 'Leg height',
                  controller: _legCtrl,
                  mode: mode,
                  onChanged: () => setState(() {}),
                  step: 1,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ProLengthInput(
                  label: 'Between bends',
                  controller: _betweenCtrl,
                  mode: mode,
                  onChanged: () => setState(() {}),
                  step: 1,
                ),
              ),
            ],
          ),
          body: !ready
              ? const Center(
                  child: Text('Enter leg height and distance',
                      style: TextStyle(color: ProTheme.textDim)))
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.swap_vert,
                          color: ProTheme.accent, size: 64),
                      const SizedBox(height: 12),
                      Text(
                        '${AppUnits.format(between!, mode)} apart',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'legs ${AppUnits.format(leg!, mode)} tall',
                        style: const TextStyle(
                            color: ProTheme.textDim, fontSize: 15),
                      ),
                    ],
                  ),
                ),
          resultBar: mark1 == null
              ? const ProResultBar(label: 'Mark 1 from end', value: '—')
              : ProResultBar(
                  label: 'Mark 1 from end',
                  value: AppUnits.format(mark1, mode),
                  fraction: (mode != MeasureMode.centimeters)
                      ? AppUnits.fraction(mark1)
                      : null,
                  onSave: () {
                    final summary =
                        'Back-to-back legs ${AppUnits.format(leg!, mode)} → mark 1 at ${AppUnits.format(mark1, mode)}';
                    HistoryStore.add('Back-to-Back 90s', summary).then((_) =>
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Saved to history'))));
                  },
                  onSteps: () => showStepsSheet(context, 'Marking steps', [
                    'Mark 1 at ${AppUnits.format(mark1, mode)} from the end.',
                    'Bend 90° with arrow on mark 1.',
                    'From back of bend 1, measure ${AppUnits.format(between!, mode)} — mark 2.',
                    'Flip end-for-end, bend 90° on mark 2, same direction.',
                  ]),
                ),
        );
      },
    );
  }
}
