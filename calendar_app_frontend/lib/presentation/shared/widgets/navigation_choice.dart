import 'package:flutter/material.dart';
import 'package:hexora/theme/themes/navigation_tokens.dart';

/// Content-sized destination for horizontal and mobile navigation.
class NavigationChoice extends StatelessWidget {
  const NavigationChoice(
      {super.key,
      required this.label,
      required this.selected,
      required this.onTap,
      this.icon});
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = NavigationColors(Theme.of(context).colorScheme);
    final fg = onTap == null
        ? colors.disabled
        : selected
            ? colors.selectedForeground
            : colors.foreground;
    final radius = BorderRadius.circular(NavigationTokens.radius);
    return Semantics(
        button: true,
        selected: selected,
        enabled: onTap != null,
        child: Material(
            color: selected ? colors.selectedBackground : Colors.transparent,
            borderRadius: radius,
            child: InkWell(
                onTap: onTap,
                borderRadius: radius,
                overlayColor: WidgetStateProperty.resolveWith(colors.overlay),
                child: Container(
                    constraints: BoxConstraints(
                        minHeight: NavigationTokens.rowHeight(context)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: NavigationTokens.itemPadding, vertical: 8),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                width: NavigationTokens.indicatorWidth,
                                color: selected
                                    ? colors.indicator
                                    : Colors.transparent))),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (icon != null) ...[
                            Icon(icon,
                                size: NavigationTokens.iconSize, color: fg),
                            const SizedBox(width: 8)
                          ],
                          Text(label,
                              style: NavigationTokens.label(context,
                                      selected: selected)
                                  .copyWith(color: fg))
                        ])))));
  }
}
