import 'dart:convert';

import '../../../core/network/api_client.dart';

/// Daily rates from ExchangeRate-API's open endpoint (free, no key). Its
/// terms ask for the "Rates by exchangerate-api.com" credit where shown.
class ExchangeRateClient {
  ExchangeRateClient(this._api);

  final ApiClient _api;

  static const attribution = 'Rates by exchangerate-api.com';

  /// How many [to] one [from] is worth, or null when unknown.
  Future<double?> rate(String from, String to) async {
    if (from == to) {
      return 1;
    }
    final body = await _api.getText(
      Uri.https('open.er-api.com', '/v6/latest/$from'),
      cacheKey: 'rates_$from.json',
      maxAge: const Duration(hours: 12), // The source updates once a day.
    );
    if (body == null) {
      return null;
    }
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      if (json['result'] != 'success') {
        return null;
      }
      final value = (json['rates'] as Map<String, dynamic>)[to];
      return value is num && value > 0 ? value.toDouble() : null;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}
