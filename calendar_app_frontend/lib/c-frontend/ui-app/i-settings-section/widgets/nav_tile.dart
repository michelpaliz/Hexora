// lib/c-frontend/i-settings-section/widgets/nav_tile.dart
import 'package:flutter/material.dart';

class NavTile extends StatelessWidget {
  const NavTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.onTap,
    this.danger = false,
    this.iconBgColor,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool danger;

  /// Background color for the icon container. Defaults to a neutral tint.
  final Color? iconBgColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bodyM = theme.textTheme.bodyMedium!;
    final bodyS = theme.textTheme.bodySmall!;

    final effectiveBg = iconBgColor ??
        (danger
            ? cs.errorContainer.withValues(alpha: 0.35)
            : cs.surfaceContainerHighest.withValues(alpha: 0.6));

    final titleStyle = bodyM.copyWith(
      fontWeight: FontWeight.w600,
      color: danger ? cs.error : cs.onSurface,
    );

    final subtitleStyle = bodyS.copyWith(
      color: danger ? cs.error.withValues(alpha: 0.75) : cs.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );

    return InkWell(
      onTap: onTap,
      mouseCursor:
          onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(14),
      hoverColor: (danger ? cs.error : cs.primary).withValues(alpha: 0.045),
      splashColor: (danger ? cs.error : cs.primary).withValues(alpha: 0.08),
      highlightColor: (danger ? cs.error : cs.primary).withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: effectiveBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: leading),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: titleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: subtitleStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
