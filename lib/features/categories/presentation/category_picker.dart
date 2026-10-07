import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/fade_slide_in.dart';
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
            padding: AppSpacing.screen,
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
                        onTap: () => Navigator.of(context).pop(items[i]),
                      ),
                    ),
                  ),
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
