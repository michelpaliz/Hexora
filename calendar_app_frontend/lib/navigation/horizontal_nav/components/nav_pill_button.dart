import 'package:hexora/theme/themes/navigation_tokens.dart';
import 'package:flutter/material.dart';

class NavPillButton extends StatefulWidget {
  final IconData? icon; // icon OR child (avatar)
  final Widget? child;
  final String? semanticLabel;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const NavPillButton({
    super.key,
    this.icon,
    this.child,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
    this.semanticLabel,
  });

  @override
  State<NavPillButton> createState() => _NavPillButtonState();
}

class _NavPillButtonState extends State<NavPillButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final showHighlight = widget.isSelected || _hovering;

    return InkWell(
      borderRadius: BorderRadius.circular(NavigationTokens.radius),
      onTap: widget.onTap,
      onHover: (value) => setState(() => _hovering = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: NavigationTokens.rowHeight(context),
        padding: EdgeInsets.symmetric(
          horizontal: showHighlight ? 16 : 12,
        ),
        decoration: BoxDecoration(
          color: showHighlight
              ? widget.activeColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(NavigationTokens.radius),
        ),
        child: Center(
          child: AnimatedScale(
            duration: const Duration(milliseconds: 160),
            scale: 1,
            child: widget.child ??
                Icon(
                  widget.icon!,
                  size: NavigationTokens.iconSize,
                  color: widget.isSelected
                      ? widget.activeColor
                      : widget.inactiveColor,
                  semanticLabel: widget.semanticLabel,
                ),
          ),
        ),
      ),
    );
  }
}
