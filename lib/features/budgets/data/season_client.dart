import 'dart:convert';

import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';

/// Days in a budget period when spending usually changes: Tunisian public
/// holidays (Nager.Date) and Ramadan and the Islamic holidays (AlAdhan).
/// Both APIs are free, keyless, and cached for a month.
class SeasonClient {
  SeasonClient(this._api);

  final ApiClient _api;

  static const _maxAge = Duration(days: 30);

  // Islamic public holidays in Tunisia, by Hijri (month, day).
  static const _islamic = {
    (1, 1): 'Islamic New Year',
    (3, 12): 'Mawlid',
    (10, 1): 'Eid al-Fitr',
    (12, 10): 'Eid al-Adha',
  };

  /// Short notes such as "Ramadan" or "Eid al-Fitr 20 Mar", in date order.
  Future<List<String>> notes(DateTime start, DateTime end) async {
    final first = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    bool within(DateTime day) => !day.isBefore(first) && !day.isAfter(last);

    final months = <DateTime>[];
    // shortcut: at most 12 months are checked, so a longer custom budget
    // only gets notes for its first year.
    for (
      var month = DateTime(first.year, first.month);
      !month.isAfter(last) && months.length < 12;
      month = DateTime(month.year, month.month + 1)
    ) {
      months.add(month);
    }

    final events = <DateTime, List<String>>{}; // Eid can share a civil day.
    var ramadan = false;
    for (final month in months) {
      for (final (day, hijriMonth, hijriDay) in await _hijri(month)) {
        if (!within(day)) {
          continue;
        }
        if (hijriMonth == 9) {
          ramadan = true;
        }
        final name = _islamic[(hijriMonth, hijriDay)];
        if (name != null) {
          (events[day] ??= []).add(name);
        }
      }
    }
    for (final year in {for (final month in months) month.year}) {
      for (final (day, name) in await _holidays(year)) {
        if (within(day)) {
          (events[day] ??= []).add(name);
        }
      }
    }

    final format = DateFormat('d MMM');
    final dates = events.keys.toList()..sort();
    return [
      if (ramadan) 'Ramadan',
      for (final day in dates)
        for (final name in events[day]!) '$name ${format.format(day)}',
    ];
  }

  // shortcut: Tunisia only, since the app targets Tunisia; map the
  // profile's country here if other countries are added.
  Future<List<(DateTime, String)>> _holidays(int year) async {
    final body = await _api.getText(
      Uri.https('date.nager.at', '/api/v3/PublicHolidays/$year/TN'),
      cacheKey: 'holidays_TN_$year.json',
      maxAge: _maxAge,
    );
    if (body == null) {
      return const [];
    }
    try {
      return [
        for (final item in jsonDecode(body) as List)
          if (DateTime.tryParse((item as Map)['date'] as String) case final d?)
            (d, item['name'] as String),
      ];
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }

  /// Each Gregorian day of [month] with its Hijri month and day.
  Future<List<(DateTime, int, int)>> _hijri(DateTime month) async {
    final body = await _api.getText(
      Uri.https(
        'api.aladhan.com',
        '/v1/gToHCalendar/${month.month}/${month.year}',
      ),
      cacheKey: 'hijri_${month.year}_${month.month}.json',
      maxAge: _maxAge,
    );
    if (body == null) {
      return const [];
    }
    try {
      final days = (jsonDecode(body) as Map<String, dynamic>)['data'] as List;
      return [
        for (final item in days)
          if (_gregorian((item as Map)['gregorian']['date'] as String)
              case final day?)
            (
              day,
              item['hijri']['month']['number'] as int,
              int.parse(item['hijri']['day'] as String),
            ),
      ];
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }

  /// AlAdhan writes dates as DD-MM-YYYY.
  static DateTime? _gregorian(String text) {
    final parts = text.split('-');
    if (parts.length != 3) {
      return null;
    }
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return null;
    }
    return DateTime(year, month, day);
  }
}
