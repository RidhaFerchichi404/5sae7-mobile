import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../domain/category_validation.dart';

/// Icon search and SVGs from the Iconify public API (free, no key).
/// Searches only Apache/MIT sets, see [iconifyPrefixes].
class IconifyClient {
  IconifyClient(this._api);

  final ApiClient _api;

  Future<List<String>> search(String query) async {
    final text = query.trim().toLowerCase();
    if (text.isEmpty) {
      return const [];
    }
    final body = await _api.getText(
      Uri.https('api.iconify.design', '/search', {
        'query': text,
        'limit': '64',
        'prefixes': iconifyPrefixes.join(','),
      }),
      cacheKey: 'iconify_search_$text.json',
      maxAge: const Duration(days: 7),
    );
    if (body == null) {
      return const [];
    }
    try {
      final icons = (jsonDecode(body) as Map<String, dynamic>)['icons'];
      return [
        for (final icon in icons as List)
          if (icon is String && isIconifyKey(icon)) icon,
      ];
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }

  /// Icons never change, so once fetched the SVG is kept for good.
  Future<String?> svg(String key) async {
    if (!isIconifyKey(key)) {
      return null;
    }
    final split = key.indexOf(':');
    final body = await _api.getText(
      Uri.https(
        'api.iconify.design',
        '/${key.substring(0, split)}/${key.substring(split + 1)}.svg',
      ),
      cacheKey: 'iconify_$key.svg',
      maxAge: const Duration(days: 3650),
    );
    return body != null && body.trimLeft().startsWith('<svg') ? body : null;
  }
}
