import 'package:flutter/material.dart';
import '../pro_widgets.dart';
import '../units.dart';
import 'offset_screen.dart';
import 'rolling_offset_screen.dart';
import 'stub_up_screen.dart';
import 'three_point_saddle_screen.dart';
import 'four_point_saddle_screen.dart';
import 'kick_screen.dart';
import 'ubend_screen.dart';
import 'segmented_screen.dart';
import 'concentric_screen.dart';
import 'backtoback_screen.dart';
import 'shrink_screen.dart';

class _CalcInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget Function() page;
  const _CalcInfo(this.title, this.subtitle, this.icon, this.page);
}

/// Calculator grid — premium cards, compact, no scrolling needed
/// for the core list (11 items fit with minimal scroll on most phones).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<_CalcInfo> _calcs = [
    _CalcInfo('Offset Bend', 'Two bends, parallel shift',
        Icons.trending_up, OffsetScreen.new),
    _CalcInfo('Rolling Offset', 'Rise + roll true offset',
        Icons.transform, RollingOffsetScreen.new),
    _CalcInfo('90° Stub-Up', 'Riser to finished height',
        Icons.vertical_align_top, StubUpScreen.new),
    _CalcInfo('Three-Point Saddle', 'Jump an obstruction',
        Icons.waves, ThreePointSaddleScreen.new),
    _CalcInfo('Four-Point Saddle', 'Wide obstruction cross',
        Icons.view_column, FourPointSaddleScreen.new),
    _CalcInfo('Kick (90°)', 'Single bend off surface',
        Icons.arrow_upward, KickScreen.new),
    _CalcInfo('Double 90°', 'U-bend over obstacle',
        Icons.u_turn_left, UBendScreen.new),
    _CalcInfo('Segmented 90°', 'Smooth sweep, no kinks',
        Icons.donut_large, SegmentedScreen.new),
    _CalcInfo('Concentric 90°s', 'Parallel conduit runs',
        Icons.filter_none, ConcentricScreen.new),
    _CalcInfo('Back-to-Back 90s', 'Two 90s with run between',
        Icons.swap_vert, BackToBackScreen.new),
    _CalcInfo('Shrink Chart', 'Pullback reference table',
        Icons.table_chart, ShrinkScreen.new),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProTheme.bg,
      appBar: AppBar(
        backgroundColor: ProTheme.bg,
        elevation: 0,
        title: const Text('BendPro',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        actions: const [ProUnitToggle()],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'Pick a bend — results update live.',
                  style: TextStyle(color: ProTheme.textDim, fontSize: 14),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 108,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final c = _calcs[i];
                    return _CalcCard(info: c);
                  },
                  childCount: _calcs.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalcCard extends StatelessWidget {
  final _CalcInfo info;
  const _CalcCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ProTheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => info.page()),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ProTheme.border),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(info.icon, color: ProTheme.accent, size: 28),
              const SizedBox(height: 8),
              Text(
                info.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                info.subtitle,
                style:
                    const TextStyle(color: ProTheme.textDim, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
