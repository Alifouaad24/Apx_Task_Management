import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Circular avatar with a graceful fallback chain:
/// remote image → coloured initials → generic person icon.
///
/// The initials background is derived from the name, so the same person keeps
/// the same colour everywhere in the app.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size,
    this.showBorder = false,
  });

  final String name;
  final String? imageUrl;
  final double? size;
  final bool showBorder;

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dimension = size ?? 36.w;
    final background = AppColors.avatarColor(name, isDark: isDark);

    return Container(
      height: dimension,
      width: dimension,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background,
        border: showBorder
            ? Border.all(color: Theme.of(context).colorScheme.surface, width: 2)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: (imageUrl != null && imageUrl!.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => _Initials(
                initials: _initials,
                dimension: dimension,
              ),
              errorWidget: (_, __, ___) => _Initials(
                initials: _initials,
                dimension: dimension,
              ),
            )
          : _Initials(initials: _initials, dimension: dimension),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials, required this.dimension});

  final String initials;
  final double dimension;

  @override
  Widget build(BuildContext context) {
    if (initials.isEmpty) {
      return Icon(
        Icons.person_rounded,
        size: dimension * 0.55,
        color: Colors.white,
      );
    }
    return Center(
      child: Text(
        initials,
        style: AppTextStyles.labelMedium.copyWith(
          color: Colors.white,
          fontSize: (dimension * 0.38).sp / 1, // scales with the avatar
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Overlapping avatar stack, used on the task card when several people are
/// involved (assignee + reporter).
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    super.key,
    required this.people,
    this.size,
    this.maxVisible = 3,
  });

  /// `(name, imageUrl)` pairs.
  final List<({String name, String? imageUrl})> people;
  final double? size;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final dimension = size ?? 26.w;
    final visible = people.take(maxVisible).toList();
    final overflow = people.length - visible.length;

    return SizedBox(
      height: dimension,
      width: dimension + (visible.length - 1).clamp(0, maxVisible) * dimension * 0.65 +
          (overflow > 0 ? dimension * 0.65 : 0),
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * dimension * 0.65,
              child: UserAvatar(
                name: visible[i].name,
                imageUrl: visible[i].imageUrl,
                size: dimension,
                showBorder: true,
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: visible.length * dimension * 0.65,
              child: Container(
                height: dimension,
                width: dimension,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '+$overflow',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
