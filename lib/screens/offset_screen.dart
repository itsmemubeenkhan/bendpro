import 'dart:math';
import 'package:flutter/material.dart';
import '../pro_widgets.dart';
import '../qb_diagram.dart';
import '../store.dart';
import '../units.dart';

/// Offset bend — QuickBend-style professional layout:
/// technical conduit diagram with highlighted bend zones,
/// floating result cards, compact inputs. Original design.
class OffsetScreen extends StatefulWidget {
  const OffsetScreen({super.key});

  @override
  State<OffsetScreen> createState() => _OffsetScreenState();
}

class _OffsetScreenState extends State<OffsetScreen> {
  final _heightCtrl = TextEditingController(text: '6');
  double _angle = 30;

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
        final m = AppUnits.multipliers[_angle]!;
        final dist = h == null ? null : h * m;
        final shrink = h == null
            ? null
            : h * (AppUnits.shrinkPerInch[_angle] ?? 0);

        return Scaffold(
          backgroundColor: ProTheme.bg,
          appBar: AppBar(
            backgroundColor: ProTheme.bg,
            elevation: 0,
            title: const Text('Offset',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            actions: const [ProUnitToggle()],
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Compact inputs.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ProLengthInput(
                          label: 'Rise',
                          controller: _heightCtrl,
                          mode: mode,
                          onChanged: () => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AngleInput(
                          angle: _angle,
                          onChanged: (a) =>
                              setState(() => _angle = a),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Diagram with floating result cards.
                Expanded(
                  child: h == null
                      ? const Center(
                          child: Text('Enter the rise',
                              style: TextStyle(
                                  color: ProTheme.textDim)))
                      : Stack(
                          children: [
                            QBDiagram(
                              height: double.infinity,
                              painter: _OffsetPainter(
                                angleDeg: _angle,
                                riseIn: h,
                              ),
                            ),
                            // Floating result cards.
                            Positioned(
                              right: 24,
                              top: 16,
                              child: QBResultCard(
                                label: 'Between Bends',
                                value: AppUnits.fraction(dist!),
                                hint:
                                    'Mark 1 → Mark 2',
                                onTap: () => _explain(
                                    context,
                                    'Between Bends',
                                    'Distance from the center of the first bend to the center of the second bend.'),
                              ),
                            ),
                            Positioned(
                              right: 24,
                              top: 110,
                              child: QBResultCard(
                                label: 'Bend',
                                value: AppUnits.angleLabel(
                                    _angle),
                              ),
                            ),
                            Positioned(
                              right: 24,
                              bottom: 70,
                              child: QBResultCard(
                                label: 'Shrink',
                                value: AppUnits.fraction(
                                    shrink!),
                                hint: 'Pullback',
                                onTap: () => _explain(
                                    context,
                                    'Shrink',
                                    'The conduit "shrinks" by this amount through the bends. Start your first mark this far early.'),
                              ),
                            ),
                          ],
                        ),
                ),
                // Bottom result bar.
                dist == null
                    ? const ProResultBar(
                        label: 'Distance between marks',
                        value: '—',
                      )
                    : ProResultBar(
                        label: 'Distance between marks',
                        value: AppUnits.format(dist, mode),
                        fraction:
                            (mode != MeasureMode.centimeters)
                                ? AppUnits.fraction(dist)
                                : null,
                        onSave: () {
                          final summary =
                              'Offset ${AppUnits.format(h!, mode)} @ ${AppUnits.angleLabel(_angle)} → marks ${AppUnits.format(dist, mode)} apart';
                          HistoryStore.add('Offset Bend', summary)
                              .then((_) => ScaffoldMessenger.of(
                                      context)
                                  .showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Saved to history'))));
                        },
                        onSteps: () => showStepsSheet(
                            context, 'Marking steps', [
                          'Mark 1 where the first bend begins.',
                          'Measure ${AppUnits.format(dist, mode)} from Mark 1 and make Mark 2.',
                          'Set the bender arrow on Mark 1 and bend to ${AppUnits.angleLabel(_angle)}.',
                          'Flip the conduit over, set the bender on Mark 2, and bend to ${AppUnits.angleLabel(_angle)} the opposite way.',
                          'Check the offset — it should measure ${AppUnits.format(h!, mode)}.',
                        ]),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _explain(BuildContext context, String title, String text) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ProTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: ProTheme.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 8),
            Text(text,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5)),
          ],
        ),
      ),
    );
  }
}

/// Compact angle input with - / + steppers.
class _AngleInput extends StatelessWidget {
  final double angle;
  final ValueChanged<double> onChanged;
  const _AngleInput({required this.angle, required this.onChanged});

  static const _angles = [10.0, 15.0, 22.5, 30.0, 45.0, 60.0];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ProTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ProTheme.border),
      ),
      padding:
          const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          _step(Icons.remove, -1),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('BEND ANGLE',
                    style: TextStyle(
                        color: ProTheme.textDim,
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600)),
                GestureDetector(
                  onTap: () => _pick(context),
                  child: Text(
                    AppUnits.angleLabel(angle),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          _step(Icons.add, 1),
        ],
      ),
    );
  }

  Widget _step(IconData icon, int dir) {
    return Material(
      color: ProTheme.surface2,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          final i = _angles.indexOf(angle);
          final n = (i + dir).clamp(0, _angles.length - 1);
          onChanged(_angles[n]);
        },
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon,
              color: ProTheme.accent, size: 22),
        ),
      ),
    );
  }

  void _pick(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ProTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding:
            const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Wrap(
          spacing: 10,
          children: _angles
              .map((a) => ChoiceChip(
                    label: Text(AppUnits.angleLabel(a)),
                    selected: a == angle,
                    onSelected: (_) {
                      onChanged(a);
                      Navigator.of(context).pop();
                    },
                    selectedColor: ProTheme.accent,
                    backgroundColor:
                        ProTheme.surface2,
                    labelStyle: TextStyle(
                      color: a == angle
                          ? Colors.black
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

/// Offset conduit diagram: vertical riser, two bends (green zones),
/// dashed bend arcs, dimension lines.
class _OffsetPainter extends CustomPainter {
  final double angleDeg;
  final double riseIn;
  _OffsetPainter({required this.angleDeg, required this.riseIn});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final hgt = size.height;
    final rad = angleDeg * pi / 180;

    // Geometry: conduit runs vertically, offset jogs right.
    final x0 = w * 0.30; // main run x
    final jog = (riseIn / 12 * 130).clamp(40.0, 170.0);
    final x1 = x0 + jog; // offset run x
    final yTop = 24.0;
    final bendLen = 90.0; // vertical length of each bend section
    final yB1 = hgt * 0.38; // first bend center y
    final yB2 = yB1 + bendLen; // second bend center y

    // Bend 1: from (x0, yB1-bendLen/2) angled to (x1, yB1+bendLen/2).
    final b1a = Offset(x0, yB1 - bendLen / 2);
    final b1b = Offset(
      x0 + jog * 0.5,
      yB1,
    );
    final b1c = Offset(x1, yB1 + bendLen / 2);
    // Bend 2: mirror.
    final b2a = Offset(x1, yB2 - bendLen / 2);
    final b2b = Offset(
      x1 - jog * 0.5,
      yB2,
    );
    final b2c = Offset(x0, yB2 + bendLen / 2);

    // Full conduit path.
    QBConduit.drawPipe(canvas, [
      Offset(x0, yTop),
      b1a,
      b1b,
      b1c,
      b2a,
      b2b,
      b2c,
      Offset(x0, hgt - 24),
    ]);

    // Green bend zones.
    QBConduit.bendZone(canvas, b1a, b1c);
    QBConduit.bendZone(canvas, b2a, b2c);

    // Dashed arcs showing bend sweep.
    QBConduit.dashedArc(
        canvas, Offset(x0, yB1), 44, -pi / 2, rad * 0.9);
    QBConduit.dashedArc(
        canvas, Offset(x1, yB2), 44, pi / 2 - rad * 0.9, rad * 0.9);

    // Mark dots.
    QBConduit.markDot(canvas, b1b, '1');
    QBConduit.markDot(canvas, b2b, '2');

    // Dimension: rise (horizontal jog).
    QBConduit.dimension(
      canvas,
      Offset(x0, hgt - 44),
      Offset(x1, hgt - 44),
      '${riseIn.toStringAsFixed(riseIn == riseIn.roundToDouble() ? 0 : 1)}" rise',
    );
  }

  @override
  bool shouldRepaint(covariant _OffsetPainter old) =>
      old.angleDeg != angleDeg || old.riseIn != riseIn;
}
