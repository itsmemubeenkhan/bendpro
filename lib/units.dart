import 'package:flutter/foundation.dart';

/// Measurement mode for input and display.
///
/// All bending math is performed in decimal inches (the trade standard for
/// the multiplier tables). Values are converted only at the input/display
/// boundary, so the formulas stay clean and unit-independent.
enum MeasureMode { inches, feetInches, centimeters }

class AppUnits {
  AppUnits._();

  /// Currently selected input/display mode.
  static final ValueNotifier<MeasureMode> mode =
      ValueNotifier<MeasureMode>(MeasureMode.inches);

  static const double inchToCm = 2.54;

  static String shortLabel(MeasureMode m) {
    switch (m) {
      case MeasureMode.inches:
        return 'in';
      case MeasureMode.feetInches:
        return 'ft-in';
      case MeasureMode.centimeters:
        return 'cm';
    }
  }

  static String inputHint(MeasureMode m) {
    switch (m) {
      case MeasureMode.inches:
        return 'e.g. 12.5 or 12 1/2';
      case MeasureMode.feetInches:
        return 'e.g. 2\' 6 1/2"';
      case MeasureMode.centimeters:
        return 'e.g. 30.5';
    }
  }

  /// Parse user-typed text into inches. Returns null when invalid.
  /// Accepts decimals ("12.5"), fractions ("12 1/2", "1/2") and, in
  /// feet-inches mode, forms like 2'6", 2' 6 1/2", 6".
  static double? parseInput(String text, MeasureMode m) {
    final t = text.trim();
    if (t.isEmpty) return null;
    switch (m) {
      case MeasureMode.inches:
        return _parseNumberOrFraction(t);
      case MeasureMode.centimeters:
        final v = _parseNumberOrFraction(t);
        return v == null ? null : v / inchToCm;
      case MeasureMode.feetInches:
        return _parseFeetInches(t);
    }
  }

  static double? _parseNumberOrFraction(String t) {
    t = t.trim().replaceAll('"', '');
    final mixed =
        RegExp(r'^(\d+(?:\.\d+)?)\s+(\d+)\s*/\s*(\d+)$').firstMatch(t);
    if (mixed != null) {
      final d = double.parse(mixed.group(3)!);
      if (d == 0) return null;
      return double.parse(mixed.group(1)!) +
          double.parse(mixed.group(2)!) / d;
    }
    final frac = RegExp(r'^(\d+)\s*/\s*(\d+)$').firstMatch(t);
    if (frac != null) {
      final d = double.parse(frac.group(2)!);
      if (d == 0) return null;
      return double.parse(frac.group(1)!) / d;
    }
    return double.tryParse(t);
  }

  static double? _parseFeetInches(String t) {
    var s = t
        .toLowerCase()
        .replaceAll('"', '')
        .replaceAll('inches', '')
        .replaceAll('inch', '')
        .replaceAll('in', '')
        .replaceAll('feet', "'")
        .replaceAll('foot', "'")
        .replaceAll('ft', "'")
        .trim();
    double feet = 0;
    double inches = 0;
    if (s.contains("'")) {
      final parts = s.split("'");
      final f = double.tryParse(parts[0].trim());
      if (f == null || f < 0) return null;
      feet = f;
      final rest = parts.length > 1 ? parts[1].trim() : '';
      if (rest.isNotEmpty) {
        final iv = _parseNumberOrFraction(rest);
        if (iv == null || iv < 0) return null;
        inches = iv;
      }
    } else {
      final iv = _parseNumberOrFraction(s);
      if (iv == null || iv < 0) return null;
      inches = iv;
    }
    final total = feet * 12 + inches;
    return total > 0 ? total : null;
  }

  /// Format an inch value for display in mode [m].
  static String format(double inches, MeasureMode m) {
    switch (m) {
      case MeasureMode.inches:
        return '${_trim(inches)} in';
      case MeasureMode.feetInches:
        return toFeetInches(inches);
      case MeasureMode.centimeters:
        return '${_trim(inches * inchToCm)} cm';
    }
  }

  /// Format an inch value as clean input-field text (no unit suffix),
  /// e.g. 12.5 -> "12.5", or "30.5" in cm mode, or 1' 2 1/2" in ft-in mode.
  static String formatInput(double inches, MeasureMode m) {
    switch (m) {
      case MeasureMode.inches:
        return _trim(inches);
      case MeasureMode.feetInches:
        return toFeetInches(inches);
      case MeasureMode.centimeters:
        return _trim(inches * inchToCm);
    }
  }

  static String _trim(double v) {
    var s = v.toStringAsFixed(2);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '');
      s = s.replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }

  /// Inch value as a trade fraction rounded to the nearest 1/16,
  /// e.g. 12.5 -> 12 1/2", 0.375 -> 3/8".
  static String fraction(double inches) {
    final neg = inches < 0;
    var v = inches.abs();
    var whole = v.floor();
    var sixteenths = ((v - whole) * 16).round();
    if (sixteenths == 16) {
      whole += 1;
      sixteenths = 0;
    }
    String body;
    if (sixteenths == 0) {
      body = '$whole"';
    } else {
      var n = sixteenths;
      var d = 16;
      while (n % 2 == 0) {
        n ~/= 2;
        d ~/= 2;
      }
      body = whole == 0 ? '$n/$d"' : '$whole $n/$d"';
    }
    return neg ? '-$body' : body;
  }

  /// e.g. 14.5 -> 1' 2 1/2"
  static String toFeetInches(double inches) {
    final neg = inches < 0;
    final v = inches.abs();
    final feet = (v / 12).floor();
    final rem = v - feet * 12;
    final s = feet == 0 ? fraction(rem) : "$feet' ${fraction(rem)}";
    return neg ? '-$s' : s;
  }

  /// Standard offset multipliers: 1 / sin(angle), rounded to 2 decimals —
  /// the numbers printed on every bender handle. (Non-const: double keys
  /// are not allowed in const maps.)
  static final Map<double, double> multipliers = {
    10: 5.76,
    15: 3.86,
    22.5: 2.61,
    30: 2.0,
    45: 1.41,
    60: 1.15,
  };

  static const List<double> angles = [10, 15, 22.5, 30, 45, 60];

  /// Shrink per inch of offset (pullback) by bend angle.
  static final Map<double, double> shrinkPerInch = {
    10: 0.06,
    15: 0.11,
    22.5: 0.20,
    30: 0.25,
    45: 0.41,
    60: 0.58,
  };

  static String angleLabel(double a) =>
      a == a.roundToDouble() ? '${a.toInt()}°' : '${a}°';

  static String multLabel(double m) =>
      m == m.roundToDouble() ? m.toInt().toString() : m.toString();
}
