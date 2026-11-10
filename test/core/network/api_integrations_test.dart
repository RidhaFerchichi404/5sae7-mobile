import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mybudget/core/network/api_client.dart';
import 'package:mybudget/features/budgets/data/season_client.dart';
import 'package:mybudget/features/categories/data/iconify_client.dart';
import 'package:mybudget/features/categories/domain/category_validation.dart';
import 'package:mybudget/features/transactions/data/exchange_rate_client.dart';

/// An [ApiClient] without a disk cache, answering from [routes] by host.
ApiClient _api(Map<String, String Function(Uri)> routes) {
  return ApiClient(
    MockClient((request) async {
      final route = routes[request.url.host];
      return route == null
          ? http.Response('nope', 500)
          : http.Response.bytes(utf8.encode(route(request.url)), 200);
    }),
    () async => null,
  );
}

void main() {
  test('a failed request without a cache gives null, never throws', () async {
    final api = _api({});
    expect(
      await api.getText(
        Uri.https('example.com', '/'),
        cacheKey: 'x',
        maxAge: Duration.zero,
      ),
      isNull,
    );
  });

  group('exchange rates', () {
    test('reads the target currency from the base currency rates', () async {
      final client = ExchangeRateClient(
        _api({
          'open.er-api.com': (url) {
            expect(url.path, '/v6/latest/EUR');
            return jsonEncode({
              'result': 'success',
              'rates': {'TND': 3.358, 'USD': 1.08},
            });
          },
        }),
      );
      expect(await client.rate('EUR', 'TND'), 3.358);
      expect(await client.rate('TND', 'TND'), 1);
    });

    test('an error answer or offline gives null', () async {
      final error = ExchangeRateClient(
        _api({
          'open.er-api.com': (_) => jsonEncode({'result': 'error'}),
        }),
      );
      expect(await error.rate('EUR', 'TND'), isNull);
      expect(await ExchangeRateClient(_api({})).rate('EUR', 'TND'), isNull);
    });
  });

  group('iconify', () {
    test('keys are limited to the licensed sets and safe names', () {
      expect(isIconifyKey('mdi:coffee'), isTrue);
      expect(isIconifyKey('tabler:shopping-cart'), isTrue);
      expect(isIconifyKey('game-icons:coffee'), isFalse);
      expect(isIconifyKey('mdi:../secret'), isFalse);
      expect(isIconifyKey('coffee'), isFalse);
    });

    test('the form accepts a searched icon and still refuses junk', () {
      expect(
        validateCategoryInput(
          const CategoryInput(name: 'Coffee', icon: 'mdi:coffee'),
        ).iconError,
        isNull,
      );
      expect(
        validateCategoryInput(
          const CategoryInput(name: 'Coffee', icon: 'evil:coffee'),
        ).iconError,
        isNotNull,
      );
    });

    test('search drops other sets; svg needs an svg answer', () async {
      final client = IconifyClient(
        _api({
          'api.iconify.design': (url) => url.path == '/search'
              ? jsonEncode({
                  'icons': ['mdi:coffee', 'game-icons:coffee', 'tabler:mug'],
                })
              : '<svg viewBox="0 0 24 24"></svg>',
        }),
      );
      expect(await client.search('coffee'), ['mdi:coffee', 'tabler:mug']);
      expect(await client.search('  '), isEmpty);
      expect(await client.svg('mdi:coffee'), startsWith('<svg'));
      expect(await client.svg('evil:coffee'), isNull);
    });
  });

  test('season notes list Ramadan, Eid and civil holidays in order', () async {
    // March 2026: Ramadan until the 19th, Eid al-Fitr and Independence Day
    // both on the 20th.
    final days = [
      for (var day = 1; day <= 31; day++)
        {
          'gregorian': {'date': '${'$day'.padLeft(2, '0')}-03-2026'},
          'hijri': {
            'day': day < 20 ? '${day + 11}' : '${day - 19}',
            'month': {'number': day < 20 ? 9 : 10},
          },
        },
    ];
    final client = SeasonClient(
      _api({
        'api.aladhan.com': (_) => jsonEncode({'data': days}),
        'date.nager.at': (_) => jsonEncode([
          {'date': '2026-01-01', 'name': "New Year's Day"},
          {'date': '2026-03-20', 'name': 'Independence Day'},
        ]),
      }),
    );

    expect(await client.notes(DateTime(2026, 3, 1), DateTime(2026, 3, 31)), [
      'Ramadan',
      'Eid al-Fitr 20 Mar',
      'Independence Day 20 Mar',
    ]);
    expect(
      await client.notes(DateTime(2026, 3, 25), DateTime(2026, 3, 31)),
      isEmpty,
    );
    expect(
      await SeasonClient(
        _api({}),
      ).notes(DateTime(2026, 3, 1), DateTime(2026, 3, 31)),
      isEmpty,
    );
  });
}
