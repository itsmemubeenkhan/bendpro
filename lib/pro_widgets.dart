import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../units.dart';

/// Premium design tokens.
class ProTheme {
  static const accent = Color(0xFF2196F3);
  static const bg = Color(0xFF0D1117);
  static const surface = Color(0xFF161C23);
  static const surface2 = Color(0xFF1E2530);
  static const text = Colors.white;
  static const textDim = Color(0xFF8A94A0);
  static const border = Color(0xFF2A3340);
}

/// Compact calculator shell: NO scrolling. Fixed layout —
/// input on top, interactive area fills the middle, result bar pinned
/// at the bottom. Feels like a tool, not a webpage.
class ProCalcScaffold extends StatelessWidget {
  final String title;
  final Widget inputBar;
  final Widget body;
  final Widget resultBar;

  const ProCalcScaffold({
    super.key,
    required this.title,
    required this.inputBar,
    required this.body,
    required this.resultBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProTheme.bg,
      appBar: AppBar(
        backgroundColor: ProTheme.bg,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: const [ProUnitToggle()],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Compact input zone.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: inputBar,
            ),
            // Interactive area expands to fill.
            Expanded(child: body),
            // Result pinned at bottom — always visible, no scroll needed.
            resultBar,
          ],
        ),
      ),
    );
  }
}

/// Compact unit toggle for the app bar.
class ProUnitToggle extends StatelessWidget {
  const ProUnitToggle({super.key});

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
              ButtonSegment(value: MeasureMode.feetInches, label: Text('ft')),
              ButtonSegment(
                  value: MeasureMode.centimeters, label: Text('cm')),
            ],
            selected: {mode},
            onSelectionChanged: (s) => AppUnits.mode.value = s.first,
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium length input: text field with - / + steppers.
/// No keyboard needed for quick adjustments.
class ProLengthInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final MeasureMode mode;
  final VoidCallback onChanged;
  /// Step size in inches for the +/- buttons.
  final double step;

  const ProLengthInput({
    super.key,
    required this.label,
    required this.controller,
    required this.mode,
    required this.onChanged,
    this.step = 0.5,
  });

  void _nudge(double dir) {
    final cur = AppUnits.parseInput(controller.text, mode) ?? 0;
    var next = cur + dir * step;
    if (next < 0) next = 0;
    // Round to clean steps.
    next = (next / step).round() * step;
    controller.text = AppUnits.formatInput(next, mode);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final isFtIn = mode == MeasureMode.feetInches;
    return Container(
      decoration: BoxDecoration(
        color: ProTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ProTheme.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          _StepBtn(icon: Icons.remove, onTap: () => _nudge(-1)),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: ProTheme.textDim,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextField(
                  controller: controller,
                  keyboardType: isFtIn
                      ? TextInputType.text
                      : const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(isFtIn ? r'''[0-9./'" \-]''' : r'[0-9./ ]')),
                  ],
                  onChanged: (_) => onChanged(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: AppUnits.inputHint(mode),
                    hintStyle:
                        const TextStyle(color: Colors.white24, fontSize: 11),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 2),
                  ),
                ),
              ],
            ),
          ),
          _StepBtn(icon: Icons.add, onTap: () => _nudge(1)),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ProTheme.surface2,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: ProTheme.accent, size: 22),
        ),
      ),
    );
  }
}

/// Compact angle selector: horizontal chips.
class ProAngleChips extends StatelessWidget {
  final double selected;
  final ValueChanged<double> onSelected;

  const ProAngleChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: AppUnits.angles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final a = AppUnits.angles[i];
          final sel = a == selected;
          return ChoiceChip(
            label: Text(AppUnits.angleLabel(a)),
            selected: sel,
            onSelected: (_) => onSelected(a),
            selectedColor: ProTheme.accent,
            backgroundColor: ProTheme.surface,
            side: BorderSide(
                color: sel ? ProTheme.accent : ProTheme.border),
            labelStyle: TextStyle(
              color: sel ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          );
        },
      ),
    );
  }
}

/// Fixed bottom result bar: big number, save action. Always visible.
class ProResultBar extends StatelessWidget {
  final String label;
  final String value;
  final String? fraction;
  final VoidCallback? onSave;
  final VoidCallback? onSteps;

  const ProResultBar({
    super.key,
    required this.label,
    required this.value,
    this.fraction,
    this.onSave,
    this.onSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ProTheme.surface,
        border: Border(top: BorderSide(color: ProTheme.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      color: ProTheme.textDim,
                      fontSize: 11,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: ProTheme.accent,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (fraction != null)
                    Text(
                      '≈ $fraction',
                      style: const TextStyle(
                          color: ProTheme.textDim, fontSize: 13),
                    ),
                ],
              ),
            ),
            if (onSteps != null)
              IconButton(
                tooltip: 'Marking steps',
                icon: const Icon(Icons.list_alt,
                    color: ProTheme.accent, size: 28),
                onPressed: onSteps,
              ),
            if (onSave != null)
              IconButton(
                tooltip: 'Save',
                icon: const Icon(Icons.bookmark_add_outlined,
                    color: ProTheme.accent, size: 28),
                onPressed: onSave,
              ),
          ],
        ),
      ),
    );
  }
}

/// Marking steps as a bottom sheet — not inline scrolling.
void showStepsSheet(
    BuildContext context, String title, List<String> steps) {
  showModalBottomSheet(
    context: context,
    backgroundColor: ProTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ProTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: ProTheme.accent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: steps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: ProTheme.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
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
                      steps[i],
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
