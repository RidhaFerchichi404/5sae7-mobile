import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../users/presentation/user_providers.dart';
import '../domain/category.dart';
import 'category_form_screen.dart';
import 'category_icons.dart';
import 'category_providers.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  String _type = AppConstants.expenseType;

  Future<void> _delete(Category category) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Delete category',
      message: 'Delete ${category.name}?',
    );
    if (!confirmed || !mounted) {
      return;
    }
    try {
      await ref.read(categoryRepositoryProvider).delete(category.id);
      ref.invalidate(categoryListProvider);
    } on RestrictFailure catch (error) {
      if (!mounted) {
        return;
      }
      await _offerReassign(category, error.message);
    } on AppFailure catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _offerReassign(Category category, String message) async {
    final others = await ref.read(
      categoryListProvider(category.type).future,
    );
    final targets = others.where((item) => item.id != category.id).toList();
    if (!mounted) {
      return;
    }
    final target = await showDialog<Category>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Category still in use'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, key: const Key('category-restrict')),
                const SizedBox(height: AppSpacing.xs),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final item in targets)
                        ListTile(
                          title: Text(item.name),
                          onTap: () => Navigator.of(context).pop(item),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
    if (target == null) {
      return;
    }
    await ref.read(categoryRepositoryProvider).reassign(
      fromId: category.id,
      toId: target.id,
    );
    await ref.read(categoryRepositoryProvider).delete(category.id);
    ref.invalidate(categoryListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryListProvider(_type));
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const CategoryFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.screen,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: AppConstants.expenseType,
                  label: Text('Expense'),
                ),
                ButtonSegment(
                  value: AppConstants.incomeType,
                  label: Text('Income'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (value) => setState(() => _type = value.first),
            ),
          ),
          Expanded(
            child: categories.when(
              loading: () => const LoadingIndicator(),
              error: (error, _) => ErrorView(message: error.toString()),
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    title: 'No categories',
                    message: 'Add a category for this type.',
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    0,
                    AppSpacing.sm,
                    88,
                  ),
                  children: [
                    for (var i = 0; i < items.length; i++)
                      FadeSlideIn(
                        index: i,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Card(
                            child: ListTile(
                              leading: Icon(iconForKey(items[i].icon)),
                              title: Text(items[i].name),
                              subtitle: Text(
                                isPredefinedCategory(items[i])
                                    ? 'Predefined'
                                    : 'Custom',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              trailing: IconButton(
                                key: Key('delete-category-${items[i].id}'),
                                tooltip: 'Delete category',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _delete(items[i]),
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        CategoryFormScreen(existing: items[i]),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
