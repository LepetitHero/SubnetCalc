import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ui/screens/home_screen.dart';

const _prefsThemeModeKey = 'theme_mode';

void main() {
  runApp(const SubnetCalculatorApp());
}

class SubnetCalculatorApp extends StatefulWidget {
  const SubnetCalculatorApp({super.key});

  @override
  State<SubnetCalculatorApp> createState() => _SubnetCalculatorAppState();
}

class _SubnetCalculatorAppState extends State<SubnetCalculatorApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _restoreThemeMode();
  }

  Future<void> _restoreThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsThemeModeKey);
    if (!mounted || saved == null) return;
    setState(() {
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => ThemeMode.system,
      );
    });
  }

  Future<void> _cycleThemeMode() async {
    const order = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];
    final next = order[(order.indexOf(_themeMode) + 1) % order.length];
    setState(() => _themeMode = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsThemeModeKey, next.name);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SubnetCalc',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: HomeScreen(themeMode: _themeMode, onCycleThemeMode: _cycleThemeMode),
    );
  }
}
