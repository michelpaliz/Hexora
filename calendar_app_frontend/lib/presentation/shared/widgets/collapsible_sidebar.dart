import 'package:hexora/presentation/shared/widgets/sidebar_edge_shell.dart';
import 'package:hexora/models/user/user_preferences.dart';
import 'package:hexora/state/user_preferences_provider.dart';
import 'package:hexora/theme/themes/navigation_theme.dart';
import 'package:hexora/theme/motion/hexora_motion.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class CollapsibleSidebarGroup {
  const CollapsibleSidebarGroup({required this.label, required this.items});

  final String label;
  final List<CollapsibleSidebarItem> items;
}

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
    this.expandedWidth = CollapsibleSidebar.expandedWidth,
    this.collapsedWidth = CollapsibleSidebar.collapsedWidth,
    this.collapsedToggleInRail = false,
    this.expandTooltip = 'Expand menu',
    this.collapseTooltip = 'Collapse menu',
  });

  final String title;
  final bool collapsed;
  final VoidCallback? onToggleCollapsed;
  final CollapsibleSidebarBuilder builder;
  final bool drawer;
  final bool secondaryHeader;
  final double expandedWidth;
  final double collapsedWidth;
  final bool collapsedToggleInRail;
  final String expandTooltip;
  final String collapseTooltip;

  @override
  Widget build(BuildContext context) => Theme(
        data: navigationTheme(Theme.of(context)),
        child: Builder(
          builder: (navigationContext) {
            UserPreferencesProvider? preferences;
            try {
              preferences = navigationContext.watch<UserPreferencesProvider>();
            } on ProviderNotFoundException {
              // Standalone sidebars (including focused widget tests) do not
              // always provide workspace preferences.
            }
            final forceIconsOnly = !drawer &&
                preferences?.navigationDisplayMode ==
                    NavigationDisplayMode.iconsOnly;
            final effectiveCollapsed = collapsed || forceIconsOnly;
            final width = drawer
                ? double.infinity
                : effectiveCollapsed
                    ? collapsedWidth
                    : expandedWidth;
            return AnimatedContainer(
              key: const ValueKey('collapsible-sidebar'),
              duration: HexoraMotion.duration(context, HexoraMotion.layout),
              curve: HexoraMotion.emphasized,
              width: width,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final layoutCollapsed =
                      !drawer && constraints.maxWidth < expandedWidth * 0.56;
                  final cs = Theme.of(context).colorScheme;
                  return SidebarEdgeShell(
                    collapsed: layoutCollapsed,
                    onToggle:
                        drawer || forceIconsOnly ? null : onToggleCollapsed,
                    showHandle:
                        !drawer && !collapsedToggleInRail && !forceIconsOnly,
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
    this.groups = const [],
    this.topContent,
    this.drawer = false,
    this.expandTooltip = 'Expand menu',
    this.collapseTooltip = 'Collapse menu',
    this.titleTextStyle,
    this.itemTextStyle,
    this.selectedItemTextStyle,
    this.secondaryHeader = false,
    this.menuExpandedWidth = CollapsibleSidebar.expandedWidth,
    this.menuCollapsedWidth = CollapsibleSidebar.collapsedWidth,
    this.collapsedToggleInRail = false,
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
  final List<CollapsibleSidebarGroup> groups;
  final Widget? topContent;
  final bool drawer;
  final String expandTooltip;
  final String collapseTooltip;
  final TextStyle? titleTextStyle;
  final TextStyle? itemTextStyle;
  final TextStyle? selectedItemTextStyle;
  final bool secondaryHeader;
  final double menuExpandedWidth;
  final double menuCollapsedWidth;
  final bool collapsedToggleInRail;

  @override
  Widget build(BuildContext context) => CollapsibleSidebarShell(
        title: title,
        collapsed: collapsed,
        onToggleCollapsed: onToggleCollapsed,
        drawer: drawer,
        secondaryHeader: secondaryHeader,
        expandedWidth: menuExpandedWidth,
        collapsedWidth: menuCollapsedWidth,
        collapsedToggleInRail: collapsedToggleInRail,
        expandTooltip: expandTooltip,
        collapseTooltip: collapseTooltip,
        builder: (context, layoutCollapsed) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (layoutCollapsed && collapsedToggleInRail)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
                child: Tooltip(
                  message: expandTooltip,
                  child: IconButton(
                    onPressed: onToggleCollapsed,
                    icon: const Icon(Icons.chevron_right_rounded),
                    iconSize: NavigationTokens.iconSize,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 32,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHigh,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                children: [
                  if (!layoutCollapsed && topContent != null) ...[
                    topContent!,
                    const SizedBox(height: 6),
                  ],
                  if (primaryAction != null) ...[
                    _primaryEntry(
                      context,
                      primaryAction!,
                      layoutCollapsed,
                    ),
                    const SizedBox(height: 6),
                  ],
                  for (final item in items) _entry(item, layoutCollapsed),
                  for (final group
                      in groups.where((g) => g.items.isNotEmpty)) ...[
                    if (!layoutCollapsed)
                      Divider(
                        height: 16,
                        thickness: 0.5,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.18),
                      ),
                    if (!layoutCollapsed && group.label.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 4, 4),
                        child: Text(
                          group.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.65),
                                  ),
                        ),
                      ),
                    for (final item in group.items)
                      _entry(item, layoutCollapsed),
                  ],
                  if (secondaryItems.isNotEmpty) ...[
                    const SizedBox(height: 8),
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
