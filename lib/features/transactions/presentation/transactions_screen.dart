import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/iso_time.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/category_providers.dart';
import '../../users/domain/user_profile.dart';
import '../../users/presentation/user_providers.dart';
import '../domain/transaction_query.dart';
import '../domain/transaction_record.dart';
import 'transaction_form_screen.dart';
import 'transaction_providers.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key, required this.userId});

  final int userId;

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _search = TextEditingController();
  String? _type;
  int? _categoryId;
  TransactionSortField _sort = TransactionSortField.date;
  bool _ascending = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  TransactionQuery get _query => TransactionQuery(
    userId: widget.userId,
    search: _search.text,
    type: _type,
    categoryId: _categoryId,
    sortField: _sort,
    ascending: _ascending,
  );

  Future<void> _delete(TransactionRecord item) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Delete transaction',
      message: 'Delete this ${item.type.toLowerCase()}?',
    );
    if (!confirmed) {
      return;
    }
    await ref.read(transactionRepositoryProvider).delete(item.id);
    ref.invalidate(transactionListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(transactionListProvider(_query));
    final categories = ref.watch(categoryListProvider(null));
    final currency = ref.watch(userListProvider).maybeWhen(
      data: (users) => _currencyOf(users, widget.userId),
      orElse: () => AppConstants.defaultCurrency,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      floatingActionButton: FloatingActionButton(
        key: const Key('add-transaction'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TransactionFormScreen(userId: widget.userId),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                labelText: 'Search description',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _type == null,
                  onSelected: (_) => setState(() => _type = null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Expense'),
                  selected: _type == AppConstants.expenseType,
                  onSelected: (_) =>
                      setState(() => _type = AppConstants.expenseType),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Income'),
                  selected: _type == AppConstants.incomeType,
                  onSelected: (_) =>
                      setState(() => _type = AppConstants.incomeType),
                ),
                const SizedBox(width: 8),
                categories.maybeWhen(
                  data: (items) => DropdownButton<int?>(
                    value: _categoryId,
                    hint: const Text('Category'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All categories'),
                      ),
                      for (final category in items)
                        DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        ),
                    ],
                    onChanged: (value) => setState(() => _categoryId = value),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
                const SizedBox(width: 8),
                DropdownButton<TransactionSortField>(
                  value: _sort,
                  items: const [
                    DropdownMenuItem(
                      value: TransactionSortField.date,
                      child: Text('Date'),
                    ),
                    DropdownMenuItem(
                      value: TransactionSortField.amount,
                      child: Text('Amount'),
                    ),
                    DropdownMenuItem(
                      value: TransactionSortField.categoryName,
                      child: Text('Category'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _sort = value);
                    }
                  },
                ),
                IconButton(
                  onPressed: () => setState(() => _ascending = !_ascending),
                  icon: Icon(
                    _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.when(
              loading: () => const LoadingIndicator(),
              error: (error, _) => ErrorView(message: error.toString()),
              data: (rows) {
                if (rows.isEmpty) {
                  return const EmptyState(
                    title: 'No transactions',
                    message: 'Add an income or an expense to start the history.',
                  );
                }
                final names = {
                  for (final category in categories.maybeWhen(
                    data: (value) => value,
                    orElse: () => const <Category>[],
                  ))
                    category.id: category.name,
                };
                return ListView(
                  children: [
                    for (final item in rows)
                      ListTile(
                        title: Text(names[item.categoryId] ?? item.type),
                        subtitle: Text(
                          '${IsoTime.date(item.transactionDate)}'
                          '${item.description == null ? '' : ' · ${item.description}'}',
                        ),
                        trailing: AmountText(
                          amount: item.amount,
                          currencyCode: currency,
                          expense: item.isExpense,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => TransactionFormScreen(
                                userId: widget.userId,
                                existing: item,
                              ),
                            ),
                          );
                        },
                        onLongPress: () => _delete(item),
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

String _currencyOf(List<UserProfile> users, int userId) {
  for (final user in users) {
    if (user.id == userId) {
      return user.currency;
    }
  }
  return AppConstants.defaultCurrency;
}
