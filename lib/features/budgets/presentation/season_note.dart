import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'budget_providers.dart';

/// "Includes Ramadan, Eid al-Fitr 20 Mar" under a budget. Shows nothing
/// while loading, offline without a cache, or when the period is ordinary.
class SeasonNote extends ConsumerWidget {
  const SeasonNote({super.key, required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(budgetSeasonProvider((start, end))).value;
    if (notes == null || notes.isEmpty) {
      return const SizedBox.shrink();
    }
    final muted = AppColors.of(context).muted;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.event_outlined, size: 16, color: muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Includes ${notes.join(', ')}',
              key: const Key('budget-season'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
        ],
      ),
    );
  }
}
