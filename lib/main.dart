import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation/app_routes.dart';
import 'core/navigation/app_shell.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/dashboard/presentation/statistics_screen.dart';

// Feature providers belong in each feature's presentation folder.
// This root only provides the shared [ProviderScope].

void main() {
  runApp(const ProviderScope(child: MyBudgetApp()));
}

class MyBudgetApp extends ConsumerWidget {
  const MyBudgetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'MyBudget',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      home: const AppShell(),
      routes: {
        AppRoutes.dashboard: (_) => const DashboardScreen(),
        AppRoutes.statistics: (_) => const StatisticsScreen(),
      },
    );
  }
}
