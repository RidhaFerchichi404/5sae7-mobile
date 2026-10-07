import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/users/presentation/profile_gate_screen.dart';
import '../../features/users/presentation/user_providers.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import 'home_shell.dart';

/// Chooses the profile gate or the main shell from the active profile.
/// Feature providers stay in each feature's presentation folder.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeUserIdProvider);
    return active.when(
      loading: () => const Scaffold(body: LoadingIndicator()),
      error: (error, _) => Scaffold(
        body: ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(activeUserIdProvider),
        ),
      ),
      data: (userId) {
        if (userId == null) {
          return const ProfileGateScreen();
        }
        return HomeShell(userId: userId);
      },
    );
  }
}
