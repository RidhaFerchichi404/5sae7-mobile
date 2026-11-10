import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// GETs public, keyless APIs and keeps each answer in a file, so the app
/// still works offline with the last answer. Never throws: callers get
/// null and show their fallback.
class ApiClient {
  ApiClient(this._http, this._cacheDir);

  final http.Client _http;
  final Future<Directory?> Function() _cacheDir;

  static const _timeout = Duration(seconds: 8);

  /// A fresh cache (younger than [maxAge]) is used without a request.
  /// When the request fails, a stale cache is better than nothing.
  Future<String?> getText(
    Uri url, {
    required String cacheKey,
    required Duration maxAge,
  }) async {
    final file = await _file(cacheKey);
    try {
      if (file != null && await file.exists()) {
        final age = DateTime.now().difference(await file.lastModified());
        if (age < maxAge) {
          return await file.readAsString();
        }
      }
    } on FileSystemException {
      // Unreadable cache: fetch again.
    }
    try {
      final response = await _http.get(url).timeout(_timeout);
      if (response.statusCode == 200) {
        await file?.writeAsString(response.body);
        return response.body;
      }
    } catch (_) {
      // Offline, timeout or bad host: fall through to the stale cache.
    }
    try {
      if (file != null && await file.exists()) {
        return await file.readAsString();
      }
    } on FileSystemException {
      return null;
    }
    return null;
  }

  Future<File?> _file(String cacheKey) async {
    final directory = await _cacheDir();
    if (directory == null) {
      return null;
    }
    final safe = cacheKey.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return File(p.join(directory.path, safe));
  }
}

Future<Directory?> _defaultCacheDir() async {
  try {
    final base = await getApplicationCacheDirectory();
    return Directory(p.join(base.path, 'api')).create(recursive: true);
  } catch (_) {
    return null; // No platform channel, e.g. in tests: run without a cache.
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return ApiClient(client, _defaultCacheDir);
});
