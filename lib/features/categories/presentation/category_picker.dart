import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../domain/category.dart';
import 'category_icons.dart';
import 'category_providers.dart';

class CategoryPickerPage extends ConsumerWidget {
  const CategoryPickerPage({super.key, this.type});

  final String? type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryListProvider(type));
    return Scaffold(
      appBar: AppBar(
        title: Text(type == null ? 'Category' : 'Choose $type'),
      ),
      body: categories.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'No categories',
              message: 'Create a category before continuing.',
            );
          }
          return ListView(
            children: [
              for (final category in items)
                ListTile(
                  leading: Icon(iconForKey(category.icon)),
                  title: Text(category.name),
                  onTap: () => Navigator.of(context).pop(category),
                ),
            ],
          );
        },
      ),
    );
  }
}

Future<Category?> pickCategory(
  BuildContext context, {
  String? type,
}) {
  return Navigator.of(context).push<Category>(
    MaterialPageRoute(builder: (_) => CategoryPickerPage(type: type)),
  );
}
