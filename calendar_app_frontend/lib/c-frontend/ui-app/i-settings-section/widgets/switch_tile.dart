// lib/c-frontend/i-settings-section/widgets/switch_tile.dart
import 'package:flutter/material.dart';

class SwitchTile extends StatelessWidget {
  const SwitchTile({
    super.key,
    required this.leading,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
    this.iconBgColor,
  });

  final Widget leading;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;
  final bool enabled;

  /// Background color for the icon container. Defaults to a neutral tint.
  final Color? iconBgColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bodyM = theme.textTheme.bodyMedium!;
    final bodyS = theme.textTheme.bodySmall!;

    final effectiveBg =
        iconBgColor ?? cs.surfaceContainerHighest.withValues(alpha: 0.6);

    return InkWell(
      onTap: enabled ? () => onChanged(!value) : null,
      mouseCursor:
          enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      borderRadius: BorderRadius.circular(14),
      hoverColor: cs.primary.withValues(alpha: enabled ? 0.045 : 0),
      splashColor: cs.primary.withValues(alpha: enabled ? 0.08 : 0),
      highlightColor: cs.primary.withValues(alpha: enabled ? 0.04 : 0),
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
                    style: bodyM.copyWith(
                      fontWeight: FontWeight.w600,
                      color: enabled
                          ? cs.onSurface
                          : cs.onSurface.withValues(alpha: 0.4),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: bodyS.copyWith(
                        color: cs.onSurfaceVariant.withValues(
                          alpha: enabled ? 1.0 : 0.5,
                        ),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch.adaptive(
              value: value,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }
}
