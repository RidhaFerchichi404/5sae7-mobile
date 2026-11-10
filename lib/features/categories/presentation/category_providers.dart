import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../users/presentation/user_providers.dart';
import '../data/iconify_client.dart';
import '../domain/category.dart';

final iconifyClientProvider = Provider<IconifyClient>((ref) {
  return IconifyClient(ref.watch(apiClientProvider));
});

/// The SVG for an Iconify key, or null while offline with no cache.
final iconSvgProvider = FutureProvider.family<String?, String>((ref, key) {
  return ref.watch(iconifyClientProvider).svg(key);
});

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
