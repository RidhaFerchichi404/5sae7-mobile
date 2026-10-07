import '../../../core/utils/iso_time.dart';
import '../../../core/utils/money.dart';
import '../../categories/domain/category.dart';

class TransactionInput {
  const TransactionInput({
    required this.amountText,
    required this.currencyCode,
    required this.type,
    required this.category,
    required this.userId,
    required this.dateText,
    required this.description,
  });

  final String amountText;
  final String currencyCode;
  final String type;
  final Category? category;
  final int userId;
  final String dateText;
  final String description;
}

class TransactionValidationResult {
  const TransactionValidationResult({
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    required this.description,
    this.amountError,
    this.categoryError,
    this.dateError,
    this.descriptionError,
  });

  final double amount;
  final String type;
  final int categoryId;
  final DateTime date;
  final String? description;
  final String? amountError;
  final String? categoryError;
  final String? dateError;
  final String? descriptionError;

  bool get isValid =>
      amountError == null &&
      categoryError == null &&
      dateError == null &&
      descriptionError == null;

  String? get message =>
      amountError ?? categoryError ?? dateError ?? descriptionError;
}

TransactionValidationResult validateTransactionInput(TransactionInput input) {
  final amountError = _amountError(input.amountText, input.currencyCode);
  final amount = double.tryParse(input.amountText.trim().replaceAll(',', '.')) ?? 0;

  String? categoryError;
  final category = input.category;
  if (category == null) {
    categoryError = 'Choose a category.';
  } else if (category.userId != input.userId) {
    categoryError = 'Choose a category from this profile.';
  } else if (category.type != input.type) {
    categoryError = 'The category type must match the transaction.';
  }

  final date = IsoTime.tryParseDate(input.dateText.trim());
  final dateError = date == null ? 'Enter a valid date.' : null;

  final description = input.description.trim();
  final descriptionError = description.length > 200
      ? 'Keep the description under 200 characters.'
      : null;

  return TransactionValidationResult(
    amount: amount,
    type: input.type,
    categoryId: category?.id ?? 0,
    date: date ?? DateTime(1970),
    description: description.isEmpty ? null : description,
    amountError: amountError,
    categoryError: categoryError,
    dateError: dateError,
    descriptionError: descriptionError,
  );
}

String? _amountError(String raw, String currencyCode) {
  final text = raw.trim().replaceAll(',', '.');
  if (text.isEmpty || text.split('.').length > 2) {
    return 'Enter an amount greater than zero.';
  }
  final value = double.tryParse(text);
  if (value == null || value.isNaN || value.isInfinite || value <= 0) {
    return 'Enter an amount greater than zero.';
  }
  final dot = text.indexOf('.');
  if (dot != -1) {
    final decimals = text.length - dot - 1;
    if (decimals > Money.decimalScale(currencyCode)) {
      return 'Use at most ${Money.decimalScale(currencyCode)} decimal places.';
    }
  }
  return null;
}
