import 'package:flutter/material.dart';
import 'package:hexora/theme/themes/navigation_tokens.dart';

/// Compact, shared heading for expanded secondary navigation sidebars.
class SecondarySidebarHeader extends StatelessWidget {
  const SecondarySidebarHeader({
    super.key,
    required this.title,
    required this.onCollapse,
    this.toggleKey,
    this.showCollapseAction = true,
  });

  final String title;
  final VoidCallback onCollapse;
  final Key? toggleKey;
  final bool showCollapseAction;

  @override
  Widget build(BuildContext context) {
    final colors = NavigationColors(Theme.of(context).colorScheme);
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';

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
                iconSize: 16,
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
