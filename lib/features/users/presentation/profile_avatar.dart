import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/user_profile.dart';

/// A DiceBear "shapes" avatar (CC0, free public API, no key). Falls back to
/// the profile's initial while loading or offline.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.user, this.size = 40});

  final UserProfile user;
  final double size;

  /// Seeded with id and creation time, never the name or email, so no
  /// personal data leaves the device. Same profile, same picture.
  static Uri url(UserProfile user, {int pixels = 128}) =>
      Uri.https('api.dicebear.com', '/9.x/shapes/png', {
        'seed': '${user.id}-${user.createdAt.millisecondsSinceEpoch}',
        'size': '$pixels',
      });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final initial = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: colors.secondary,
      child: Text(
        user.name.isEmpty ? '?' : user.name.characters.first.toUpperCase(),
        style: TextStyle(
          color: colors.ink,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.4,
        ),
      ),
    );
    // shortcut: Flutter's image cache is in memory only, so offline after a
    // restart shows the initial; add a disk cache if that matters.
    return Semantics(
      label: 'Avatar of ${user.name}',
      image: true,
      child: ClipOval(
        child: Image.network(
          url(user, pixels: (size * 3).round()).toString(),
          width: size,
          height: size,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : initial,
          errorBuilder: (context, error, stack) => initial,
        ),
      ),
    );
  }
}
