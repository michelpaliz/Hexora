import 'package:flutter/material.dart';
import 'package:hexora/theme/colors/app_colors.dart';
import 'package:hexora/theme/themes/navigation_tokens.dart';
import 'package:hexora/theme/typography/hexora_design_tokens.dart';

/// Compact, shared heading for expanded secondary navigation sidebars.
class SecondarySidebarHeader extends StatelessWidget {
  const SecondarySidebarHeader({
    super.key,
    required this.title,
    required this.onCollapse,
    this.toggleKey,
    this.showCollapseAction = true,
    this.icon,
    this.emphasized = false,
  });

  final String title;
  final VoidCallback onCollapse;
  final Key? toggleKey;
  final bool showCollapseAction;
  final IconData? icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = NavigationColors(Theme.of(context).colorScheme);
    final colorScheme = Theme.of(context).colorScheme;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';

    if (emphasized) {
      final light = colorScheme.brightness == Brightness.light;
      return Padding(
        // The 48 px contextual slot mirrors the primary sidebar's top area.
        // A 10 px top inset places this 32 px surface on the same centerline
        // as the 38 px Compact control, leaving a compact 6 px content gap.
        padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 6),
        child: DecoratedBox(
          key: const ValueKey('secondary-module-header-surface'),
          decoration: BoxDecoration(
            color: light
                ? AppColors.inputBackground
                : Color.alphaBlend(
                    colorScheme.primary.withValues(alpha: 0.14),
                    colorScheme.surface,
                  ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Tooltip(
                    message: title,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: HexoraTypography.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Tooltip(
                message: title,
                child: Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NavigationTokens.section(context).copyWith(
                    color: colors.sectionForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (showCollapseAction) ...[
              const SizedBox(width: 6),
              IconButton(
                key: toggleKey,
                tooltip:
                    isSpanish ? 'Contraer barra lateral' : 'Collapse sidebar',
                onPressed: onCollapse,
                icon: const Icon(Icons.keyboard_double_arrow_left_rounded),
                iconSize: HexoraIconTokens.compact,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints:
                    const BoxConstraints.tightFor(width: 32, height: 32),
                color: colors.sectionForeground,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
