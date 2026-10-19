import 'package:hexora/presentation/shared/widgets/navigation_menu_header.dart';
import 'package:hexora/theme/themes/navigation_theme.dart';
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
  });

  static const double expandedWidth = NavigationTokens.sidebarWidth;
  static const double collapsedWidth = NavigationTokens.railWidth;
  static const double responsiveBreakpoint = NavigationTokens.mobileBreakpoint;
  static const Duration animationDuration = Duration(milliseconds: 180);

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

  @override
  Widget build(BuildContext context) =>
      NavigationSurface(builder: _buildNavigation);

  Widget _buildNavigation(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isCollapsed = collapsed && !drawer;
    final width = drawer
        ? double.infinity
        : isCollapsed
            ? collapsedWidth
            : expandedWidth;

    return AnimatedContainer(
      key: const ValueKey('collapsible-sidebar'),
      duration: animationDuration,
      curve: Curves.easeOutCubic,
      width: width,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.zero,
        border: Border(
          right: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Keep compact children until the animated rail is wide enough for
          // expanded content. This prevents a one-frame flex overflow while
          // expanding from the 64 px state.
          final layoutCollapsed =
              !drawer && constraints.maxWidth < expandedWidth * 0.56;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NavigationMenuHeader(
                title: title,
                icon: headerIcon,
                collapsed: layoutCollapsed,
                onToggle: drawer ? null : onToggleCollapsed,
                toggleKey: const ValueKey('collapsible-sidebar-toggle'),
                expandTooltip: expandTooltip,
                collapseTooltip: collapseTooltip,
              ),
              Divider(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: 0.45),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
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
                      const SizedBox(height: 8),
                      Divider(
                        height: 1,
                        color: cs.outlineVariant.withValues(alpha: 0.45),
                      ),
                      const SizedBox(height: 8),
                      for (final item in secondaryItems)
                        _entry(item, layoutCollapsed),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _entry(CollapsibleSidebarItem item, bool isCollapsed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
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
