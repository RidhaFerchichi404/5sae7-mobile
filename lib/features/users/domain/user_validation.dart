import '../../../core/constants/app_constants.dart';

class UserInput {
  const UserInput({
    this.name = '',
    this.email = '',
    this.currency = AppConstants.defaultCurrency,
  });

  final String name;
  final String email;
  final String currency;
}

class UserValidationResult {
  const UserValidationResult({
    required this.name,
    required this.email,
    required this.currency,
    this.nameError,
    this.emailError,
    this.currencyError,
  });

  final String name;
  final String email;
  final String currency;
  final String? nameError;
  final String? emailError;
  final String? currencyError;

  bool get isValid =>
      nameError == null && emailError == null && currencyError == null;
}

UserValidationResult validateUserInput(UserInput input) {
  final name = input.name.trim();
  final email = input.email.trim().toLowerCase();
  final currency = input.currency.trim().toUpperCase();

  String? nameError;
  if (name.isEmpty || name.length > 80) {
    nameError = 'Enter a name between 1 and 80 characters.';
  }

  String? emailError;
  if (!_validEmail(email)) {
    emailError = 'Enter a valid email address.';
  }

  String? currencyError;
  if (!AppConstants.currencies.contains(currency)) {
    currencyError = 'Choose a supported currency.';
  }

  return UserValidationResult(
    name: name,
    email: email,
    currency: currency,
    nameError: nameError,
    emailError: emailError,
    currencyError: currencyError,
  );
}

bool _validEmail(String email) {
  final parts = email.split('@');
  if (parts.length != 2) {
    return false;
  }
  final local = parts[0];
  final domain = parts[1];
  return local.isNotEmpty && domain.contains('.') && !domain.startsWith('.');
}
