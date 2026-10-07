import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../users/presentation/user_providers.dart';
import '../domain/category.dart';

final categoryListProvider = FutureProvider.family<List<Category>, String?>((
  ref,
  type,
) async {
  final userId = await ref.watch(activeUserIdProvider.future);
  if (userId == null) {
    return const [];
  }
  return ref.watch(categoryRepositoryProvider).list(userId: userId, type: type);
});

bool isPredefinedCategory(Category category) {
  return AppConstants.predefinedCategories.any(
    (item) => item.name == category.name && item.type == category.type,
  );
}
