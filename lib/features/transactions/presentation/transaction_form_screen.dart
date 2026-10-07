import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/iso_time.dart';
import '../../../shared/widgets/section_card.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/category_picker.dart';
import '../../users/presentation/user_providers.dart';
import '../domain/transaction_record.dart';
import '../domain/transaction_validation.dart';
import 'transaction_providers.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({
    super.key,
    required this.userId,
    this.existing,
  });

  final int userId;
  final TransactionRecord? existing;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  late final TextEditingController _amount;
  late final TextEditingController _description;
  late String _type;
  late String _date;
  Category? _category;
  TransactionValidationResult? _errors;
  String? _formError;
  String _currency = AppConstants.defaultCurrency;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _amount = TextEditingController(
      text: existing == null ? '' : existing.amount.toString(),
    );
    _description = TextEditingController(text: existing?.description ?? '');
    _type = existing?.type ?? AppConstants.expenseType;
    _date = existing == null
        ? IsoTime.date(IsoTime.now())
        : IsoTime.date(existing.transactionDate);
    Future<void>.microtask(_loadExtras);
  }

  Future<void> _loadExtras() async {
    final user = await ref.read(userRepositoryProvider).getById(widget.userId);
    final existing = widget.existing;
    Category? category;
    if (existing != null) {
      category = await ref
          .read(categoryRepositoryProvider)
          .getById(existing.categoryId);
    }
    if (mounted) {
      setState(() {
        _currency = user.currency;
        _category = category;
      });
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickCategory() async {
    final picked = await pickCategory(context, type: _type);
    if (picked != null) {
      setState(() => _category = picked);
    }
  }

  Future<void> _pickDate() async {
    final initial = IsoTime.tryParseDate(_date) ?? IsoTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = IsoTime.date(picked));
    }
  }

  Future<void> _save() async {
    final result = validateTransactionInput(
      TransactionInput(
        amountText: _amount.text,
        currencyCode: _currency,
        type: _type,
        category: _category,
        userId: widget.userId,
        dateText: _date,
        description: _description.text,
      ),
    );
    setState(() {
      _errors = result;
      _formError = null;
    });
    if (!result.isValid) {
      return;
    }
    try {
      final repository = ref.read(transactionRepositoryProvider);
      final existing = widget.existing;
      if (existing == null) {
        await repository.create(userId: widget.userId, input: result);
      } else {
        await repository.update(current: existing, input: result);
      }
      ref.invalidate(transactionListProvider);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on AppFailure catch (error) {
      setState(() => _formError = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expense = _type == AppConstants.expenseType;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New transaction' : 'Edit transaction'),
      ),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: AppConstants.expenseType,
                label: Text('Expense'),
              ),
              ButtonSegment(value: AppConstants.incomeType, label: Text('Income')),
            ],
            selected: {_type},
            onSelectionChanged: (value) {
              setState(() {
                _type = value.first;
                _category = null;
              });
            },
          ),
          AppSpacing.gap,
          TextField(
            key: const Key('transaction-amount'),
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount',
              suffixText: _currency,
              errorText: _errors?.amountError,
            ),
          ),
          AppSpacing.gap,
          ListTile(
            key: const Key('transaction-category'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Category'),
            subtitle: Text(
              _category?.name ?? 'Choose a category',
              style: TextStyle(
                color: _errors?.categoryError == null ? null : AppColors.exceeded,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickCategory,
          ),
          if (_errors?.categoryError != null) Text(_errors!.categoryError!),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            subtitle: Text(_date),
            onTap: _pickDate,
          ),
          if (_errors?.dateError != null) Text(_errors!.dateError!),
          TextField(
            controller: _description,
            decoration: InputDecoration(
              labelText: 'Description',
              errorText: _errors?.descriptionError,
            ),
          ),
          if (_formError != null) ...[
            AppSpacing.gap,
            Text(_formError!),
          ],
              ],
            ),
          ),
          AppSpacing.section,
          FilledButton(
            key: const Key('save-transaction'),
            onPressed: _save,
            child: Text(expense ? 'Save expense' : 'Save income'),
          ),
        ],
      ),
    );
  }
}
