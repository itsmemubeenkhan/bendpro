import 'package:flutter/material.dart';
import 'pro_widgets.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profiles_screen.dart';

void main() => runApp(const BendProApp());

class BendProApp extends StatelessWidget {
  const BendProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BendPro - Conduit Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: ProTheme.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ProTheme.accent,
          brightness: Brightness.dark,
        ).copyWith(
          primary: ProTheme.accent,
          secondary: ProTheme.accent,
          surface: ProTheme.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: ProTheme.bg,
          foregroundColor: Colors.white,
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: ProTheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: ProTheme.surface,
          selectedItemColor: ProTheme.accent,
          unselectedItemColor: ProTheme.textDim,
        ),
      ),
      home: const MainTabs(),
    );
  }
}

/// Bottom tab navigation: Calculators | History | Profiles.
/// Native app feel — no hamburger, no deep stacks.
class MainTabs extends StatefulWidget {
  const MainTabs({super.key});

  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  int _index = 0;

  static const _pages = [
    HomeScreen(),
    HistoryScreen(),
    ProfilesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate_outlined),
            activeIcon: Icon(Icons.calculate),
            label: 'Calculators',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.construction_outlined),
            activeIcon: Icon(Icons.construction),
            label: 'Benders',
          ),
        ],
      ),
    );
  }
}
