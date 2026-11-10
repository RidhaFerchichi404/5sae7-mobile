import '../../../core/constants/app_constants.dart';

class CategoryInput {
  const CategoryInput({
    this.name = '',
    this.type = AppConstants.expenseType,
    this.icon = 'category',
  });

  final String name;
  final String type;
  final String icon;
}

class CategoryValidationResult {
  const CategoryValidationResult({
    required this.name,
    required this.type,
    required this.icon,
    this.nameError,
    this.typeError,
    this.iconError,
  });

  final String name;
  final String type;
  final String icon;
  final String? nameError;
  final String? typeError;
  final String? iconError;

  bool get isValid =>
      nameError == null && typeError == null && iconError == null;

  String? get message => nameError ?? typeError ?? iconError;
}

CategoryValidationResult validateCategoryInput(CategoryInput input) {
  final name = input.name.trim();
  final type = input.type.trim().toUpperCase();
  final icon = input.icon.trim();

  String? nameError;
  if (name.isEmpty || name.length > 40) {
    nameError = 'Enter a name between 1 and 40 characters.';
  }

  String? typeError;
  if (!AppConstants.categoryTypes.contains(type)) {
    typeError = 'Choose expense or income.';
  }

  String? iconError;
  if (!AppConstants.iconCatalogue.contains(icon) && !isIconifyKey(icon)) {
    iconError = 'Choose an icon from the catalogue or the search.';
  }

  return CategoryValidationResult(
    name: name,
    type: type,
    icon: icon,
    nameError: nameError,
    typeError: typeError,
    iconError: iconError,
  );
}

String normalizedCategoryName(String name) => name.trim().toLowerCase();

/// Iconify sets allowed in the search: all Apache 2.0 or MIT licensed.
const iconifyPrefixes = ['mdi', 'tabler', 'material-symbols'];

final _iconifyKey = RegExp(r'^(mdi|tabler|material-symbols):[a-z0-9-]{1,60}$');

/// An icon from the Iconify search, stored as `prefix:name`.
bool isIconifyKey(String icon) => _iconifyKey.hasMatch(icon);
