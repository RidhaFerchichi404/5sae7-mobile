import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../categories/presentation/category_providers.dart';
import '../../users/domain/user_profile.dart';
import '../../users/presentation/user_providers.dart';
import 'budget_form_screen.dart';
import 'budget_progress_card.dart';
import 'budget_providers.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key, required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(budgetListProvider(userId));
    final categories = ref.watch(categoryListProvider(null));
    final currency = ref.watch(userListProvider).maybeWhen(
      data: (users) => _currencyOf(users, userId),
      orElse: () => AppConstants.defaultCurrency,
    );
    final names = {
      for (final category in categories.maybeWhen(
        data: (value) => value,
        orElse: () => const [],
      ))
        category.id: category.name,
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => BudgetFormScreen(userId: userId),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: progress.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorView(message: error.toString()),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'No budgets',
              message: 'Create a spending limit for an expense category.',
            );
          }
          return ListView(
            padding: AppSpacing.screen,
            children: [
              for (var i = 0; i < items.length; i++)
                FadeSlideIn(
                  index: i,
                  child: BudgetProgressCard(
                    progress: items[i],
                    categoryName:
                        names[items[i].budget.categoryId] ?? 'Category',
                    currencyCode: currency,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => BudgetFormScreen(
                            userId: userId,
                            existing: items[i].budget,
                          ),
                        ),
                      );
                    },
                    onDelete: () async {
                      final confirmed = await showConfirmDialog(
                        context: context,
                        title: 'Delete budget',
                        message: 'Delete this budget? Transactions stay.',
                      );
                      if (!confirmed) {
                        return;
                      }
                      await ref
                          .read(budgetRepositoryProvider)
                          .delete(items[i].budget.id);
                      ref.invalidate(budgetListProvider);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

String _currencyOf(List<UserProfile> users, int userId) {
  for (final user in users) {
    if (user.id == userId) {
      return user.currency;
    }
  }
  return AppConstants.defaultCurrency;
}
