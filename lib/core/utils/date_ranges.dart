/// Calendar helpers shared by budgets and the dashboard.
abstract final class DateRanges {
  static ({DateTime start, DateTime end}) monthBounds(DateTime day) {
    final start = DateTime(day.year, day.month, 1);
    final end = DateTime(day.year, day.month + 1, 0);
    return (start: start, end: end);
  }

  /// Inclusive ranges overlap when their endpoints touch.
  static bool overlaps({
    required DateTime startA,
    required DateTime endA,
    required DateTime startB,
    required DateTime endB,
  }) {
    final a0 = _day(startA);
    final a1 = _day(endA);
    final b0 = _day(startB);
    final b1 = _day(endB);
    return !a1.isBefore(b0) && !b1.isBefore(a0);
  }

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
