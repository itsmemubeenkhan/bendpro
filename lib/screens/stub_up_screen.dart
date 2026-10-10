import 'package:flutter/material.dart';
import '../pro_bender.dart';
import '../pro_widgets.dart';
import '../store.dart';
import '../units.dart';
import 'profiles_screen.dart';

/// 90° Stub-Up — pro layout.
class StubUpScreen extends StatefulWidget {
  const StubUpScreen({super.key});

  @override
  State<StubUpScreen> createState() => _StubUpScreenState();
}

class _StubUpScreenState extends State<StubUpScreen> {
  final _heightCtrl = TextEditingController(text: '24');
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
    _heightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MeasureMode>(
      valueListenable: AppUnits.mode,
      builder: (context, mode, _) {
        final h = AppUnits.parseInput(_heightCtrl.text, mode);
        final deduct = _deducts[_size] ?? 6.0;
        final mark = h == null ? null : h - deduct;
        final valid = mark != null && mark > 0;

        return ProCalcScaffold(
          title: '90° Stub-Up',
          inputBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProLengthInput(
                label: 'Finished stub height',
                controller: _heightCtrl,
                mode: mode,
                onChanged: () => setState(() {}),
                step: 1,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: ProfileStore.sizes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final s = ProfileStore.sizes[i];
                    final sel = s == _size;
                    return ChoiceChip(
                      label: Text(s),
                      selected: sel,
                      onSelected: (_) => setState(() => _size = s),
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
          body: ProBender(
            angleDeg: 90,
            onAngleChanged: (_) {},
          ),
          resultBar: !valid
              ? ProResultBar(
                  label: 'Mark at',
                  value: h == null ? '—' : 'Too short',
                )
              : ProResultBar(
                  label: 'Mark at',
                  value: AppUnits.format(mark!, mode),
                  fraction: (mode != MeasureMode.centimeters)
                      ? AppUnits.fraction(mark!)
                      : null,
                  onSave: () {
                    final summary =
                        'Stub-up ${AppUnits.format(h!, mode)} ($_size) → mark at ${AppUnits.format(mark!, mode)}';
                    HistoryStore.add('90° Stub-Up', summary).then((_) =>
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Saved to history'))));
                  },
                  onSteps: () => showStepsSheet(context, 'Marking steps', [
                    'Measure ${AppUnits.format(mark!, mode)} from the end and mark it.',
                    'Set the bender arrow on the mark.',
                    'Bend a full 90° — check with a level.',
                    'The riser should finish at ${AppUnits.format(h!, mode)}.',
                  ]),
                ),
        );
      },
    );
  }
}
