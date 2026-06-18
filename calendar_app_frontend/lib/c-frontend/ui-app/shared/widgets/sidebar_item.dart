import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart';

/// A single nav row used in the persistent web sidebar.
///
/// Renders icon + label when [collapsed] is false; icon only (with tooltip)
/// when [collapsed] is true.
class SidebarItem extends StatefulWidget {
  const SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.collapsed,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  State<SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<SidebarItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppDarkColors.primary : AppColors.primary;
    final inactiveColor =
        isDark ? AppDarkColors.textSecondary : AppColors.textSecondary;

    final fg = widget.isSelected ? activeColor : inactiveColor;
    final showBg = widget.isSelected || _hovering;
    final borderColor = widget.isSelected
        ? activeColor.withValues(alpha: 0.26)
        : (_hovering
            ? activeColor.withValues(alpha: 0.14)
            : Colors.transparent);

    final inner = MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          height: 44,
          decoration: BoxDecoration(
            color: showBg
                ? activeColor.withValues(alpha: widget.isSelected ? 0.1 : 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              // Left accent bar — visible only when selected
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 3,
                height: widget.isSelected ? 22 : 0,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(3),
                    bottomRight: Radius.circular(3),
                  ),
                ),
              ),
              SizedBox(width: widget.isSelected ? 9 : 12),
              Icon(widget.icon, size: 20, color: fg),
              // Label — always in tree but faded out when collapsed
              if (!widget.collapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 160),
                    opacity: widget.collapsed ? 0 : 1,
                    child: Text(
                      widget.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (widget.collapsed) {
      return Tooltip(
        message: widget.label,
        preferBelow: false,
        child: inner,
      );
    }
    return inner;
  }
}
