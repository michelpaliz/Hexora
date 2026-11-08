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
      this.subtitle,
      this.count,
      this.trailing,
      this.primaryAction = false,
      this.groupHeader = false,
      this.activeAncestor = false,
      this.rowHeight,
      this.iconSize});
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool collapsed;
  final VoidCallback? onTap;
  final TextStyle? textStyle;
  final String? subtitle;
  final int? count;
  final Widget? trailing;

  /// Creation action ("Crear factura"): neutral text with a subtle blue icon.
  final bool primaryAction;

  /// Toggle row of an expandable group ("Clientes", "Facturación").
  final bool groupHeader;

  /// Parent of the selected destination: keeps a soft fill without selection.
  final bool activeAncestor;
  final double? rowHeight;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = NavigationColors(Theme.of(context).colorScheme);
    final isCreateAction = primaryAction && !isSelected;
    final fg = onTap == null
        ? colors.disabled
        : isSelected
            ? colors.selectedForeground
            : groupHeader
                ? colors.groupForeground
                : isCreateAction
                    ? colors.createActionForeground
                    : colors.itemForeground;
    final iconColor =
        isCreateAction && onTap != null ? colors.createActionIcon : fg;
    final style = (textStyle ?? NavigationTokens.label(context)).copyWith(
        fontSize: groupHeader
            ? NavigationTokens.groupSize
            : isCreateAction
                ? NavigationTokens.createActionSize
                : NavigationTokens.textSize,
        color: fg,
        fontWeight:
            isSelected || groupHeader ? FontWeight.w600 : FontWeight.w500,
        letterSpacing: 0);
    final radius = BorderRadius.circular(NavigationTokens.radius);
    final selectionDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : NavigationTokens.motion;
    return Semantics(
        selected: isSelected,
        button: true,
        enabled: onTap != null,
        label: collapsed ? label : null,
        child: Tooltip(
            message: label,
            child: Material(
                animationDuration: selectionDuration,
                color: isSelected
                    ? colors.selectedBackground
                    : activeAncestor
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
                              minHeight: rowHeight ??
                                  NavigationTokens.rowHeight(context)),
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
                                        size: iconSize ??
                                            NavigationTokens.iconSize,
                                        color: iconColor),
                                    if (!collapsed) ...[
                                      const SizedBox(
                                        width: NavigationTokens.itemPadding,
                                      ),
                                      Expanded(
                                          child: subtitle == null
                                              ? Text(label,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: style)
                                              : Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                      Text(label,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: style),
                                                      const SizedBox(height: 2),
                                                      Text(subtitle!,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: NavigationTokens
                                                                  .label(
                                                                      context)
                                                              .copyWith(
                                                                  fontSize: 11,
                                                                  color: fg
                                                                      .withValues(
                                                                          alpha:
                                                                              .72),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400)),
                                                    ])),
                                      if (count != null) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                                color:
                                                    fg.withValues(alpha: .12),
                                                borderRadius: radius),
                                            child: Text('$count',
                                                style: style.copyWith(
                                                    fontSize: NavigationTokens
                                                        .countSize,
                                                    fontWeight:
                                                        FontWeight.w600)))
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
