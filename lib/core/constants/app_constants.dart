/// Shared values. Feature modules must not copy this list.
abstract final class AppConstants {
  static const currencies = ['TND', 'EUR', 'USD', 'GBP', 'MAD'];
  static const defaultCurrency = 'TND';

  static const expenseType = 'EXPENSE';
  static const incomeType = 'INCOME';
  static const categoryTypes = [expenseType, incomeType];

  static const monthlyPeriod = 'MONTHLY';
  static const customPeriod = 'CUSTOM';
  static const budgetPeriods = [monthlyPeriod, customPeriod];

  /// Warning starts at this percentage used. Exceeded starts above 100.
  static const warningThreshold = 80;

  static const iconCatalogue = [
    'restaurant',
    'directions_car',
    'home',
    'medical_services',
    'shopping_bag',
    'movie',
    'school',
    'receipt_long',
    'category',
    'payments',
    'work',
    'card_giftcard',
    'savings',
    'pets',
    'flight',
    'fitness_center',
    'child_care',
    'phone_iphone',
    'local_cafe',
    'more_horiz',
  ];

  /// Inserted as ordinary category rows when a profile is created.
  static const predefinedCategories = [
    PredefinedCategory(name: 'Food', type: expenseType, icon: 'restaurant'),
    PredefinedCategory(
      name: 'Transport',
      type: expenseType,
      icon: 'directions_car',
    ),
    PredefinedCategory(name: 'Housing', type: expenseType, icon: 'home'),
    PredefinedCategory(
      name: 'Health',
      type: expenseType,
      icon: 'medical_services',
    ),
    PredefinedCategory(
      name: 'Shopping',
      type: expenseType,
      icon: 'shopping_bag',
    ),
    PredefinedCategory(name: 'Leisure', type: expenseType, icon: 'movie'),
    PredefinedCategory(name: 'Education', type: expenseType, icon: 'school'),
    PredefinedCategory(name: 'Bills', type: expenseType, icon: 'receipt_long'),
    PredefinedCategory(
      name: 'Other expense',
      type: expenseType,
      icon: 'category',
    ),
    PredefinedCategory(name: 'Salary', type: incomeType, icon: 'payments'),
    PredefinedCategory(name: 'Freelance', type: incomeType, icon: 'work'),
    PredefinedCategory(name: 'Gifts', type: incomeType, icon: 'card_giftcard'),
    PredefinedCategory(name: 'Other income', type: incomeType, icon: 'savings'),
  ];
}

class PredefinedCategory {
  const PredefinedCategory({
    required this.name,
    required this.type,
    required this.icon,
  });

  final String name;
  final String type;
  final String icon;
}
