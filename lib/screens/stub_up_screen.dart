import 'package:flutter/material.dart';
import '../diagrams.dart';
import '../store.dart';
import '../units.dart';
import '../widgets.dart';
import 'profiles_screen.dart';

/// 90° stub-up: bend the end of the conduit straight up to a finished height.
///
/// Math: mark the conduit at (stub height − deduct), then bend 90° with
/// the bender arrow on the mark. The deduct comes from the active bender
/// profile (or the standard EMT table when no profile is selected).
class StubUpScreen extends StatefulWidget {
  const StubUpScreen({super.key});

  @override
  State<StubUpScreen> createState() => _StubUpScreenState();
}

class _StubUpScreenState extends State<StubUpScreen> {
  final _heightCtrl = TextEditingController();
  String _size = '3/4"';
  Map<String, double> _deducts = Map.of(ProfileStore.standardDeducts);
  String? _profileName;
  List<BenderProfile> _profiles = [];

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final profiles = await ProfileStore.load();
    final active = await ProfileStore.activeName();
    final deducts = await ProfileStore.activeDeducts();
    if (mounted) {
      setState(() {
        _profiles = profiles;
        _profileName = active;
        _deducts = deducts;
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
    return CalcScaffold(
      title: '90° Stub-Up',
      subtitle:
          'Bend the end of the conduit straight up so it finishes at exactly the height you need.',
      builder: (context, mode) {
        final h = AppUnits.parseInput(_heightCtrl.text, mode);
        final deduct = _deducts[_size]!;
        final mark = h == null ? null : h - deduct;
        final valid = mark != null && mark > 0;
        final profileLabel =
            _profileName == null ? 'Standard EMT' : _profileName!;

        final fields = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LengthField(
              label: 'Finished stub height',
              controller: _heightCtrl,
              mode: mode,
              onChanged: () => setState(() {}),
            ),
            const SectionLabel('BENDER PROFILE'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _profileChip('Standard EMT', _profileName == null,
                    () async {
                  await ProfileStore.setActive(null);
                  _loadProfiles();
                }),
                ..._profiles.map((p) => _profileChip(
                    p.name, _profileName == p.name, () async {
                  await ProfileStore.setActive(p.name);
                  _loadProfiles();
                })),
                IconButton(
                  tooltip: 'Manage bender profiles',
                  icon: const Icon(Icons.settings_outlined, color: kAccent),
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(
                          builder: (_) => const ProfilesScreen()))
                      .then((_) => _loadProfiles()),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const SectionLabel('CONDUIT SIZE'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ProfileStore.sizes.map((s) {
                final isSel = s == _size;
                return ChoiceChip(
                  label: Text(s),
                  selected: isSel,
                  onSelected: (_) => setState(() => _size = s),
                  selectedColor: kAccent,
                  labelStyle: TextStyle(
                    color: isSel ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        );

        if (h == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              fields,
              const HintCard(
                  'Enter the finished stub height to find where to mark.'),
            ],
          );
        }
        if (!valid) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              fields,
              const HintCard(
                  'The stub height must be taller than the deduct for this conduit size.'),
            ],
          );
        }

        final summary =
            'Stub-up ${AppUnits.format(h, mode)} ($_size, $profileLabel) → mark at ${AppUnits.format(mark!, mode)}';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            fields,
            DragDiagramCard(
              painter: StubUpDiagramPainter(
                markLabel: AppUnits.format(mark!, mode),
                stubLabel: AppUnits.format(h, mode),
                deductLabel: AppUnits.format(deduct, mode),
                stubInches: h,
              ),
              onDrag: (pos, size) {
                final v = StubUpDiagramPainter.stubFromDragY(pos.dy);
                final snapped = mode == MeasureMode.centimeters
                    ? (v * AppUnits.inchToCm).roundToDouble() / AppUnits.inchToCm
                    : (v * 2).round() / 2;
                _heightCtrl.text = AppUnits.formatInput(snapped, mode);
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            ResultCard(
              label: 'Mark the conduit at',
              value: AppUnits.format(mark!, mode),
              inchesValue: mark!,
              mode: mode,
              note:
                  '${AppUnits.format(h, mode)} stub − ${AppUnits.format(deduct, mode)} deduct ($_size · $profileLabel)',
              onSave: () => HistoryStore.add('90° Stub-Up', summary).then(
                  (_) => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved to history')))),
            ),
            const SizedBox(height: 12),
            StepsCard(
              title: 'Marking steps',
              steps: [
                'Measure ${AppUnits.format(mark!, mode)} from the end of the conduit and mark it.',
                'Set the bender arrow exactly on the mark.',
                'Pull the bend to a full 90°, keeping steady foot pressure.',
                'Stand the conduit up and check the height — it should finish at ${AppUnits.format(h, mode)}.',
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _profileChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: kAccent,
      labelStyle: TextStyle(
        color: selected ? Colors.black : Colors.white,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
