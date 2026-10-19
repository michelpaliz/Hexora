import 'package:hexora/theme/themes/navigation_tokens.dart';
import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/sidebar_item.dart';

class GroupInvoicesSubMenuItem extends StatelessWidget {
  const GroupInvoicesSubMenuItem(
      {super.key,
      required this.icon,
      required this.label,
      required this.selected,
      required this.onPressed,
      this.count,
      this.primaryAction = false,
      this.indent = 0});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  final int? count;
  final bool primaryAction;
  final double indent;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsetsDirectional.only(
            start: indent, bottom: NavigationTokens.itemGap),
        child: SidebarItem(
            icon: icon,
            label: label,
            isSelected: selected,
            collapsed: false,
            onTap: onPressed,
            count: count,
            primaryAction: primaryAction),
      );
}
