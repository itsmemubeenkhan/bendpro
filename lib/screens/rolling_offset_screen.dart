import 'dart:math';
import 'package:flutter/material.dart';
import '../pro_widgets.dart';
import '../qb_diagram.dart';
import '../store.dart';
import '../units.dart';

/// Rolling Offset — QuickBend-style professional layout.
/// Original design with the same calculations.
class RollingOffsetScreen extends StatefulWidget {
  const RollingOffsetScreen({super.key});

  @override
  State<RollingOffsetScreen> createState() =>
      _RollingOffsetScreenState();
}

class _RollingOffsetScreenState
    extends State<RollingOffsetScreen> {
  final _riseCtrl = TextEditingController(text: '6');
  final _rollCtrl = TextEditingController(text: '6');
  double _angle = 30;

  @override
  void dispose() {
    _riseCtrl.dispose();
    _rollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MeasureMode>(
      valueListenable: AppUnits.mode,
      builder: (context, mode, _) {
        final rise = AppUnits.parseInput(_riseCtrl.text, mode);
        final roll = AppUnits.parseInput(_rollCtrl.text, mode);
        final m = AppUnits.multipliers[_angle]!;
        final trueOff = (rise == null || roll == null)
            ? null
            : sqrt(rise * rise + roll * roll);
        final dist =
            trueOff == null ? null : trueOff * m;

        return Scaffold(
          backgroundColor: ProTheme.bg,
          appBar: AppBar(
            backgroundColor: ProTheme.bg,
            elevation: 0,
            title: const Text('Rolling Offset',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            actions: const [ProUnitToggle()],
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ProLengthInput(
                          label: 'Rise',
                          controller: _riseCtrl,
                          mode: mode,
                          onChanged: () =>
                              setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ProLengthInput(
                          label: 'Roll',
                          controller: _rollCtrl,
                          mode: mode,
                          onChanged: () =>
                              setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: trueOff == null
                      ? const Center(
                          child: Text(
                              'Enter rise and roll',
                              style: TextStyle(
                                  color:
                                      ProTheme.textDim)))
                      : Stack(
                          children: [
                            QBDiagram(
                              height: double.infinity,
                              painter: _RollingPainter(
                                angleDeg: _angle,
                                trueOffIn: trueOff,
                              ),
                            ),
                            Positioned(
                              right: 24,
                              top: 16,
                              child: QBResultCard(
                                label: 'Between Bends',
                                value: AppUnits.fraction(
                                    dist!),
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
                                label: 'True Offset',
                                value: AppUnits.fraction(
                                    trueOff),
                                hint:
                                    '√(rise² + roll²)',
                              ),
                            ),
                            Positioned(
                              right: 24,
                              bottom: 70,
                              child: QBResultCard(
                                label: 'Bend',
                                value:
                                    AppUnits.angleLabel(
                                        _angle),
                              ),
                            ),
                          ],
                        ),
                ),
                dist == null
                    ? const ProResultBar(
                        label: 'Distance between marks',
                        value: '—',
                      )
                    : ProResultBar(
                        label:
                            'Distance between marks',
                        value: AppUnits.format(
                            dist, mode),
                        fraction: (mode !=
                                MeasureMode.centimeters)
                            ? AppUnits.fraction(
                                dist)
                            : null,
                        onSave: () {
                          final summary =
                              'Rolling offset ${AppUnits.format(trueOff!, mode)} @ ${AppUnits.angleLabel(_angle)} → marks ${AppUnits.format(dist, mode)} apart';
                          HistoryStore.add(
                                  'Rolling Offset',
                                  summary)
                              .then((_) =>
                                  ScaffoldMessenger.of(
                                          context)
                                      .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Saved to history'))));
                        },
                        onSteps: () => showStepsSheet(
                            context,
                            'Marking steps', [
                          'Mark 1 where the first bend begins.',
                          'Measure ${AppUnits.format(dist, mode)} from Mark 1 and make Mark 2.',
                          'Bend to ${AppUnits.angleLabel(_angle)} at Mark 1, rolling the conduit as you bend.',
                          'Bend to ${AppUnits.angleLabel(_angle)} at Mark 2 the opposite way.',
                        ]),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _explain(
      BuildContext context, String title, String text) {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
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

/// Rolling offset diagram: diagonal run with two bend zones.
class _RollingPainter extends CustomPainter {
  final double angleDeg;
  final double trueOffIn;
  _RollingPainter(
      {required this.angleDeg, required this.trueOffIn});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final hgt = size.height;
    final rad = angleDeg * pi / 180;

    final x0 = w * 0.22;
    final y0 = hgt * 0.70;
    final runLen = w * 0.42;
    final dx = runLen * cos(rad);
    final dy = runLen * sin(rad);

    final p0 = Offset(x0 - 60, y0);
    final p1 = Offset(x0, y0);
    final p2 = Offset(x0 + dx, y0 - dy);
    final p3 = Offset(x0 + dx + 60, y0 - dy);

    QBConduit.drawPipe(canvas, [p0, p1, p2, p3]);
    QBConduit.bendZone(canvas, p1 - const Offset(28, 0),
        p1 + Offset(28 * cos(rad), -28 * sin(rad)));
    QBConduit.bendZone(canvas, p2 - Offset(28 * cos(rad), -28 * sin(rad)),
        p2 + const Offset(28, 0));

    QBConduit.markDot(canvas, p1, '1');
    QBConduit.markDot(canvas, p2, '2');

    // Dashed true-offset triangle.
    QBConduit.dashedLine(canvas, p1, Offset(p2.dx, p1.dy));
    QBConduit.dashedLine(canvas, Offset(p2.dx, p1.dy), p2);

    QBConduit.dimension(
        canvas,
        Offset(p1.dx, y0 + 34),
        Offset(p2.dx, y0 + 34),
        'true ${trueOffIn.toStringAsFixed(1)}"');
  }

  @override
  bool shouldRepaint(covariant _RollingPainter old) =>
      old.angleDeg != angleDeg ||
      old.trueOffIn != trueOffIn;
}
