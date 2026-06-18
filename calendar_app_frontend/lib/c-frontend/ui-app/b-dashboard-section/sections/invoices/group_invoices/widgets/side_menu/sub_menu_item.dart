import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class GroupInvoicesSubMenuItem extends StatefulWidget {
  const GroupInvoicesSubMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.count,
    this.primaryAction = false,
    this.indent = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  final int? count;
  final bool primaryAction;
  final double indent;

  @override
  State<GroupInvoicesSubMenuItem> createState() =>
      _GroupInvoicesSubMenuItemState();
}

class _GroupInvoicesSubMenuItemState extends State<GroupInvoicesSubMenuItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final enabled = widget.onPressed != null;
    const animationDuration = Duration(milliseconds: 170);
    final hovered = enabled && _hovering;
    final fg = widget.selected
        ? cs.primary
        : hovered
            ? cs.onSurface
            : widget.primaryAction
                ? cs.onSurfaceVariant
                : (enabled ? cs.onSurfaceVariant : cs.outline);
    final iconColor = widget.selected
        ? cs.primary
        : hovered
            ? cs.primary
            : widget.primaryAction
                ? cs.primary.withValues(alpha: 0.82)
                : fg;
    final bg = widget.selected
        ? cs.primary.withValues(alpha: 0.105)
        : hovered
            ? cs.surfaceContainerHighest.withValues(alpha: 0.34)
            : widget.primaryAction
                ? cs.surfaceContainerHighest.withValues(alpha: 0.22)
                : enabled
                    ? Colors.transparent
                    : cs.surfaceContainerHighest.withValues(alpha: 0.08);
    final borderColor = widget.selected
        ? cs.primary.withValues(alpha: 0.18)
        : widget.primaryAction
            ? cs.outlineVariant.withValues(alpha: hovered ? 0.30 : 0.22)
            : hovered
                ? cs.outlineVariant.withValues(alpha: 0.18)
                : Colors.transparent;

    return Padding(
      padding: EdgeInsets.only(left: widget.indent, bottom: 2),
      child: Tooltip(
        message: widget.label,
        waitDuration: const Duration(milliseconds: 450),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(10),
            hoverColor: Colors.transparent,
            splashColor: cs.primary.withValues(alpha: 0.08),
            child: AnimatedContainer(
              duration: animationDuration,
              curve: Curves.easeOutCubic,
              height: widget.primaryAction ? 30 : 32,
              padding: EdgeInsets.symmetric(
                horizontal: widget.primaryAction ? 9 : 10,
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(widget.selected ? 9 : 8),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: animationDuration,
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      widget.icon,
                      size: widget.primaryAction ? 14 : 15,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: animationDuration,
                      curve: Curves.easeOutCubic,
                      style: t.bodySmall.copyWith(
                        color: fg,
                        fontSize: widget.primaryAction ? 11.8 : 12.3,
                        fontWeight: widget.selected || widget.primaryAction
                            ? FontWeight.w700
                            : FontWeight.w600,
                        letterSpacing: 0,
                      ),
                      child: Text(
                        widget.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (widget.count != null)
                    _SidebarBadge(
                      count: widget.count!,
                      selected: widget.selected,
                    ),
                  if (!enabled)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        'Pronto',
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarBadge extends StatelessWidget {
  const _SidebarBadge({
    required this.count,
    required this.selected,
  });

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      constraints: const BoxConstraints(minWidth: 20, minHeight: 18),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected
            ? cs.primary.withValues(alpha: 0.14)
            : cs.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected
              ? cs.primary.withValues(alpha: 0.18)
              : cs.outlineVariant.withValues(alpha: 0.24),
        ),
      ),
      child: Text(
        count.toString(),
        style: t.caption.copyWith(
          color: selected ? cs.primary : cs.onSurfaceVariant,
          fontWeight: FontWeight.w800,
          fontSize: 10.5,
          letterSpacing: 0,
          height: 1.0,
        ),
      ),
    );
  }
}
