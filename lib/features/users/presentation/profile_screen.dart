import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/iso_time.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../domain/user_profile.dart';
import 'edit_profile_screen.dart';
import 'user_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userListProvider);
    return user.when(
      loading: () => const Scaffold(body: LoadingIndicator()),
      error: (error, _) => Scaffold(body: ErrorView(message: error.toString())),
      data: (users) {
        final matches = users.where((item) => item.id == userId);
        if (matches.isEmpty) {
          return const Scaffold(
            body: ErrorView(message: 'This profile no longer exists.'),
          );
        }
        return _ProfileBody(user: matches.first);
      },
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.user});

  final UserProfile user;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Delete profile',
      message:
          'Delete ${user.name}? This removes their categories, transactions, and budgets.',
    );
    if (!confirmed) {
      return;
    }
    await ref.read(activeUserIdProvider.notifier).remove(user.id);
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          FadeSlideIn(
            child: SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(user.email, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
          AppSpacing.section,
          FadeSlideIn(
            index: 1,
            child: SectionCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Currency'),
                    trailing: Text(user.currency),
                  ),
                  ListTile(
                    title: const Text('Created'),
                    trailing: Text(
                      IsoTime.date(user.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.section,
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => EditProfileScreen(user: user),
                ),
              );
            },
            child: const Text('Edit profile'),
          ),
          AppSpacing.gap,
          OutlinedButton(
            onPressed: () {
              ref.read(activeUserIdProvider.notifier).select(null);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Switch profile'),
          ),
          TextButton(
            key: const Key('delete-profile'),
            onPressed: () => _delete(context, ref),
            child: const Text(
              'Delete profile',
              style: TextStyle(color: AppColors.exceeded),
            ),
          ),
        ],
      ),
    );
  }
}
