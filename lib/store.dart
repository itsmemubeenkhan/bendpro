import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence: calculation history and named bender profiles.
/// Everything stays on the device — no accounts, no network.

class HistoryEntry {
  final DateTime time;
  final String calc;
  final String summary;

  HistoryEntry({required this.time, required this.calc, required this.summary});

  String encode() => '${time.toIso8601String()}|$calc|$summary';

  static HistoryEntry? decode(String s) {
    final parts = s.split('|');
    if (parts.length < 3) return null;
    final t = DateTime.tryParse(parts[0]);
    if (t == null) return null;
    return HistoryEntry(
        time: t, calc: parts[1], summary: parts.sublist(2).join('|'));
  }
}

class HistoryStore {
  static const _key = 'bendpro_history_v1';
  static const _max = 60;

  static Future<void> add(String calc, String summary) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.insert(
        0, HistoryEntry(time: DateTime.now(), calc: calc, summary: summary).encode());
    while (list.length > _max) {
      list.removeLast();
    }
    await prefs.setStringList(_key, list);
  }

  static Future<List<HistoryEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list
        .map(HistoryEntry.decode)
        .whereType<HistoryEntry>()
        .toList();
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

/// A named bender with custom deduct-per-size values, e.g. "My Greenlee 555".
/// Deducts are stored in inches keyed by conduit size label.
class BenderProfile {
  final String name;
  final Map<String, double> deducts;

  BenderProfile({required this.name, required this.deducts});

  Map<String, dynamic> toJson() => {'name': name, 'deducts': deducts};

  static BenderProfile? fromJson(Map<String, dynamic> j) {
    final name = j['name'] as String?;
    final d = j['deducts'] as Map?;
    if (name == null || d == null) return null;
    final deducts = <String, double>{};
    for (final s in ProfileStore.sizes) {
      final v = d[s];
      if (v is num) deducts[s] = v.toDouble();
    }
    if (deducts.length != ProfileStore.sizes.length) return null;
    return BenderProfile(name: name, deducts: deducts);
  }
}

class ProfileStore {
  static const List<String> sizes = ['1/2"', '3/4"', '1"', '1-1/4"'];

  /// Factory deducts for standard EMT benders.
  static const Map<String, double> standardDeducts = {
    '1/2"': 5,
    '3/4"': 6,
    '1"': 8,
    '1-1/4"': 11,
  };

  static const _key = 'bendpro_profiles_v1';
  static const _activeKey = 'bendpro_active_profile_v1';

  static Future<List<BenderProfile>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(BenderProfile.fromJson)
          .whereType<BenderProfile>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAll(List<BenderProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(profiles.map((p) => p.toJson()).toList()));
  }

  /// Name of the active profile, or null for the built-in Standard EMT.
  static Future<String?> activeName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeKey);
  }

  static Future<void> setActive(String? name) async {
    final prefs = await SharedPreferences.getInstance();
    if (name == null) {
      await prefs.remove(_activeKey);
    } else {
      await prefs.setString(_activeKey, name);
    }
  }

  /// Resolve deducts for the active profile (or standard when none).
  static Future<Map<String, double>> activeDeducts() async {
    final name = await activeName();
    if (name == null) return Map.of(standardDeducts);
    final profiles = await load();
    final match = profiles.where((p) => p.name == name);
    if (match.isEmpty) return Map.of(standardDeducts);
    return Map.of(match.first.deducts);
  }
}
