import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() => runApp(const BendProApp());

class BendProApp extends StatelessWidget {
  const BendProApp({super.key});

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFFFB300);
    return MaterialApp(
      title: 'BendPro - Conduit Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF14171B),
        colorScheme: ColorScheme.fromSeed(
          seedColor: amber,
          brightness: Brightness.dark,
        ).copyWith(
          primary: amber,
          secondary: amber,
          surface: const Color(0xFF1E2226),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E2226),
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF1E2226),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
