import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../domain/category_validation.dart';
import 'category_providers.dart';

IconData iconForKey(String key) {
  return switch (key) {
    'restaurant' => Icons.restaurant,
    'directions_car' => Icons.directions_car,
    'home' => Icons.home,
    'medical_services' => Icons.medical_services,
    'shopping_bag' => Icons.shopping_bag,
    'movie' => Icons.movie,
    'school' => Icons.school,
    'receipt_long' => Icons.receipt_long,
    'category' => Icons.category,
    'payments' => Icons.payments,
    'work' => Icons.work,
    'card_giftcard' => Icons.card_giftcard,
    'savings' => Icons.savings,
    'pets' => Icons.pets,
    'flight' => Icons.flight,
    'fitness_center' => Icons.fitness_center,
    'child_care' => Icons.child_care,
    'phone_iphone' => Icons.phone_iphone,
    'local_cafe' => Icons.local_cafe,
    'more_horiz' => Icons.more_horiz,
    _ => Icons.category,
  };
}

/// Draws a catalogue icon, or an Iconify icon (`prefix:name`) from its
/// cached SVG. Shows the generic category icon until the SVG is there.
class CategoryIcon extends ConsumerWidget {
  const CategoryIcon(this.iconKey, {super.key, this.color, this.size = 24});

  final String iconKey;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tint = color ?? IconTheme.of(context).color;
    final fallback = Icon(iconForKey(iconKey), color: color, size: size);
    if (!isIconifyKey(iconKey)) {
      return fallback;
    }
    final svg = ref.watch(iconSvgProvider(iconKey)).value;
    if (svg == null) {
      return fallback;
    }
    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      colorFilter: tint == null
          ? null
          : ColorFilter.mode(tint, BlendMode.srcIn),
    );
  }
}
