import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:hexora/theme/colors/app_colors.dart';
import 'package:hexora/theme/themes/navigation_tokens.dart';
import 'package:hexora/theme/themes/theme_variant.dart';

/// Colors for the dark global navigation bar. Every interactive element in the
/// bar resolves its idle / hover / focus / active look from here so states
/// stay identical across destinations, menus and actions.
abstract final class HexoraGlobalNavColors {
  static const background = AppColors.dashboardTopBar;
  static const foreground = AppColors.navigationForeground;
  static const active = AppColors.primary;

  static Color backgroundFor(BuildContext context) {
    final theme = Theme.of(context);
    final neutralLight =
        theme.extension<HexoraThemeVariant>()?.neutralLight == true;
    return neutralLight ? theme.colorScheme.surface : AppColors.dashboardTopBar;
  }

  static Color foregroundFor(BuildContext context) {
    final theme = Theme.of(context);
    final neutralLight =
        theme.extension<HexoraThemeVariant>()?.neutralLight == true;
    return neutralLight
        ? theme.colorScheme.onSurface
        : AppColors.navigationForeground;
  }

  static Color fill({
    required bool selected,
    required bool hovered,
    required Color foreground,
    required Color background,
  }) {
    if (selected) return AppColors.selectedControl;
    if (hovered) return foreground.withValues(alpha: 0.08);
    return Colors.transparent;
  }

  static Color content({
    required bool selected,
    required bool hovered,
    required Color background,
    required Color foreground,
  }) {
    if (selected) return AppColors.textPrimary;
    return foreground.withValues(alpha: hovered ? 1 : 0.74);
  }

  static Color get divider => foreground.withValues(alpha: 0.10);
  static Color get focusRing => active.withValues(alpha: 0.85);
}

/// Shared compact style for the global-bar dropdowns (group switcher and worker
/// status). Keeps the two menus visually consistent across light/dark themes.
MenuStyle hexoraDropdownMenuStyle() => const MenuStyle(
      minimumSize: WidgetStatePropertyAll(Size(280, 0)),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      )),
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 6)),
      elevation: WidgetStatePropertyAll(8),
      visualDensity: VisualDensity.compact,
    );

/// Base interactive surface for global-bar controls. Handles hover, focus and
/// pressed states and hands the resolved foreground color to [builder].
class HexoraNavTile extends StatefulWidget {
  const HexoraNavTile({
    super.key,
    required this.builder,
    required this.onTap,
    this.selected = false,
    this.moduleTab = false,
    this.tooltip,
    this.semanticLabel,
    this.padding = const EdgeInsets.symmetric(
      horizontal: NavigationTokens.globalItemPadding,
    ),
    this.minWidth = NavigationTokens.globalItemHeight,
  });

  final Widget Function(BuildContext context, Color foreground) builder;
  final VoidCallback? onTap;
  final bool selected;
  final bool moduleTab;
  final String? tooltip;
  final String? semanticLabel;
  final EdgeInsetsGeometry padding;
  final double minWidth;

  @override
  State<HexoraNavTile> createState() => _HexoraNavTileState();
}

class _HexoraNavTileState extends State<HexoraNavTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final navBackground = HexoraGlobalNavColors.backgroundFor(context);
    final navForeground = HexoraGlobalNavColors.foregroundFor(context);
    final primary = Theme.of(context).colorScheme.primary;
    final fg = HexoraGlobalNavColors.content(
      selected: widget.selected,
      hovered: _hovered,
      background: navBackground,
      foreground: navForeground,
    );
    final radius = BorderRadius.circular(
      widget.selected ? 14 : NavigationTokens.radius,
    );
    final tabShape = _ModuleTabShape(
      side: _focused
          ? BorderSide(color: primary.withValues(alpha: 0.85), width: 1.5)
          : BorderSide.none,
    );

    Widget tile = Semantics(
      button: true,
      selected: widget.selected,
      label: widget.semanticLabel ?? widget.tooltip,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: radius,
        customBorder: widget.moduleTab ? tabShape : null,
        onHover: (v) => setState(() => _hovered = v),
        onFocusChange: (v) => setState(() => _focused = v),
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        splashColor: primary.withValues(alpha: 0.16),
        highlightColor: primary.withValues(alpha: 0.10),
        child: AnimatedContainer(
          duration: NavigationTokens.motion,
          curve: Curves.easeOutCubic,
          height: widget.moduleTab
              ? NavigationTokens.globalBarHeight
              : NavigationTokens.globalItemHeight,
          constraints: BoxConstraints(minWidth: widget.minWidth),
          padding: widget.moduleTab
              ? widget.padding.add(const EdgeInsets.symmetric(horizontal: 12))
              : widget.padding,
          decoration: widget.moduleTab
              ? ShapeDecoration(
                  color: HexoraGlobalNavColors.fill(
                    selected: widget.selected,
                    hovered: _hovered,
                    foreground: navForeground,
                    background: navBackground,
                  ),
                  shape: tabShape,
                )
              : BoxDecoration(
                  color: HexoraGlobalNavColors.fill(
                    selected: widget.selected,
                    hovered: _hovered,
                    foreground: navForeground,
                    background: navBackground,
                  ),
                  borderRadius: radius,
                  border: Border.all(
                    color: _focused
                        ? primary.withValues(alpha: 0.85)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
          alignment: Alignment.center,
          child: widget.builder(context, fg),
        ),
      ),
    );

    if (widget.tooltip != null) {
      tile = Tooltip(
        message: widget.tooltip!,
        waitDuration: const Duration(milliseconds: 350),
        child: tile,
      );
    }
    return tile;
  }
}

/// The selected module meets the header baseline with outward lower shoulders.
class _ModuleTabShape extends ShapeBorder {
  const _ModuleTabShape({this.side = BorderSide.none});

  final BorderSide side;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final x = rect.left;
    final y = rect.top + 8;
    final w = rect.width;
    final b = rect.bottom;
    return Path()
      ..moveTo(x, b)
      // Quarter-circle shoulders join the baseline with a horizontal tangent
      // and the sides with a vertical tangent, avoiding a pinched lower edge.
      ..cubicTo(x + 6.63, b, x + 12, b - 5.37, x + 12, b - 12)
      ..lineTo(x + 12, y + 12)
      ..cubicTo(x + 12, y + 5.37, x + 17.37, y, x + 24, y)
      ..lineTo(x + w - 24, y)
      ..cubicTo(x + w - 17.37, y, x + w - 12, y + 5.37, x + w - 12, y + 12)
      ..lineTo(x + w - 12, b - 12)
      ..cubicTo(x + w - 12, b - 5.37, x + w - 6.63, b, x + w, b)
      ..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style != BorderStyle.none) {
      canvas.drawPath(getOuterPath(rect), side.toPaint());
    }
  }

  @override
  ShapeBorder scale(double t) => _ModuleTabShape(side: side.scale(t));
}

/// Square icon-only action for the global bar. Always carries a tooltip.
class HexoraNavIconButton extends StatelessWidget {
  const HexoraNavIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return HexoraNavTile(
      tooltip: tooltip,
      selected: selected,
      onTap: onPressed,
      padding: EdgeInsets.zero,
      builder: (context, fg) => HexoraBadgeAnchor(
        count: badgeCount,
        attention: !selected,
        child: Icon(icon, size: NavigationTokens.iconSize, color: fg),
      ),
    );
  }
}

/// Places a [HexoraNotificationBadge] on the top-right corner of [child].
class HexoraBadgeAnchor extends StatelessWidget {
  const HexoraBadgeAnchor({
    super.key,
    required this.child,
    required this.count,
    this.attention = false,
  });

  final Widget child;
  final int count;
  final bool attention;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -7,
          top: -6,
          child: HexoraNotificationBadge(count: count, attention: attention),
        ),
      ],
    );
  }
}

/// Compact unread counter. Shows a soft pulse ring while [attention] is set.
class HexoraNotificationBadge extends StatefulWidget {
  const HexoraNotificationBadge({
    super.key,
    required this.count,
    this.attention = false,
  });

  final int count;
  final bool attention;

  @override
  State<HexoraNotificationBadge> createState() =>
      _HexoraNotificationBadgeState();
}

class _HexoraNotificationBadgeState extends State<HexoraNotificationBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant HexoraNotificationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attention != widget.attention) _sync();
  }

  void _sync() {
    if (widget.attention) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = widget.count > 9 ? '9+' : '${widget.count}';
    const h = NavigationTokens.badgeHeight;

    final badge = Container(
      height: h,
      constraints: const BoxConstraints(minWidth: h),
      padding: const EdgeInsets.symmetric(horizontal: 3.5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cs.error,
        borderRadius: BorderRadius.circular(h),
        border: Border.all(
          color: HexoraGlobalNavColors.backgroundFor(context),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: cs.onError,
          fontSize: NavigationTokens.badgeTextSize,
          height: 1,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );

    return Semantics(
      label: '${widget.count}',
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (widget.attention)
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) {
                final t = Curves.easeOut.transform(_pulse.value);
                return Transform.scale(
                  scale: 1 + t * 0.9,
                  child: Container(
                    width: h,
                    height: h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.error.withValues(alpha: 0.35 * (1 - t)),
                    ),
                  ),
                );
              },
            ),
          badge,
        ],
      ),
    );
  }
}

/// Circular blue expand/collapse control shared by module side menus.
class SidebarCollapseToggle extends StatelessWidget {
  const SidebarCollapseToggle({
    super.key,
    required this.collapsed,
    required this.onPressed,
    this.expandTooltip,
    this.collapseTooltip,
    this.diameter = 32,
  });

  final bool collapsed;
  final VoidCallback? onPressed;
  final String? expandTooltip;
  final String? collapseTooltip;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final es = Localizations.localeOf(context).languageCode == 'es';
    final tooltip = collapsed
        ? expandTooltip ?? (es ? 'Expandir barra lateral' : 'Expand sidebar')
        : collapseTooltip ??
            (es ? 'Contraer barra lateral' : 'Collapse sidebar');
    return SizedBox.square(
      dimension: 44,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Container(
          width: diameter,
          height: diameter,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: onPressed == null
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.18),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(
            collapsed ? LucideIcons.chevronRight : LucideIcons.chevronLeft,
            size: diameter * 0.61,
            color: Colors.white,
          ),
        ),
        style: ButtonStyle(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          minimumSize: const WidgetStatePropertyAll(Size.square(44)),
          fixedSize: const WidgetStatePropertyAll(Size.square(44)),
          overlayColor: WidgetStatePropertyAll(
            AppColors.primary.withValues(alpha: 0.12),
          ),
          side: const WidgetStatePropertyAll(BorderSide.none),
          shape: const WidgetStatePropertyAll(CircleBorder()),
        ),
      ),
    );
  }
}
