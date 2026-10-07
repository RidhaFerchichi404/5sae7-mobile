class TransactionRecord {
  const TransactionRecord({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.type,
    required this.description,
    required this.transactionDate,
    required this.createdAt,
  });

  final int id;
  final int userId;
  final int categoryId;
  final double amount;
  final String type;
  final String? description;
  final DateTime transactionDate;
  final DateTime createdAt;

  bool get isExpense => type == 'EXPENSE';
}
