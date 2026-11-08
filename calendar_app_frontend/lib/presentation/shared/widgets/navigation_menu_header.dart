import 'package:flutter/material.dart';

/// Slim header that hosts only the collapse control. The module title is
/// deliberately omitted: every module already names itself in the content
/// area and the global bar, so repeating it in each side menu was redundant.
/// [title] and [icon] are kept for call-site compatibility and accessibility.
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
    // SidebarEdgeShell owns the full-height notch and handle. This legacy
    // widget intentionally reserves no layout space.
    return const SizedBox.shrink();
  }
}
