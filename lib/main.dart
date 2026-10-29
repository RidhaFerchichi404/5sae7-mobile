import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation/app_routes.dart';
import 'core/navigation/app_shell.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/budgets/presentation/budget_providers.dart';
import 'features/dashboard/presentation/statistics_screen.dart';
import 'features/transactions/presentation/transaction_providers.dart';
import 'features/users/presentation/user_providers.dart';
import 'shared/demo/demo_seed.dart';

// Feature providers belong in each feature's presentation folder.
// This root only provides the shared [ProviderScope].

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  // Debug and profile builds start with demo data; release builds start empty.
  if (!kReleaseMode) {
    await _seedDemoData(container);
  }
  runApp(
    UncontrolledProviderScope(container: container, child: const MyBudgetApp()),
  );
}

/// Fills an empty database once. Any existing profile means it never runs.
Future<void> _seedDemoData(ProviderContainer container) async {
  try {
    final users = container.read(userRepositoryProvider);
    if ((await users.list()).isNotEmpty) {
      return;
    }
    await DemoSeed(
      users: users,
      categories: container.read(categoryRepositoryProvider),
      transactions: container.read(transactionRepositoryProvider),
      budgets: container.read(budgetRepositoryProvider),
    ).run();
  } catch (error) {
    // The app still opens, on the empty profile gate.
    debugPrint('Demo data was not seeded: $error');
  }
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
