import 'dart:math';
import 'package:flutter/material.dart';
import '../pro_widgets.dart';
import '../store.dart';
import '../units.dart';

/// Segmented 90° — pro layout.
class SegmentedScreen extends StatefulWidget {
  const SegmentedScreen({super.key});

  @override
  State<SegmentedScreen> createState() => _SegmentedScreenState();
}

class _SegmentedScreenState extends State<SegmentedScreen> {
  final _radiusCtrl = TextEditingController(text: '12');
  int _shots = 5;

  @override
  void dispose() {
    _radiusCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MeasureMode>(
      valueListenable: AppUnits.mode,
      builder: (context, mode, _) {
        final r = AppUnits.parseInput(_radiusCtrl.text, mode);
        final perShot = 90.0 / _shots;
        final spacing =
            r == null ? null : (3.14159265 / 2 * r) / _shots;

        return ProCalcScaffold(
          title: 'Segmented 90°',
          inputBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProLengthInput(
                label: 'Centerline radius',
                controller: _radiusCtrl,
                mode: mode,
                onChanged: () => setState(() {}),
                step: 1,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 6,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final n = [3, 4, 5, 6, 8, 10][i];
                    final sel = n == _shots;
                    return ChoiceChip(
                      label: Text('$n shots'),
                      selected: sel,
                      onSelected: (_) => setState(() => _shots = n),
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
          body: spacing == null
              ? const Center(
                  child: Text('Enter the radius',
                      style: TextStyle(color: ProTheme.textDim)))
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Segmented bend arc visualization.
                      CustomPaint(
                        size: const Size(200, 120),
                        painter: _SegmentArcPainter(shots: _shots),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${perShot.toStringAsFixed(1)}°',
                        style: const TextStyle(
                          color: ProTheme.accent,
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('per shot',
                          style: TextStyle(
                              color: ProTheme.textDim, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                        '$_shots shots × ${AppUnits.format(spacing, mode)} apart',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
          resultBar: spacing == null
              ? const ProResultBar(label: 'Spacing between shots', value: '—')
              : ProResultBar(
                  label: 'Spacing between shots',
                  value: AppUnits.format(spacing, mode),
                  fraction: (mode != MeasureMode.centimeters)
                      ? AppUnits.fraction(spacing)
                      : null,
                  onSave: () {
                    final summary =
                        'Segmented 90° r=${AppUnits.format(r!, mode)} $_shots shots → ${AppUnits.format(spacing, mode)} apart';
                    HistoryStore.add('Segmented 90°', summary).then((_) =>
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Saved to history'))));
                  },
                  onSteps: () => showStepsSheet(context, 'Marking steps', [
                    'Mark shot 1 where the bend begins.',
                    'Space each mark ${AppUnits.format(spacing, mode)} apart — $_shots total.',
                    'Bend ${perShot.toStringAsFixed(1)}° at each mark, in order.',
                    'Do not flip the conduit between shots.',
                  ]),
                ),
        );
      },
    );
  }
}

/// Segmented 90° arc: shows the bend divided into shot segments
/// with a mark dot at each shot point.
class _SegmentArcPainter extends CustomPainter {
  final int shots;
  _SegmentArcPainter({required this.shots});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height + 20;
    const r = 110.0;
    // Arc path for the conduit.
    final path = Path();
    for (var i = 0; i <= 40; i++) {
      final a = pi - (i / 40) * pi / 2;
      final p = Offset(cx + r * cos(a), cy - r * sin(a));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    // Metallic pipe.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14.5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF0D1117),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF9AA7B4),
    );
    // Shot marks.
    for (var i = 0; i <= shots; i++) {
      final a = pi - (i / shots) * pi / 2;
      final p = Offset(cx + r * cos(a), cy - r * sin(a));
      canvas.drawCircle(
          p, 7, Paint()..color = ProTheme.accent.withOpacity(0.25));
      canvas.drawCircle(p, 4.5, Paint()..color = ProTheme.accent);
    }
    // 90° label.
    final tp = TextPainter(
      text: const TextSpan(
        text: '90°',
        style: TextStyle(
            color: ProTheme.textDim,
            fontSize: 13,
            fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - r - 24));
  }

  @override
  bool shouldRepaint(covariant _SegmentArcPainter old) =>
      old.shots != shots;
}
