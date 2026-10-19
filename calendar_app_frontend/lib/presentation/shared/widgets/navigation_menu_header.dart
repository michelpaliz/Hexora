import 'package:flutter/material.dart';
import 'package:hexora/navigation/shell/hexora_nav_components.dart';
import 'package:hexora/theme/themes/navigation_tokens.dart';

class NavigationMenuHeader extends StatelessWidget {
  const NavigationMenuHeader(
      {super.key,
      required this.title,
      required this.icon,
      this.collapsed = false,
      this.onToggle,
      this.toggleKey,
      this.expandTooltip,
      this.collapseTooltip});
  final String title;
  final IconData icon;
  final bool collapsed;
  final VoidCallback? onToggle;
  final Key? toggleKey;
  final String? expandTooltip;
  final String? collapseTooltip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: collapsed ? 7 : NavigationTokens.outerPadding,
          vertical: 12),
      child: Row(children: [
        if (!collapsed) ...[
          Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon,
                  size: NavigationTokens.iconSize,
                  color: cs.onPrimaryContainer)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NavigationTokens.title(context).copyWith(
                      fontSize: NavigationTokens.titleSize,
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600))),
        ],
        if (onToggle != null)
          SidebarCollapseToggle(
            key: toggleKey,
            collapsed: collapsed,
            onPressed: onToggle,
            expandTooltip: expandTooltip,
            collapseTooltip: collapseTooltip,
          ),
      ]),
    );
  }
}
