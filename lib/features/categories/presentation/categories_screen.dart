import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
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
                const SizedBox(height: 12),
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
            padding: const EdgeInsets.all(16),
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
                  children: [
                    for (final category in items)
                      ListTile(
                        leading: Icon(iconForKey(category.icon)),
                        title: Text(category.name),
                        subtitle: Text(
                          isPredefinedCategory(category) ? 'Predefined' : 'Custom',
                        ),
                        trailing: IconButton(
                          key: Key('delete-category-${category.id}'),
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(category),
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  CategoryFormScreen(existing: category),
                            ),
                          );
                        },
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
