import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../categories/data/category_repository.dart';
import '../data/user_repository.dart';
import '../domain/user_profile.dart';
import '../domain/user_validation.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(appDatabaseProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(appDatabaseProvider));
});

final userListProvider = FutureProvider<List<UserProfile>>((ref) {
  return ref.watch(userRepositoryProvider).list();
});

final activeUserIdProvider =
    AsyncNotifierProvider<ActiveUserController, int?>(ActiveUserController.new);

class ActiveUserController extends AsyncNotifier<int?> {
  @override
  Future<int?> build() async {
    final users = await ref.watch(userRepositoryProvider).list();
    if (users.length == 1) {
      return users.single.id;
    }
    return null;
  }

  void select(int? id) {
    state = AsyncData(id);
  }

  Future<UserProfile> create(UserValidationResult input) async {
    final user = await ref.read(userRepositoryProvider).create(input);
    await ref.read(categoryRepositoryProvider).seedDefaultCategories(user.id);
    ref.invalidate(userListProvider);
    state = AsyncData(user.id);
    return user;
  }

  Future<void> remove(int id) async {
    await ref.read(userRepositoryProvider).delete(id);
    ref.invalidate(userListProvider);
    final users = await ref.read(userRepositoryProvider).list();
    state = AsyncData(users.length == 1 ? users.single.id : null);
  }
}
