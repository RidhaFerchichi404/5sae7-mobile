import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Destructive confirmation. Returns true only when the owner confirms.
Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Delete',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              confirmLabel,
              style: const TextStyle(color: AppColors.exceeded),
            ),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
