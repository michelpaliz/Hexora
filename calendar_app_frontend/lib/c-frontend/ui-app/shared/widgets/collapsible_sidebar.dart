import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/sidebar_item.dart';

/// Navigation entry rendered by [CollapsibleSidebar].
class CollapsibleSidebarItem {
  const CollapsibleSidebarItem({
    this.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final Key? key;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
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

  static const double expandedWidth = 214;
  static const double collapsedWidth = 64;
  static const double responsiveBreakpoint = 760;
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
  Widget build(BuildContext context) {
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.65),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 8, 8),
                child: Row(
                  mainAxisAlignment: layoutCollapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    if (!layoutCollapsed) ...[
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          headerIcon,
                          size: 17,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: titleTextStyle ??
                              Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                    if (!drawer)
                      IconButton.filledTonal(
                        key: const ValueKey('collapsible-sidebar-toggle'),
                        tooltip: collapsed ? expandTooltip : collapseTooltip,
                        onPressed: onToggleCollapsed,
                        icon: Icon(
                          collapsed
                              ? Icons.keyboard_double_arrow_right_rounded
                              : Icons.keyboard_double_arrow_left_rounded,
                        ),
                        iconSize: 18,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(40, 34),
                          fixedSize: const Size(40, 34),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
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
    if (isCollapsed) {
      return Center(
        child: IconButton.filledTonal(
          key: item.key,
          tooltip: item.label,
          onPressed: item.onTap,
          icon: Icon(item.icon, size: 20),
          style: IconButton.styleFrom(
            fixedSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 44,
      child: FilledButton.icon(
        key: item.key,
        onPressed: item.onTap,
        icon: Icon(item.icon, size: 20),
        label: Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: FilledButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
