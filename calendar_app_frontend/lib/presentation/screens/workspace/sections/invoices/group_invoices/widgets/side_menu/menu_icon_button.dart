import 'package:hexora/presentation/shared/widgets/sidebar_item.dart';
import 'package:flutter/material.dart';

class GroupInvoicesMenuIconButton extends StatelessWidget {
  const GroupInvoicesMenuIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SidebarItem(
      icon: icon,
      label: label,
      isSelected: selected,
      collapsed: true,
      onTap: onPressed,
      primaryAction: true);
}
