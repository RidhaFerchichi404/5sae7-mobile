import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/utils/date_ranges.dart';
import '../../../core/utils/iso_time.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/category_picker.dart';
import '../../users/presentation/user_providers.dart';
import '../domain/budget.dart';
import '../domain/budget_validation.dart';
import 'budget_providers.dart';

class BudgetFormScreen extends ConsumerStatefulWidget {
  const BudgetFormScreen({super.key, required this.userId, this.existing});

  final int userId;
  final Budget? existing;

  @override
  ConsumerState<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends ConsumerState<BudgetFormScreen> {
  late final TextEditingController _limit;
  late String _period;
  late DateTime _month;
  late DateTime _start;
  late DateTime _end;
  Category? _category;
  BudgetValidationResult? _errors;
  String? _formError;
  String _currency = AppConstants.defaultCurrency;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _limit = TextEditingController(
      text: existing == null ? '' : existing.amountLimit.toString(),
    );
    _period = existing?.period ?? AppConstants.monthlyPeriod;
    _month = existing?.startDate ?? IsoTime.now();
    _start = existing?.startDate ?? DateRanges.monthBounds(IsoTime.now()).start;
    _end = existing?.endDate ?? DateRanges.monthBounds(IsoTime.now()).end;
    Future<void>.microtask(_load);
  }

  Future<void> _load() async {
    final user = await ref.read(userRepositoryProvider).getById(widget.userId);
    final existing = widget.existing;
    Category? category;
    if (existing != null) {
      category = await ref.read(categoryRepositoryProvider).getById(existing.categoryId);
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
    _limit.dispose();
    super.dispose();
  }

  ({DateTime start, DateTime end}) get _range {
    if (_period == AppConstants.monthlyPeriod) {
      return DateRanges.monthBounds(_month);
    }
    return (start: _start, end: _end);
  }

  Future<void> _save() async {
    final range = _range;
    final result = validateBudgetInput(
      BudgetInput(
        limitText: _limit.text,
        currencyCode: _currency,
        period: _period,
        startText: IsoTime.date(range.start),
        endText: IsoTime.date(range.end),
        category: _category,
        userId: widget.userId,
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
      final repository = ref.read(budgetRepositoryProvider);
      final existing = widget.existing;
      if (existing == null) {
        await repository.create(userId: widget.userId, input: result);
      } else {
        await repository.update(current: existing, input: result);
      }
      ref.invalidate(budgetListProvider);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on AppFailure catch (error) {
      setState(() => _formError = error.message);
    }
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _month = picked);
    }
  }

  Future<void> _pickBound({required bool start}) async {
    final initial = start ? _start : _end;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      if (start) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final range = _range;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New budget' : 'Edit budget'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Expense category'),
            subtitle: Text(_category?.name ?? 'Choose a category'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final picked = await pickCategory(
                context,
                type: AppConstants.expenseType,
              );
              if (picked != null) {
                setState(() => _category = picked);
              }
            },
          ),
          if (_errors?.categoryError != null) Text(_errors!.categoryError!),
          TextField(
            key: const Key('budget-limit'),
            controller: _limit,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount limit',
              suffixText: _currency,
              errorText: _errors?.limitError,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: AppConstants.monthlyPeriod, label: Text('Monthly')),
              ButtonSegment(value: AppConstants.customPeriod, label: Text('Custom')),
            ],
            selected: {_period},
            onSelectionChanged: (value) => setState(() => _period = value.first),
          ),
          const SizedBox(height: 12),
          if (_period == AppConstants.monthlyPeriod)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Month'),
              subtitle: Text(IsoTime.date(range.start)),
              onTap: _pickMonth,
            )
          else ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start'),
              subtitle: Text(IsoTime.date(_start)),
              onTap: () => _pickBound(start: true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('End'),
              subtitle: Text(IsoTime.date(_end)),
              onTap: () => _pickBound(start: false),
            ),
          ],
          if (_errors?.dateError != null) Text(_errors!.dateError!),
          if (_formError != null) ...[
            const SizedBox(height: 12),
            Text(_formError!, key: const Key('budget-form-error')),
          ],
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('save-budget'),
            onPressed: _save,
            child: const Text('Save budget'),
          ),
        ],
      ),
    );
  }
}
