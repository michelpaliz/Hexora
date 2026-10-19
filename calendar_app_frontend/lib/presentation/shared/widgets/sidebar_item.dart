import 'package:flutter/material.dart';
import 'package:hexora/theme/themes/navigation_tokens.dart';

/// Shared navigation destination for expanded menus and collapsed rails.
class SidebarItem extends StatelessWidget {
  const SidebarItem(
      {super.key,
      required this.icon,
      required this.label,
      required this.isSelected,
      required this.collapsed,
      required this.onTap,
      this.textStyle,
      this.count,
      this.trailing,
      this.primaryAction = false});
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool collapsed;
  final VoidCallback? onTap;
  final TextStyle? textStyle;
  final int? count;
  final Widget? trailing;
  final bool primaryAction;

  @override
  Widget build(BuildContext context) {
    final colors = NavigationColors(Theme.of(context).colorScheme);
    final fg = onTap == null
        ? colors.disabled
        : isSelected
            ? colors.selectedForeground
            : colors.foreground;
    final style = (textStyle ?? NavigationTokens.label(context)).copyWith(
        fontSize: NavigationTokens.textSize,
        color: fg,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        letterSpacing: 0);
    final radius = BorderRadius.circular(NavigationTokens.radius);
    return Semantics(
        selected: isSelected,
        button: true,
        enabled: onTap != null,
        label: collapsed ? label : null,
        child: Tooltip(
            message: label,
            child: Material(
                color: isSelected
                    ? colors.selectedBackground
                    : primaryAction
                        ? colors.hover
                        : Colors.transparent,
                borderRadius: radius,
                child: InkWell(
                    onTap: onTap,
                    borderRadius: radius,
                    overlayColor:
                        WidgetStateProperty.resolveWith(colors.overlay),
                    child: Stack(children: [
                      if (isSelected)
                        PositionedDirectional(
                            start: 0,
                            top: 8,
                            bottom: 8,
                            child: Container(
                                width: NavigationTokens.indicatorWidth,
                                decoration: BoxDecoration(
                                    color: colors.indicator,
                                    borderRadius: radius))),
                      ConstrainedBox(
                          constraints: BoxConstraints(
                              minHeight: NavigationTokens.rowHeight(context)),
                          child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: collapsed
                                      ? 8
                                      : NavigationTokens.itemPadding,
                                  vertical: 8),
                              child: Row(
                                  mainAxisAlignment: collapsed
                                      ? MainAxisAlignment.center
                                      : MainAxisAlignment.start,
                                  children: [
                                    Icon(icon,
                                        size: NavigationTokens.iconSize,
                                        color: fg),
                                    if (!collapsed) ...[
                                      const SizedBox(
                                          width: NavigationTokens.itemPadding),
                                      Expanded(
                                          child: Text(label,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: style)),
                                      if (count != null) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                                color:
                                                    fg.withValues(alpha: .12),
                                                borderRadius: radius),
                                            child: Text('$count',
                                                style: style.copyWith(
                                                    fontSize: NavigationTokens
                                                        .sectionSize)))
                                      ],
                                      if (trailing != null) ...[
                                        const SizedBox(width: 6),
                                        trailing!
                                      ],
                                    ],
                                  ]))),
                    ])))));
  }
}
