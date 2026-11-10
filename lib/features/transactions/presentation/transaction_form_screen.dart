import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/iso_time.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/section_card.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/category_picker.dart';
import '../../users/presentation/user_providers.dart';
import '../data/exchange_rate_client.dart';
import '../domain/receipt_parser.dart';
import '../domain/transaction_record.dart';
import '../domain/transaction_validation.dart';
import 'transaction_providers.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key, required this.userId, this.existing});

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

  /// A foreign currency the amount was paid in, or null for the profile's.
  String? _paidIn;
  double? _rate;
  bool _rateLoading = false;
  bool _scanning = false;

  /// Fills amount, date and description from a receipt photo. The user
  /// still picks the category and checks everything before saving.
  Future<void> _scanReceipt() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(sheet).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(sheet).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) {
      return;
    }
    setState(() => _scanning = true);
    String? text;
    try {
      text = await ref.read(receiptScannerProvider).read(source);
    } catch (_) {
      text = '';
    }
    if (!mounted) {
      return;
    }
    setState(() => _scanning = false);
    if (text == null) {
      return; // Cancelled.
    }
    final draft = parseReceipt(text, today: IsoTime.now());
    setState(() {
      if (_type != AppConstants.expenseType) {
        _type = AppConstants.expenseType;
        _category = null;
      }
      if (draft.total case final total?) {
        _amount.text = Money.format(total, _paidIn ?? _currency);
      }
      if (draft.date case final date?) {
        _date = IsoTime.date(date);
      }
      if (draft.merchant case final name? when _description.text.isEmpty) {
        _description.text = name;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          draft.total == null
              ? 'No total found. Try a sharper, flat photo.'
              : 'Filled from the receipt. Check it, then pick a category.',
        ),
      ),
    );
  }

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

  Future<void> _choosePaidIn(String code) async {
    final foreign = code == _currency ? null : code;
    setState(() {
      _paidIn = foreign;
      _rate = null;
      _formError = null;
      _rateLoading = foreign != null;
    });
    if (foreign == null) {
      return;
    }
    final rate = await ref
        .read(exchangeRateClientProvider)
        .rate(foreign, _currency);
    if (!mounted) {
      return;
    }
    setState(() {
      _rateLoading = false;
      if (_paidIn == foreign) {
        _rate = rate;
      }
    });
  }

  String _conversionText() {
    final foreign = _paidIn!;
    final rate = _rate;
    if (_rateLoading) {
      return "Getting today's $foreign rate…";
    }
    if (rate == null) {
      return 'No $foreign rate available. Connect to the internet.';
    }
    final amount = double.tryParse(_amount.text.trim().replaceAll(',', '.'));
    final converted = amount == null
        ? ''
        : '≈ ${Money.format(amount * rate, _currency)} $_currency · ';
    return '${converted}1 $foreign = ${rate.toStringAsFixed(4)} $_currency'
        ' · ${ExchangeRateClient.attribution}';
  }

  TransactionInput _input(String amountText, String currency, String note) {
    return TransactionInput(
      amountText: amountText,
      currencyCode: currency,
      type: _type,
      category: _category,
      userId: widget.userId,
      dateText: _date,
      description: note,
    );
  }

  Future<void> _save() async {
    var amountText = _amount.text;
    var description = _description.text;
    final foreign = _paidIn;
    if (foreign != null) {
      // Validate in the paid currency, then store the converted amount and
      // keep the original in the description (the schema has no column).
      final paid = validateTransactionInput(
        _input(amountText, foreign, description),
      );
      if (paid.amountError != null) {
        setState(() {
          _errors = paid;
          _formError = null;
        });
        return;
      }
      final rate =
          _rate ??
          await ref.read(exchangeRateClientProvider).rate(foreign, _currency);
      if (!mounted) {
        return;
      }
      if (rate == null) {
        setState(
          () => _formError =
              'Could not get the $foreign rate. Connect to the internet '
              'or enter the amount in $_currency.',
        );
        return;
      }
      amountText = Money.format(paid.amount * rate, _currency);
      final note = '${Money.format(paid.amount, foreign)} $foreign';
      description = description.trim().isEmpty
          ? note
          : '${description.trim()} · $note';
    }
    final result = validateTransactionInput(
      _input(amountText, _currency, description),
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
        title: Text(
          widget.existing == null ? 'New transaction' : 'Edit transaction',
        ),
        actions: [
          IconButton(
            key: const Key('scan-receipt'),
            tooltip: 'Scan receipt',
            icon: const Icon(Icons.document_scanner_outlined),
            onPressed: _scanning ? null : _scanReceipt,
          ),
        ],
        bottom: _scanning
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
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
                    ButtonSegment(
                      value: AppConstants.incomeType,
                      label: Text('Income'),
                    ),
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('transaction-amount'),
                        controller: _amount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) {
                          if (_paidIn != null) {
                            setState(() {});
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          suffixText: _paidIn ?? _currency,
                          errorText: _errors?.amountError,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    SizedBox(
                      width: 104,
                      // Rebuilt once the profile currency loads.
                      child: KeyedSubtree(
                        key: ValueKey(_currency),
                        child: DropdownButtonFormField<String>(
                          key: const Key('paid-in'),
                          initialValue: _paidIn ?? _currency,
                          decoration: const InputDecoration(
                            labelText: 'Paid in',
                          ),
                          items: [
                            for (final code in AppConstants.currencies)
                              DropdownMenuItem(value: code, child: Text(code)),
                          ],
                          onChanged: (code) {
                            if (code != null) {
                              _choosePaidIn(code);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                if (_paidIn != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _conversionText(),
                    key: const Key('conversion-preview'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                AppSpacing.gap,
                ListTile(
                  key: const Key('transaction-category'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Category'),
                  subtitle: Text(
                    _category?.name ?? 'Choose a category',
                    style: TextStyle(
                      color: _errors?.categoryError == null
                          ? null
                          : AppColors.of(context).exceeded,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickCategory,
                ),
                if (_errors?.categoryError != null)
                  Text(_errors!.categoryError!),
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
                if (_formError != null) ...[AppSpacing.gap, Text(_formError!)],
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
