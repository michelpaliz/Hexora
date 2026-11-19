import 'package:flutter/material.dart';

import 'package:hexora/presentation/shared/widgets/avatars/avatar_utils.dart';

/// Avatar for a conversation channel in the chat inbox.
///
/// Shows the channel's image when one is available, otherwise a type icon on a
/// subtle tinted background. Defaults to a rounded square (desktop list); pass
/// [circular] for the modern circular mobile style.
class ChannelAvatar extends StatelessWidget {
  const ChannelAvatar({
    super.key,
    required this.icon,
    this.muted = false,
    this.size = 40,
    this.circular = false,
    this.imageUrl,
    this.navySurface = false,
  });

  final IconData icon;
  final bool muted;
  final double size;
  final bool circular;
  final String? imageUrl;
  final bool navySurface;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      final avatar =
          AvatarUtils.groupAvatar(context, imageUrl, radius: size / 2);
      return circular
          ? avatar
          : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(width: size, height: size, child: avatar),
            );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: muted
            ? (navySurface
                ? Colors.white.withValues(alpha: .10)
                : cs.surfaceContainerHighest)
            : (navySurface
                ? cs.primary.withValues(alpha: .24)
                : cs.primaryContainer.withValues(alpha: .55)),
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circular ? null : BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: muted
            ? (navySurface ? const Color(0xFFB8C7DB) : cs.onSurfaceVariant)
            : (navySurface ? const Color(0xFF93C5FD) : cs.primary),
      ),
    );
  }
}
