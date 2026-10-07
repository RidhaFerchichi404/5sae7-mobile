import 'package:flutter/material.dart';

import '../../features/budgets/presentation/budgets_screen.dart';
import '../../features/categories/presentation/categories_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/dashboard/presentation/statistics_screen.dart';
import '../../features/transactions/presentation/transactions_screen.dart';
import '../../features/users/presentation/profile_screen.dart';

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
      body: pages[_index],
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

class _MorePage extends StatelessWidget {
  const _MorePage({required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Categories'),
            subtitle: const Text('Manage expense and income categories'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const CategoriesScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProfileScreen(userId: userId),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.insights_outlined),
            title: const Text('Statistics'),
            subtitle: const Text('Income, expenses, and budgets'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => StatisticsScreen(userId: userId),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
