enum TransactionSortField { date, amount, categoryName }

class TransactionQuery {
  const TransactionQuery({
    required this.userId,
    this.search,
    this.type,
    this.categoryId,
    this.from,
    this.to,
    this.sortField = TransactionSortField.date,
    this.ascending = false,
  });

  final int userId;
  final String? search;
  final String? type;
  final int? categoryId;
  final DateTime? from;
  final DateTime? to;
  final TransactionSortField sortField;
  final bool ascending;

  @override
  bool operator ==(Object other) {
    return other is TransactionQuery &&
        other.userId == userId &&
        other.search == search &&
        other.type == type &&
        other.categoryId == categoryId &&
        other.from == from &&
        other.to == to &&
        other.sortField == sortField &&
        other.ascending == ascending;
  }

  @override
  int get hashCode => Object.hash(
    userId,
    search,
    type,
    categoryId,
    from,
    to,
    sortField,
    ascending,
  );
}
