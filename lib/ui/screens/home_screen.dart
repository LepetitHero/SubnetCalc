import 'package:flutter/material.dart';

import 'simple_calculator_tab.dart';
import 'supernet_calculator_tab.dart';
import 'vlsm_calculator_tab.dart';

class HomeScreen extends StatelessWidget {
  final ThemeMode themeMode;
  final VoidCallback onCycleThemeMode;

  const HomeScreen({
    super.key,
    required this.themeMode,
    required this.onCycleThemeMode,
  });

  IconData get _themeIcon => switch (themeMode) {
        ThemeMode.system => Icons.brightness_auto_outlined,
        ThemeMode.light => Icons.light_mode_outlined,
        ThemeMode.dark => Icons.dark_mode_outlined,
      };

  String get _themeTooltip => switch (themeMode) {
        ThemeMode.system => 'Theme : systeme (appui pour clair)',
        ThemeMode.light => 'Theme : clair (appui pour sombre)',
        ThemeMode.dark => 'Theme : sombre (appui pour systeme)',
      };

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Calculateur de sous-reseaux IPv4'),
          actions: [
            IconButton(
              icon: Icon(_themeIcon),
              tooltip: _themeTooltip,
              onPressed: onCycleThemeMode,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Calculateur', icon: Icon(Icons.calculate_outlined)),
              Tab(
                text: 'VLSM',
                icon: Icon(Icons.dashboard_customize_outlined),
              ),
              Tab(text: 'Regroupement', icon: Icon(Icons.merge_type)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SimpleCalculatorTab(),
            VlsmCalculatorTab(),
            SupernetCalculatorTab(),
          ],
        ),
      ),
    );
  }
}
