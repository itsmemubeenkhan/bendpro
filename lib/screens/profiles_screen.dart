import 'package:flutter/material.dart';
import '../store.dart';
import '../units.dart';
import '../widgets.dart';

/// Manage named bender profiles with custom deduct-per-size values.
/// The active profile's deducts are used by the 90° stub-up and
/// double-90° calculators.
class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  List<BenderProfile> _profiles = [];
  String? _active;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profiles = await ProfileStore.load();
    final active = await ProfileStore.activeName();
    if (mounted) {
      setState(() {
        _profiles = profiles;
        _active = active;
        _loading = false;
      });
    }
  }

  Future<void> _setActive(String? name) async {
    await ProfileStore.setActive(name);
    _load();
  }

  Future<void> _delete(BenderProfile p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${p.name}"?'),
        content: const Text(
            'Calculators using this profile will fall back to the standard EMT deducts.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (ok == true) {
      _profiles.removeWhere((x) => x.name == p.name);
      await ProfileStore.saveAll(_profiles);
      if (_active == p.name) await ProfileStore.setActive(null);
      _load();
    }
  }

  Future<void> _edit({BenderProfile? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final deductCtrls = {
      for (final s in ProfileStore.sizes)
        s: TextEditingController(
            text: (existing?.deducts[s] ??
                    ProfileStore.standardDeducts[s]!)
                .toString())
    };

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'New bender profile' : 'Edit profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Bender name',
                  hintText: 'e.g. My Greenlee 555',
                ),
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Deduct per conduit size (inches)',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ),
              const SizedBox(height: 8),
              ...ProfileStore.sizes.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      controller: deductCtrls[s],
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: '$s EMT',
                        suffixText: 'in',
                        isDense: true,
                      ),
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Give the profile a name.')));
                return;
              }
              final deducts = <String, double>{};
              for (final s in ProfileStore.sizes) {
                final v = double.tryParse(deductCtrls[s]!.text.trim());
                if (v == null || v <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Enter a valid deduct for $s.')));
                  return;
                }
                deducts[s] = v;
              }
              final idx = _profiles.indexWhere((p) =>
                  p.name.toLowerCase() == name.toLowerCase() &&
                  p.name != existing?.name);
              if (idx >= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('A profile with that name already exists.')));
                return;
              }
              if (existing == null) {
                _profiles.add(BenderProfile(name: name, deducts: deducts));
              } else {
                final i =
                    _profiles.indexWhere((p) => p.name == existing.name);
                if (i >= 0) {
                  _profiles[i] = BenderProfile(name: name, deducts: deducts);
                  if (_active == existing.name) {
                    ProfileStore.setActive(name);
                  }
                }
              }
              ProfileStore.saveAll(_profiles);
              Navigator.of(ctx).pop(true);
            },
          ),
        ],
      ),
    );
    for (final c in deductCtrls.values) {
      c.dispose();
    }
    nameCtrl.dispose();
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bender Profiles')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kAccent,
        foregroundColor: Colors.black,
        tooltip: 'Add profile',
        onPressed: () => _edit(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                const Text(
                  'Save your own bender\'s deduct values once, then pick the profile in the stub-up calculators.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 16),
                _profileTile(
                  name: 'Standard EMT',
                  deducts: ProfileStore.standardDeducts,
                  active: _active == null,
                  builtin: true,
                  onTap: () => _setActive(null),
                ),
                ..._profiles.map((p) => _profileTile(
                      name: p.name,
                      deducts: p.deducts,
                      active: _active == p.name,
                      builtin: false,
                      onTap: () => _setActive(p.name),
                      onEdit: () => _edit(existing: p),
                      onDelete: () => _delete(p),
                    )),
              ],
            ),
    );
  }

  Widget _profileTile({
    required String name,
    required Map<String, double> deducts,
    required bool active,
    required bool builtin,
    required VoidCallback onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: active
            ? const BorderSide(color: kAccent, width: 1.2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    active
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: active ? kAccent : Colors.white38,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ),
                  if (!builtin) ...[
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit_outlined,
                          size: 20, color: Colors.white60),
                      onPressed: onEdit,
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: Colors.redAccent),
                      onPressed: onDelete,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: ProfileStore.sizes
                    .map((s) => Text(
                          '$s: ${AppUnits.fraction(deducts[s]!)}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12.5),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
