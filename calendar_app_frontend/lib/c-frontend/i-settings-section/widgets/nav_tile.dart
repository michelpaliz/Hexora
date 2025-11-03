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
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bodyM = theme.textTheme.bodyMedium!;
    final bodyS = theme.textTheme.bodySmall!;

    final titleStyle = bodyM.copyWith(
      fontWeight: FontWeight.w700,
      color: danger ? cs.error : cs.onSurface,
    );

    final subtitleStyle = bodyS.copyWith(
      color: danger ? cs.error : cs.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title (bodyMedium)
                  Text(title,
                      style: titleStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    // Subtitle (bodySmall)
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
            Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
