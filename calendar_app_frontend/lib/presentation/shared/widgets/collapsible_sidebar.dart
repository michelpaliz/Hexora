import 'package:hexora/presentation/shared/widgets/sidebar_edge_shell.dart';
import 'package:hexora/theme/themes/navigation_theme.dart';
import 'package:hexora/theme/motion/hexora_motion.dart';
import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/sidebar_item.dart';

/// Navigation entry rendered by [CollapsibleSidebar].
class CollapsibleSidebarItem {
  const CollapsibleSidebarItem({
    this.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.count,
  });

  final Key? key;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final int? count;
}

typedef CollapsibleSidebarBuilder = Widget Function(
  BuildContext context,
  bool collapsed,
);

/// Canonical width, theme, edge and collapse behavior for module sidebars.
/// Use this shell when a module needs custom sidebar content such as search.
class CollapsibleSidebarShell extends StatelessWidget {
  const CollapsibleSidebarShell({
    super.key,
    required this.title,
    required this.collapsed,
    required this.onToggleCollapsed,
    required this.builder,
    this.drawer = false,
    this.secondaryHeader = false,
    this.expandTooltip = 'Expand menu',
    this.collapseTooltip = 'Collapse menu',
  });

  final String title;
  final bool collapsed;
  final VoidCallback? onToggleCollapsed;
  final CollapsibleSidebarBuilder builder;
  final bool drawer;
  final bool secondaryHeader;
  final String expandTooltip;
  final String collapseTooltip;

  @override
  Widget build(BuildContext context) => Theme(
        data: navigationTheme(Theme.of(context)),
        child: Builder(
          builder: (navigationContext) {
            final width = drawer
                ? double.infinity
                : collapsed
                    ? CollapsibleSidebar.collapsedWidth
                    : CollapsibleSidebar.expandedWidth;
            return AnimatedContainer(
              key: const ValueKey('collapsible-sidebar'),
              duration: HexoraMotion.duration(context, HexoraMotion.layout),
              curve: HexoraMotion.emphasized,
              width: width,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final layoutCollapsed = !drawer &&
                      constraints.maxWidth <
                          CollapsibleSidebar.expandedWidth * 0.56;
                  final cs = Theme.of(context).colorScheme;
                  return SidebarEdgeShell(
                    collapsed: layoutCollapsed,
                    onToggle: drawer ? null : onToggleCollapsed,
                    showHandle: !drawer,
                    expandTooltip: expandTooltip,
                    collapseTooltip: collapseTooltip,
                    toggleKey: const ValueKey('collapsible-sidebar-toggle'),
                    headerTitle: secondaryHeader ? title : null,
                    collapseInHeader: secondaryHeader,
                    backgroundColor: cs.surface,
                    child: builder(context, layoutCollapsed),
                  );
                },
              ),
            );
          },
        ),
      );
}

/// Shared application-module navigation used by Maps, Mail, and other hubs.
///
/// The dimensions and motion here are the canonical values for module menus.
/// Set [drawer] when placing it in a mobile drawer or modal overlay; the menu
/// then fills the available width and does not show a collapse control.
class CollapsibleSidebar extends StatelessWidget {
  const CollapsibleSidebar({
    super.key,
    required this.title,
    required this.headerIcon,
    required this.collapsed,
    required this.onToggleCollapsed,
    required this.items,
    this.primaryAction,
    this.secondaryItems = const [],
    this.drawer = false,
    this.expandTooltip = 'Expand menu',
    this.collapseTooltip = 'Collapse menu',
    this.titleTextStyle,
    this.itemTextStyle,
    this.selectedItemTextStyle,
    this.secondaryHeader = false,
  });

  static const double expandedWidth = NavigationTokens.sidebarWidth;
  static const double collapsedWidth = NavigationTokens.railWidth;
  static const double responsiveBreakpoint = NavigationTokens.mobileBreakpoint;
  static const Duration animationDuration = NavigationTokens.motion;

  final String title;
  final IconData headerIcon;
  final bool collapsed;
  final VoidCallback onToggleCollapsed;
  final CollapsibleSidebarItem? primaryAction;
  final List<CollapsibleSidebarItem> items;
  final List<CollapsibleSidebarItem> secondaryItems;
  final bool drawer;
  final String expandTooltip;
  final String collapseTooltip;
  final TextStyle? titleTextStyle;
  final TextStyle? itemTextStyle;
  final TextStyle? selectedItemTextStyle;
  final bool secondaryHeader;

  @override
  Widget build(BuildContext context) => CollapsibleSidebarShell(
        title: title,
        collapsed: collapsed,
        onToggleCollapsed: onToggleCollapsed,
        drawer: drawer,
        secondaryHeader: secondaryHeader,
        expandTooltip: expandTooltip,
        collapseTooltip: collapseTooltip,
        builder: (context, layoutCollapsed) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                children: [
                  if (primaryAction != null) ...[
                    _primaryEntry(
                      context,
                      primaryAction!,
                      layoutCollapsed,
                    ),
                    const SizedBox(height: 8),
                  ],
                  for (final item in items) _entry(item, layoutCollapsed),
                  if (secondaryItems.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    for (final item in secondaryItems)
                      _entry(item, layoutCollapsed),
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  Widget _entry(CollapsibleSidebarItem item, bool isCollapsed) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: NavigationTokens.childGap / 2),
      child: SidebarItem(
        key: item.key,
        icon: item.icon,
        label: item.label,
        isSelected: item.selected,
        collapsed: isCollapsed,
        onTap: item.onTap,
        count: item.count,
        textStyle: item.selected
            ? selectedItemTextStyle ?? itemTextStyle
            : itemTextStyle,
      ),
    );
  }

  Widget _primaryEntry(
    BuildContext context,
    CollapsibleSidebarItem item,
    bool isCollapsed,
  ) {
    return SidebarItem(
        key: item.key,
        icon: item.icon,
        label: item.label,
        isSelected: item.selected,
        collapsed: isCollapsed,
        onTap: item.onTap,
        count: item.count,
        primaryAction: true);
  }
}
