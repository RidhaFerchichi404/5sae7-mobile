abstract final class AppRoutes {
  static const profileGate = '/profile-gate';
  static const profile = '/profile';
  static const categories = '/categories';
  static const categoryForm = '/category-form';
  static const transactions = '/transactions';
  static const transactionForm = '/transaction-form';
  static const budgets = '/budgets';
  static const budgetForm = '/budget-form';
  static const dashboard = '/dashboard';
  static const statistics = '/statistics';

  static const all = [
    profileGate,
    profile,
    categories,
    categoryForm,
    transactions,
    transactionForm,
    budgets,
    budgetForm,
    dashboard,
    statistics,
  ];

  static String titleFor(String route) {
    return switch (route) {
      profileGate => 'Profile gate',
      profile => 'Profile',
      categories => 'Categories',
      categoryForm => 'Category form',
      transactions => 'Transactions',
      transactionForm => 'Transaction form',
      budgets => 'Budgets',
      budgetForm => 'Budget form',
      dashboard => 'Dashboard',
      statistics => 'Statistics',
      _ => 'MyBudget',
    };
  }
}
