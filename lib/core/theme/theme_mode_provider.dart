import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Where the theme choice lives. A file, so the SQLite schema stays at v1.
final themeFileProvider = Provider<Future<File>>((ref) async {
  final directory = await getApplicationDocumentsDirectory();
  return File(p.join(directory.path, 'theme_mode.txt'));
});

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

/// Dark by default, as the design system ships. Light only when saved.
class ThemeModeController extends Notifier<ThemeMode> {
  var _chosen = false;

  @override
  ThemeMode build() {
    _load();
    return ThemeMode.dark;
  }

  Future<void> _load() async {
    try {
      final file = await ref.read(themeFileProvider);
      if (!_chosen &&
          await file.exists() &&
          await file.readAsString() == 'light') {
        state = ThemeMode.light;
      }
    } catch (_) {
      // Unreadable preference: keep the dark default.
    }
  }

  Future<void> select(ThemeMode mode) async {
    _chosen = true;
    state = mode;
    try {
      await (await ref.read(themeFileProvider)).writeAsString(mode.name);
    } catch (_) {
      // The choice still applies for this session; only the restore is lost.
    }
  }
}
