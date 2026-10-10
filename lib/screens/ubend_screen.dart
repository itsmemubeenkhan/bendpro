import 'package:flutter/material.dart';
import '../diagrams.dart';
import '../store.dart';
import '../units.dart';
import '../widgets.dart';
import 'profiles_screen.dart';

/// Double 90° (U-bend / dogleg): two 90° bends that take the conduit up,
/// across, and back down — e.g. jumping over an obstacle and returning
/// to the original level.
///
/// Layout: mark A at (leg height − deduct) from the end, bend 90°;
/// mark B is measured [spacing] from the back of the first bend along
/// the leg, then bend 90° the same rotational direction. The two legs
/// finish parallel, [spacing] apart, each [leg height] tall.
class UBendScreen extends StatefulWidget {
  const UBendScreen({super.key});

  @override
  State<UBendScreen> createState() => _UBendScreenState();
}

class _UBendScreenState extends State<UBendScreen> {
  final _heightCtrl = TextEditingController();
  final _spacingCtrl = TextEditingController();
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
    _spacingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CalcScaffold(
      title: 'Double 90° (U-Bend)',
      subtitle:
          'Two 90° bends that take the conduit up, across, and back down — a U that jumps an obstacle and returns to level.',
      builder: (context, mode) {
        final h = AppUnits.parseInput(_heightCtrl.text, mode);
        final s = AppUnits.parseInput(_spacingCtrl.text, mode);
        final deduct = _deducts[_size]!;
        final markA = h == null ? null : h - deduct;
        final ready = markA != null && markA > 0 && s != null;
        final profileLabel =
            _profileName == null ? 'Standard EMT' : _profileName!;

        final fields = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LengthField(
              label: 'Leg height',
              controller: _heightCtrl,
              mode: mode,
              onChanged: () => setState(() {}),
            ),
            LengthField(
              label: 'Spacing between legs',
              controller: _spacingCtrl,
              mode: mode,
              onChanged: () => setState(() {}),
            ),
            const SectionLabel('BENDER PROFILE'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _chip('Standard EMT', _profileName == null, () async {
                  await ProfileStore.setActive(null);
                  _loadProfiles();
                }),
                ..._profiles.map((p) =>
                    _chip(p.name, _profileName == p.name, () async {
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
              children: ProfileStore.sizes.map((sz) {
                final isSel = sz == _size;
                return ChoiceChip(
                  label: Text(sz),
                  selected: isSel,
                  onSelected: (_) => setState(() => _size = sz),
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

        if (!ready) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              fields,
              const HintCard(
                  'Enter the leg height and the spacing to lay out both bends.'),
            ],
          );
        }

        final summary =
            'U-bend legs ${AppUnits.format(h!, mode)} spacing ${AppUnits.format(s!, mode)} ($_size, $profileLabel) → A at ${AppUnits.format(markA!, mode)}';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            fields,
            DragDiagramCard(
              painter: UBendDiagramPainter(
                legLabel: AppUnits.format(h!, mode),
                spacingLabel: AppUnits.format(s!, mode),
                legInches: h!,
              ),
              onDrag: (pos, size) {
                final v = UBendDiagramPainter.legFromDragY(pos.dy);
                final snapped = mode == MeasureMode.centimeters
                    ? (v * AppUnits.inchToCm).roundToDouble() / AppUnits.inchToCm
                    : (v * 2).round() / 2;
                // Update the leg height controller.
                _heightCtrl.text = AppUnits.formatInput(snapped, mode);
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            ResultCard(
              label: 'Mark A (from the end)',
              value: AppUnits.format(markA!, mode),
              inchesValue: markA!,
              mode: mode,
              note:
                  '${AppUnits.format(h!, mode)} leg − ${AppUnits.format(deduct, mode)} deduct ($_size · $profileLabel). Mark B sits ${AppUnits.format(s!, mode)} from the back of the first bend.',
              onSave: () =>
                  HistoryStore.add('Double 90° (U-Bend)', summary).then(
                      (_) => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Saved to history')))),
            ),
            const SizedBox(height: 12),
            StepsCard(
              title: 'Marking steps',
              steps: [
                'Measure ${AppUnits.format(markA!, mode)} from the end of the conduit and mark A.',
                'Set the bender arrow on A and bend a full 90°.',
                'From the back of that bend, measure ${AppUnits.format(s!, mode)} along the leg and mark B.',
                'Set the bender arrow on B and bend 90° in the same rotational direction.',
                'Check the U: both legs ${AppUnits.format(h!, mode)} tall, ${AppUnits.format(s!, mode)} apart, and parallel.',
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
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
