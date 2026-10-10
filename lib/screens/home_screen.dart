import 'package:flutter/material.dart';
import '../widgets.dart';
import 'offset_screen.dart';
import 'rolling_offset_screen.dart';
import 'stub_up_screen.dart';
import 'three_point_saddle_screen.dart';
import 'four_point_saddle_screen.dart';
import 'kick_screen.dart';
import 'ubend_screen.dart';
import 'history_screen.dart';
import 'profiles_screen.dart';

class _CalcInfo {
  final String title;
  final String description;
  final IconData icon;
  final Widget Function() page;
  const _CalcInfo(this.title, this.description, this.icon, this.page);
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<_CalcInfo> _calcs = [
    _CalcInfo(
      'Offset Bend',
      'Mark spacing for any offset height and angle',
      Icons.trending_up,
      OffsetScreen.new,
    ),
    _CalcInfo(
      'Rolling Offset',
      'True offset from vertical rise and horizontal roll',
      Icons.transform,
      RollingOffsetScreen.new,
    ),
    _CalcInfo(
      '90° Stub-Up',
      'Mark point using the conduit deduct',
      Icons.vertical_align_top,
      StubUpScreen.new,
    ),
    _CalcInfo(
      'Three-Point Saddle',
      'Jump an obstruction with a 45° center bend',
      Icons.waves,
      ThreePointSaddleScreen.new,
    ),
    _CalcInfo(
      'Four-Point Saddle',
      'Two offsets over a wide obstruction',
      Icons.view_column,
      FourPointSaddleScreen.new,
    ),
    _CalcInfo(
      'Kick (90°)',
      'Single-bend kick distance from the end',
      Icons.arrow_upward,
      KickScreen.new,
    ),
    _CalcInfo(
      'Double 90° (U-Bend)',
      'Up, across, and back down over an obstacle',
      Icons.u_turn_left,
      UBendScreen.new,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BendPro',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Bender profiles',
            icon: const Icon(Icons.construction_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfilesScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Calculation history',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          const UnitToggle(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const Text(
            'Conduit Calculator',
            style: TextStyle(
              color: kAmber,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pick a bend. Enter your numbers. Mark it right the first time.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            itemCount: _calcs.length,
            itemBuilder: (context, i) {
              final c = _calcs[i];
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => c.page()),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: kAmber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(c.icon, color: kAmber, size: 26),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          c.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c.description,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Works fully offline. No account, no ads, no tracking.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
