import 'package:flutter/material.dart';

import '../../features/budgets/presentation/budgets_screen.dart';
import '../../features/categories/presentation/categories_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/dashboard/presentation/statistics_screen.dart';
import '../../features/transactions/presentation/transactions_screen.dart';
import '../../features/users/presentation/profile_screen.dart';
import '../../shared/widgets/fade_slide_in.dart';
import '../../shared/widgets/section_card.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.userId});

  final int userId;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(userId: widget.userId),
      TransactionsScreen(userId: widget.userId),
      BudgetsScreen(userId: widget.userId),
      _MorePage(userId: widget.userId),
    ];
    return Scaffold(
      body: AnimatedSwitcher(
        duration: AppMotion.duration,
        switchInCurve: AppMotion.curve,
        switchOutCurve: AppMotion.curve,
        child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Dashboard'),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            label: 'Budgets',
          ),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}

class _MoreEntry {
  const _MoreEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.open,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final void Function(BuildContext context, int userId) open;
}

const _entries = [
  _MoreEntry(
    icon: Icons.category_outlined,
    title: 'Categories',
    subtitle: 'Manage expense and income categories',
    open: _openCategories,
  ),
  _MoreEntry(
    icon: Icons.person_outline,
    title: 'Profile',
    subtitle: 'Name, email, and currency',
    open: _openProfile,
  ),
  _MoreEntry(
    icon: Icons.insights_outlined,
    title: 'Statistics',
    subtitle: 'Income, expenses, and budgets',
    open: _openStatistics,
  ),
];

void _openCategories(BuildContext context, int userId) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const CategoriesScreen()),
  );
}

void _openProfile(BuildContext context, int userId) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => ProfileScreen(userId: userId)),
  );
}

void _openStatistics(BuildContext context, int userId) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => StatisticsScreen(userId: userId)),
  );
}

class _MorePage extends StatelessWidget {
  const _MorePage({required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          for (var i = 0; i < _entries.length; i++)
            FadeSlideIn(
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: SectionCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: Icon(_entries[i].icon),
                    title: Text(_entries[i].title),
                    subtitle: Text(
                      _entries[i].subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    onTap: () => _entries[i].open(context, userId),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
