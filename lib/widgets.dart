import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'units.dart';

/// Shared building blocks: dark industrial styling, blue accents,
/// big readable results.

const Color kAccent = Color(0xFF2196F3);
const Color kCardBg = Color(0xFF1E2226);

/// Page shell: title, measure-mode toggle in the app bar, scrollable body.
/// The [builder] re-runs whenever the mode changes.
class CalcScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget Function(BuildContext context, MeasureMode mode) builder;

  const CalcScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: const [UnitToggle()],
      ),
      body: ValueListenableBuilder<MeasureMode>(
        valueListenable: AppUnits.mode,
        builder: (context, mode, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 20),
            builder(context, mode),
          ],
        ),
      ),
    );
  }
}

/// Inches / feet-inches / centimeters switch shown in every app bar.
class UnitToggle extends StatelessWidget {
  const UnitToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MeasureMode>(
      valueListenable: AppUnits.mode,
      builder: (context, mode, _) => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Center(
          child: SegmentedButton<MeasureMode>(
            segments: const [
              ButtonSegment(value: MeasureMode.inches, label: Text('in')),
              ButtonSegment(value: MeasureMode.feetInches, label: Text('ft-in')),
              ButtonSegment(
                  value: MeasureMode.centimeters, label: Text('cm')),
            ],
            selected: {mode},
            onSelectionChanged: (s) => AppUnits.mode.value = s.first,
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ),
    );
  }
}

/// Length input honoring the active measure mode, with format hints.
/// Accepts decimals and trade fractions ("12 1/2") in every mode.
class LengthField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final MeasureMode mode;
  final VoidCallback onChanged;

  const LengthField({
    super.key,
    required this.label,
    required this.controller,
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isFtIn = mode == MeasureMode.feetInches;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: isFtIn
            ? TextInputType.text
            : const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
              RegExp(isFtIn ? r'''[0-9./'" \-]''' : r'[0-9./ ]')),
        ],
        onChanged: (_) => onChanged(),
        style: const TextStyle(color: Colors.white, fontSize: 18),
        decoration: InputDecoration(
          labelText: label,
          hintText: AppUnits.inputHint(mode),
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
          filled: true,
          fillColor: kCardBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kAccent, width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// Small section heading above a control group.
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: kAccent,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// Selectable bend-angle chips (10° … 60°).
class AngleChips extends StatelessWidget {
  final double selected;
  final ValueChanged<double> onSelected;

  const AngleChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppUnits.angles.map((a) {
        final isSel = a == selected;
        return ChoiceChip(
          label: Text(AppUnits.angleLabel(a)),
          selected: isSel,
          onSelected: (_) => onSelected(a),
          selectedColor: kAccent,
          labelStyle: TextStyle(
            color: isSel ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }
}

/// Big result card: headline number in blue, trade fraction underneath
/// (inch modes), optional note, optional save-to-history button.
class ResultCard extends StatelessWidget {
  final String label;
  final String value;
  final double? inchesValue;
  final MeasureMode mode;
  final String? note;
  final VoidCallback? onSave;

  const ResultCard({
    super.key,
    required this.label,
    required this.value,
    this.inchesValue,
    required this.mode,
    this.note,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final showFraction = inchesValue != null &&
        (mode == MeasureMode.inches || mode == MeasureMode.feetInches);
    return Card(
      color: kCardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kAccent, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onSave != null)
                  IconButton(
                    tooltip: 'Save to history',
                    icon: const Icon(Icons.bookmark_add_outlined,
                        color: kAccent),
                    onPressed: onSave,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: kAccent,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (showFraction) ...[
              const SizedBox(height: 2),
              Text(
                '≈ ${AppUnits.fraction(inchesValue!)}',
                style: const TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ],
            if (note != null) ...[
              const SizedBox(height: 6),
              Text(
                note!,
                style: const TextStyle(color: Colors.white60, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Numbered "how to mark & bend" instructions with computed numbers.
class StepsCard extends StatelessWidget {
  final String title;
  final List<String> steps;

  const StepsCard({super.key, required this.title, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kCardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: kAccent,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            ...steps.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: kAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${e.key + 1}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

/// Placeholder shown before the user enters enough input.
class HintCard extends StatelessWidget {
  final String text;
  const HintCard(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kCardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: kAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card hosting a custom-painted bend diagram.
class DiagramCard extends StatelessWidget {
  final CustomPainter painter;
  final double height;
  const DiagramCard({super.key, required this.painter, this.height = 190});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(painter: painter),
        ),
      ),
    );
  }
}

/// Interactive diagram card: drag the pipe to change the bend.
/// Reports drag position in the painter's local coordinates plus the
/// rendered size, so screens can map pixels back to input values.
class DragDiagramCard extends StatelessWidget {
  final CustomPainter painter;
  final double height;
  final void Function(Offset localPos, Size size) onDrag;

  const DragDiagramCard({
    super.key,
    required this.painter,
    required this.onDrag,
    this.height = 210,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: height,
              width: double.infinity,
              child: Builder(
                builder: (ctx) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (d) => _handle(d.globalPosition, ctx),
                  onPanUpdate: (d) => _handle(d.globalPosition, ctx),
                  child: CustomPaint(painter: painter),
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app, size: 14, color: Colors.white38),
                SizedBox(width: 6),
                Text(
                  'Drag the pipe to bend it',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handle(Offset global, BuildContext ctx) {
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    onDrag(box.globalToLocal(global), box.size);
  }
}
