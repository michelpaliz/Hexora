import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/sidebar_item.dart';
import 'package:hexora/theme/motion/hexora_motion.dart';
import 'package:hexora/theme/themes/navigation_tokens.dart';

class CollapsedNavigationDestination {
  const CollapsedNavigationDestination({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
    this.count,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;
  final int? count;
}

/// Accessible flyout for an expandable group rendered in a collapsed rail.
class CollapsedNavigationGroup extends StatefulWidget {
  const CollapsedNavigationGroup({
    super.key,
    required this.title,
    required this.icon,
    required this.destinations,
    this.selected = false,
  });

  final String title;
  final IconData icon;
  final List<CollapsedNavigationDestination> destinations;
  final bool selected;

  @override
  State<CollapsedNavigationGroup> createState() =>
      _CollapsedNavigationGroupState();
}

class _CollapsedNavigationGroupState extends State<CollapsedNavigationGroup> {
  Timer? _openTimer;
  Timer? _closeTimer;
  MenuController? _menuController;
  bool _anchorHovered = false;
  bool _menuHovered = false;

  @override
  void dispose() {
    _openTimer?.cancel();
    _closeTimer?.cancel();
    super.dispose();
  }

  void _openOnHover(MenuController controller) {
    _anchorHovered = true;
    _closeTimer?.cancel();
    if (controller.isOpen) return;
    _openTimer?.cancel();
    _openTimer = Timer(const Duration(milliseconds: 220), () {
      if (mounted && _anchorHovered && !controller.isOpen) controller.open();
    });
  }

  void _leaveAnchor(MenuController controller) {
    _anchorHovered = false;
    _openTimer?.cancel();
    _scheduleClose(controller);
  }

  void _hoverMenu(MenuController controller, bool hovered) {
    _menuHovered = hovered;
    if (hovered) {
      _closeTimer?.cancel();
    } else {
      _scheduleClose(controller);
    }
  }

  void _scheduleClose(MenuController controller) {
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 260), () {
      if (mounted && !_anchorHovered && !_menuHovered && controller.isOpen) {
        controller.close();
      }
    });
  }

  void _toggle(MenuController controller) {
    _openTimer?.cancel();
    _closeTimer?.cancel();
    if (controller.isOpen) {
      controller.close();
    } else {
      controller.open();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = NavigationColors(Theme.of(context).colorScheme);
    return MenuAnchor(
      alignmentOffset: const Offset(NavigationTokens.railWidth - 8, -40),
      style: MenuStyle(
        visualDensity: VisualDensity.compact,
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 6),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NavigationTokens.radius),
          ),
        ),
      ),
      menuChildren: [
        for (final destination in widget.destinations)
          MenuItemButton(
            onPressed: destination.onTap,
            onHover: (hovered) {
              final controller = _menuController;
              if (controller != null) _hoverMenu(controller, hovered);
            },
            leadingIcon: Icon(
              destination.icon,
              size: NavigationTokens.iconSize,
            ),
            trailingIcon: destination.count == null
                ? null
                : Text(
                    '${destination.count}',
                    style: NavigationTokens.label(context).copyWith(
                      fontSize: NavigationTokens.countSize,
                    ),
                  ),
            style: ButtonStyle(
              minimumSize: const WidgetStatePropertyAll(Size(190, 40)),
              backgroundColor: destination.selected
                  ? WidgetStatePropertyAll(colors.selectedBackground)
                  : null,
              foregroundColor: destination.selected
                  ? WidgetStatePropertyAll(colors.selectedForeground)
                  : null,
            ),
            child: Text(destination.label),
          ),
      ],
      builder: (context, controller, child) {
        _menuController = controller;
        return MouseRegion(
          onEnter: (_) => _openOnHover(controller),
          onExit: (_) => _leaveAnchor(controller),
          child: SidebarItem(
            icon: widget.icon,
            label: widget.title,
            isSelected: widget.selected,
            collapsed: true,
            groupHeader: true,
            onTap: () => _toggle(controller),
          ),
        );
      },
    );
  }
}

class NavigationGroup extends StatefulWidget {
  const NavigationGroup({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.expanded,
    this.onToggle,
    this.initiallyExpanded = true,
    this.storageId,
  });

  final String title;
  final IconData icon;
  final bool? expanded;
  final VoidCallback? onToggle;
  final Widget child;
  final bool initiallyExpanded;
  final String? storageId;

  @override
  State<NavigationGroup> createState() => _NavigationGroupState();
}

class _NavigationGroupState extends State<NavigationGroup> {
  late bool _expanded = widget.initiallyExpanded;
  bool _restored = false;

  bool get _isExpanded => widget.expanded ?? _expanded;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_restored || widget.expanded != null || widget.storageId == null) {
      return;
    }
    _restored = true;
    final stored = PageStorage.maybeOf(context)
        ?.readState(context, identifier: widget.storageId);
    if (stored is bool) _expanded = stored;
  }

  void _toggle() {
    if (widget.onToggle != null) {
      widget.onToggle!();
      return;
    }
    setState(() => _expanded = !_expanded);
    if (widget.storageId != null) {
      PageStorage.maybeOf(context)?.writeState(
        context,
        _expanded,
        identifier: widget.storageId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = NavigationColors(Theme.of(context).colorScheme);
    final duration = HexoraMotion.duration(
      context,
      HexoraMotion.submenuNavigation,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: NavigationTokens.groupGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            expanded: _isExpanded,
            button: true,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(NavigationTokens.radius),
              child: InkWell(
                onTap: _toggle,
                borderRadius: BorderRadius.circular(NavigationTokens.radius),
                overlayColor: WidgetStateProperty.resolveWith(colors.overlay),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 32),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // During the sidebar-width animation the group can be
                      // temporarily narrower than its icon, label and chevron.
                      // Render only the icon until the full header fits.
                      if (constraints.maxWidth < 76) {
                        return ClipRect(
                          child: Center(
                            child: Icon(
                              widget.icon,
                              size: NavigationTokens.iconSize,
                              color: colors.groupForeground,
                            ),
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          10,
                          4,
                          8,
                          6,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              widget.icon,
                              size: NavigationTokens.iconSize,
                              color: colors.groupForeground,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Tooltip(
                                message: widget.title,
                                child: Text(
                                  widget.title.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: NavigationTokens.section(context)
                                      .copyWith(
                                    color: colors.groupForeground,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            AnimatedRotation(
                              turns: _isExpanded ? .5 : 0,
                              duration: duration,
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: NavigationTokens.iconSize,
                                color: colors.foreground,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: duration,
            curve: HexoraMotion.enter,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Container(
                    margin: const EdgeInsetsDirectional.only(start: 6),
                    padding: const EdgeInsetsDirectional.only(
                      start: 4,
                      top: NavigationTokens.childGap,
                    ),
                    decoration: BoxDecoration(
                      border: BorderDirectional(
                        start: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withValues(alpha: .28),
                          width: 1,
                        ),
                      ),
                    ),
                    child: widget.child,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
