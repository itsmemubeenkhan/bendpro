import 'package:flutter/material.dart';
import '../pro_diagram.dart';
import '../pro_widgets.dart';
import '../store.dart';
import '../units.dart';

/// Double 90° U-Bend — pro layout.
class UBendScreen extends StatefulWidget {
  const UBendScreen({super.key});

  @override
  State<UBendScreen> createState() => _UBendScreenState();
}

class _UBendScreenState extends State<UBendScreen> {
  final _legCtrl = TextEditingController(text: '18');
  final _spacingCtrl = TextEditingController(text: '12');
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
    _spacingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MeasureMode>(
      valueListenable: AppUnits.mode,
      builder: (context, mode, _) {
        final h = AppUnits.parseInput(_legCtrl.text, mode);
        final s = AppUnits.parseInput(_spacingCtrl.text, mode);
        final deduct = _deducts[_size] ?? 6.0;
        final markA = h == null ? null : h - deduct;
        final ready = markA != null && markA > 0 && s != null;

        return ProCalcScaffold(
          title: 'Double 90° (U-Bend)',
          inputBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
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
                      label: 'Spacing',
                      controller: _spacingCtrl,
                      mode: mode,
                      onChanged: () => setState(() {}),
                      step: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: !ready
              ? const Center(
                  child: Text('Enter leg height and spacing',
                      style: TextStyle(color: ProTheme.textDim)))
              : ProDragDiagram(
                  painter: _UBendPainter(
                    legIn: h!,
                    legLabel: AppUnits.format(h, mode),
                    spacingLabel: AppUnits.format(s!, mode),
                  ),
                  onDragY: (dy, size) {
                    final frac = ((160 - dy) / 110).clamp(0.05, 1.0);
                    var v = (frac * 48).clamp(2.0, 48.0);
                    v = (v * 2).round() / 2;
                    _legCtrl.text = AppUnits.formatInput(v, mode);
                    setState(() {});
                  },
                ),
          resultBar: markA == null
              ? const ProResultBar(label: 'Mark A from end', value: '—')
              : ProResultBar(
                  label: 'Mark A from end',
                  value: AppUnits.format(markA, mode),
                  fraction: (mode != MeasureMode.centimeters)
                      ? AppUnits.fraction(markA)
                      : null,
                  onSave: () {
                    final summary =
                        'U-bend legs ${AppUnits.format(h!, mode)} spacing ${AppUnits.format(s!, mode)} → A at ${AppUnits.format(markA, mode)}';
                    HistoryStore.add('Double 90°', summary).then((_) =>
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Saved to history'))));
                  },
                  onSteps: () => showStepsSheet(context, 'Marking steps', [
                    'Mark A at ${AppUnits.format(markA, mode)} from the end.',
                    'Bend 90° with arrow on A.',
                    'Measure ${AppUnits.format(s!, mode)} from back of bend 1 — mark B.',
                    'Flip, bend 90° on B the same direction.',
                  ]),
                ),
        );
      },
    );
  }
}

class _UBendPainter extends CustomPainter {
  final double legIn;
  final String legLabel;
  final String spacingLabel;
  _UBendPainter(
      {required this.legIn, required this.legLabel, required this.spacingLabel});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    const botY = 160.0;
    final frac = (legIn / 48).clamp(0.08, 1.0);
    final topY = botY - frac * 110;
    final x1 = w * 0.30, x2 = w * 0.70;
    ProPipe.draw(canvas, [
      Offset(x1, botY),
      Offset(x1, topY),
      Offset(x2, topY),
      Offset(x2, botY),
    ]);
    ProPipe.mark(canvas, Offset(x1, topY), 'A');
    ProPipe.mark(canvas, Offset(x2, topY), 'B');
    ProPipe.dim(canvas, Offset(x1, 26), Offset(x2, 26), spacingLabel);
    ProPipe.dim(canvas, Offset(x1 - 34, topY), Offset(x1 - 34, botY), legLabel);
    ProPipe.label(canvas, 'drag ↕', Offset(w / 2, size.height - 16),
        size: 11, color: ProTheme.textDim);
  }

  @override
  bool shouldRepaint(covariant _UBendPainter old) =>
      old.legIn != legIn || old.legLabel != legLabel;
}
