class Category {
  const Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.icon,
    required this.createdAt,
  });

  final int id;
  final int userId;
  final String name;
  final String type;
  final String icon;
  final DateTime createdAt;

  bool get isExpense => type == 'EXPENSE';
  bool get isIncome => type == 'INCOME';
}
