/// Local ISO-8601 text used in every table.
/// Dates are `YYYY-MM-DD`. Timestamps are `YYYY-MM-DDTHH:MM:SS`.
abstract final class IsoTime {
  static DateTime now() => DateTime.now();

  static String date(DateTime value) {
    final local = value.toLocal();
    final month = _two(local.month);
    final day = _two(local.day);
    return '${local.year}-$month-$day';
  }

  static String timestamp(DateTime value) {
    final local = value.toLocal();
    final hour = _two(local.hour);
    final minute = _two(local.minute);
    final second = _two(local.second);
    return '${date(local)}T$hour:$minute:$second';
  }

  static DateTime? tryParseDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      return null;
    }
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
