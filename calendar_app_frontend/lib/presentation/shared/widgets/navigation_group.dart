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
class CollapsedNavigationGroup extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colors = NavigationColors(Theme.of(context).colorScheme);
    return MenuAnchor(
      alignmentOffset: const Offset(44, -40),
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
        for (final destination in destinations)
          MenuItemButton(
            onPressed: destination.onTap,
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
      builder: (context, controller, child) => SidebarItem(
        icon: icon,
        label: title,
        isSelected: selected,
        collapsed: true,
        groupHeader: true,
        onTap: controller.isOpen ? controller.close : controller.open,
      ),
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
                  constraints: const BoxConstraints(minHeight: 34),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 8, 6),
                    child: Row(
                      children: [
                        Icon(widget.icon,
                            size: 17, color: colors.groupForeground),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            widget.title.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: NavigationTokens.section(context).copyWith(
                              color: colors.groupForeground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          turns: _isExpanded ? .5 : 0,
                          duration: duration,
                          child: Icon(Icons.keyboard_arrow_down_rounded,
                              size: 17, color: colors.foreground),
                        ),
                      ],
                    ),
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
                    margin: const EdgeInsetsDirectional.only(start: 8),
                    padding: const EdgeInsetsDirectional.only(
                      start: 6,
                      top: NavigationTokens.childGap,
                    ),
                    decoration: BoxDecoration(
                      border: BorderDirectional(
                        start: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withValues(alpha: .42),
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
