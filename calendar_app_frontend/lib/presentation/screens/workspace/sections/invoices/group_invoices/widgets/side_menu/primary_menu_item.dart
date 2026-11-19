import 'package:hexora/presentation/shared/widgets/sidebar_item.dart';
import 'package:flutter/material.dart';

class GroupInvoicesPrimaryMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const GroupInvoicesPrimaryMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => SidebarItem(
      icon: icon,
      label: label,
      isSelected: selected,
      collapsed: false,
      onTap: onPressed,
      primaryAction: true);
}
