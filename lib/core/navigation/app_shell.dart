import 'package:flutter/material.dart';

import '../../shared/widgets/placeholder_screen.dart';

/// Shell shown before a feature owns the active profile.
/// Feature providers stay in each feature's presentation folder.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _destinations = [
    (label: 'Dashboard', icon: Icons.home_outlined, selected: Icons.home),
    (
      label: 'Transactions',
      icon: Icons.receipt_long_outlined,
      selected: Icons.receipt_long,
    ),
    (
      label: 'Budgets',
      icon: Icons.pie_chart_outline,
      selected: Icons.pie_chart,
    ),
    (label: 'More', icon: Icons.more_horiz, selected: Icons.more_horiz),
  ];

  @override
  Widget build(BuildContext context) {
    final current = _destinations[_index];
    return Scaffold(
      body: PlaceholderScreen(
        title: current.label,
        message: 'Shared placeholder. The feature owner will replace this screen.',
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: [
          for (final destination in _destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selected),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}
