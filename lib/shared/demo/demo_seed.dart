import 'dart:math';

import '../../core/constants/app_constants.dart';
import '../../core/utils/date_ranges.dart';
import '../../core/utils/iso_time.dart';
import '../../features/budgets/data/budget_repository.dart';
import '../../features/budgets/domain/budget_validation.dart';
import '../../features/categories/data/category_repository.dart';
import '../../features/categories/domain/category.dart';
import '../../features/transactions/data/transaction_repository.dart';
import '../../features/transactions/domain/transaction_query.dart';
import '../../features/transactions/domain/transaction_validation.dart';
import '../../features/users/data/user_repository.dart';
import '../../features/users/domain/user_profile.dart';
import '../../features/users/domain/user_validation.dart';

/// Creates a demo profile with six months of believable TND activity and
/// budgets for the current month. Everything goes through the repositories,
/// so the forms' validation rejects any bad row. Same seed, same data.
class DemoSeed {
  DemoSeed({
    required this.users,
    required this.categories,
    required this.transactions,
    required this.budgets,
    DateTime? today,
  }) : today = today ?? DateTime.now();

  static const email = 'demo@mybudget.test';

  final UserRepository users;
  final CategoryRepository categories;
  final TransactionRepository transactions;
  final BudgetRepository budgets;
  final DateTime today;

  final _random = Random(42);

  Future<UserProfile> run() async {
    final user = await users.create(
      validateUserInput(
        const UserInput(name: 'Yasmine Haddad', email: email, currency: 'TND'),
      ),
    );
    await categories.seedDefaultCategories(user.id);
    final byName = {
      for (final c in await categories.list(userId: user.id)) c.name: c,
    };

    final firstMonth = DateTime(today.year, today.month - 5);
    for (var m = 0; m < 6; m++) {
      await _month(
        user.id,
        byName,
        DateTime(firstMonth.year, firstMonth.month + m),
      );
    }
    await _budgets(user.id, byName);
    return user;
  }

  Future<void> _month(
    int userId,
    Map<String, Category> c,
    DateTime month,
  ) async {
    final days = DateTime(month.year, month.month + 1, 0).day;

    // On the 1st of this month, so every budget has spending on any date.
    if (month.year == today.year && month.month == today.month) {
      await _add(userId, c['Food']!, 1, month, 4.5, 'Bakery');
      await _add(userId, c['Transport']!, 1, month, 9, 'Taxi');
      await _add(userId, c['Leisure']!, 1, month, 45, 'Concert tickets');
      await _add(userId, c['Shopping']!, 1, month, 35, 'Books');
      await _add(userId, c['Bills']!, 1, month, 10, 'Phone top-up');
    }

    // Fixed monthly lines.
    await _add(userId, c['Salary']!, 1, month, 2450, 'Salary');
    await _add(userId, c['Housing']!, 3, month, 750, 'Rent');
    await _add(userId, c['Bills']!, 5, month, 59, 'Internet (Topnet)');
    await _add(userId, c['Bills']!, 6, month, 30, 'Phone plan');
    await _add(userId, c['Leisure']!, 8, month, 33.5, 'Netflix');
    await _add(userId, c['Transport']!, 2, month, 25, 'Metro monthly pass');
    if (month.month.isEven) {
      await _add(
        userId,
        c['Bills']!,
        12,
        month,
        _between(70, 115),
        'STEG electricity',
      );
      await _add(
        userId,
        c['Bills']!,
        14,
        month,
        _between(22, 35),
        'SONEDE water',
      );
    }

    // Weekly groceries and fuel.
    const shops = ['Carrefour', 'Monoprix', 'Aziza', 'Magasin Général'];
    for (var day = 2; day <= days; day += 7) {
      await _add(
        userId,
        c['Food']!,
        day,
        month,
        _between(45, 130),
        'Groceries · ${shops[_random.nextInt(shops.length)]}',
      );
    }
    for (final day in [9, 23]) {
      await _add(userId, c['Transport']!, day, month, _between(50, 80), 'Fuel');
    }

    // Small everyday spending.
    for (var i = 0; i < 10; i++) {
      await _add(
        userId,
        c['Food']!,
        _day(days),
        month,
        _between(2.5, 9),
        'Café',
      );
    }
    for (var i = 0; i < 3; i++) {
      await _add(
        userId,
        c['Food']!,
        _day(days),
        month,
        _between(25, 75),
        'Restaurant',
      );
    }
    for (var i = 0; i < 4; i++) {
      await _add(
        userId,
        c['Transport']!,
        _day(days),
        month,
        _between(6, 18),
        'Taxi',
      );
    }

    // Occasional lines.
    if (_chance(0.7)) {
      await _add(
        userId,
        c['Shopping']!,
        _day(days),
        month,
        _between(40, 190),
        'Clothes',
      );
    }
    if (_chance(0.5)) {
      await _add(
        userId,
        c['Health']!,
        _day(days),
        month,
        _between(12, 48),
        'Pharmacy',
      );
    }
    if (_chance(0.2)) {
      await _add(userId, c['Health']!, _day(days), month, 60, 'Doctor visit');
    }
    if (_chance(0.6)) {
      await _add(
        userId,
        c['Leisure']!,
        _day(days),
        month,
        _between(12, 22),
        'Cinema',
      );
    }
    if (_chance(0.3)) {
      await _add(
        userId,
        c['Education']!,
        _day(days),
        month,
        _between(90, 160),
        'Online course',
      );
    }
    if (_chance(0.6)) {
      await _add(
        userId,
        c['Freelance']!,
        _day(days),
        month,
        _between(300, 650),
        'Freelance project',
      );
    }
    if (_chance(0.15)) {
      await _add(
        userId,
        c['Gifts']!,
        _day(days),
        month,
        _between(50, 200),
        'Gift',
      );
    }
  }

  /// Limits follow this month's real spending, so the demo always shows
  /// each state: [ratio] is the share of the limit already spent.
  Future<void> _budgets(int userId, Map<String, Category> c) async {
    final month = DateRanges.monthBounds(today);
    for (final (name, ratio) in [
      ('Food', 0.55), // normal
      ('Shopping', 0.4), // normal
      ('Transport', 0.88), // warning
      ('Bills', 0.92), // warning
      ('Leisure', 1.2), // exceeded
    ]) {
      final category = c[name]!;
      final rows = await transactions.search(
        TransactionQuery(
          userId: userId,
          categoryId: category.id,
          from: month.start,
          to: month.end,
        ),
      );
      final spent = rows.fold<double>(0, (sum, row) => sum + row.amount);
      // Whole dinars, rounded toward the side that keeps the intended state.
      final raw = spent / ratio;
      final limit = max(1, ratio > 1 ? raw.floor() : raw.ceil());
      await budgets.create(
        userId: userId,
        input: validateBudgetInput(
          BudgetInput(
            limitText: '$limit',
            currencyCode: 'TND',
            period: AppConstants.monthlyPeriod,
            startText: IsoTime.date(month.start),
            endText: IsoTime.date(month.end),
            category: category,
            userId: userId,
          ),
        ),
      );
    }
  }

  /// Skips lines that would land after [today], so nothing is in the future.
  Future<void> _add(
    int userId,
    Category category,
    int day,
    DateTime month,
    double amount,
    String description,
  ) async {
    final date = DateTime(month.year, month.month, day);
    if (date.isAfter(today)) {
      return;
    }
    await transactions.create(
      userId: userId,
      input: validateTransactionInput(
        TransactionInput(
          amountText: amount.toStringAsFixed(3),
          currencyCode: 'TND',
          type: category.type,
          category: category,
          userId: userId,
          dateText: IsoTime.date(date),
          description: description,
        ),
      ),
    );
  }

  /// Rounded to 0.500 like real receipts.
  double _between(double low, double high) =>
      ((low + _random.nextDouble() * (high - low)) * 2).round() / 2;

  int _day(int days) => 1 + _random.nextInt(days);

  bool _chance(double p) => _random.nextDouble() < p;
}
