import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hexora/models/user/user_preferences.dart';
import 'package:hexora/navigation/shell/hexora_nav_components.dart';
import 'package:hexora/theme/themes/navigation_tokens.dart';

/// Where a destination appears in the global bar.
enum HexoraNavPlacement {
  /// Visible in the main strip.
  primary,

  /// Grouped under the "More" menu (rarely used modules).
  more,

  /// Not shown as a strip item (it has a dedicated control, e.g. the
  /// notifications bell) but still reachable from search.
  searchOnly,
}

class HexoraNavDestination {
  const HexoraNavDestination({
    required this.id,
    required this.icon,
    required this.label,
    this.placement = HexoraNavPlacement.primary,
  });

  final String id;
  final IconData icon;
  final String label;
  final HexoraNavPlacement placement;
}

/// Global, module-level navigation for the workspace (56px).
///
/// Layout: brand · module strip (+ More) · search · notifications · profile.
/// Labels collapse to icons (with tooltips) on narrower windows or when the
/// user picks the compact density; the active module always keeps its label.
///
/// When [groupSwitcher] is provided it replaces the "HEXORA" wordmark.
class HexoraGlobalNavBar extends StatelessWidget {
  const HexoraGlobalNavBar({
    super.key,
    required this.destinations,
    required this.activeId,
    required this.onSelected,
    this.onBrandTap,
    this.brandTooltip,
    this.navigationDisplayMode = NavigationDisplayMode.automatic,
    this.notificationCount = 0,
    this.notificationsSelected = false,
    this.onOpenNotifications,
    this.downloads,
    this.onlineMembers,
    this.profile,
    this.profileDetails,
    this.onBack,
    this.backTooltip,
    this.groupSwitcher,
    this.collapsed = false,
    this.onToggleCollapsed,
  });

  final List<HexoraNavDestination> destinations;
  final String activeId;
  final ValueChanged<String> onSelected;
  final VoidCallback? onBrandTap;
  final String? brandTooltip;
  final NavigationDisplayMode navigationDisplayMode;
  final int notificationCount;
  final bool notificationsSelected;
  final VoidCallback? onOpenNotifications;
  final Widget? downloads;
  final Widget? onlineMembers;
  final Widget? profile;
  final Widget? profileDetails;
  final VoidCallback? onBack;
  final String? backTooltip;

  /// When set, replaces the "HEXORA" wordmark with this widget (typically a
  /// group/workspace switcher).
  final Widget? groupSwitcher;

  /// Distraction-free state: this bar collapses to zero height. The shared
  /// sidebar shell supplies the HEXORA restore header beside workspace tabs.
  final bool collapsed;

  /// Toggles [collapsed]. When provided, clicking the HEXORA brand calls this
  /// instead of [onBrandTap].
  final VoidCallback? onToggleCollapsed;

  // The wordmark drops before the company name, so the active workspace stays
  // identifiable longer than the Hexora brand text (responsive priority).
  static const double _brandTextBreakpoint = 1280;
  static const double _companyNameBreakpoint = 1100;
  static const double _profileDetailsBreakpoint = 1600;

  /// Subtle branded texture reused from the home page's dark background. Held
  /// as a const so the decoded image is cached and never reloaded on rebuilds.
  static const DecorationImage _brandedBackground = DecorationImage(
    image: AssetImage('assets/images/home_page/dark_bg_color.png'),
    fit: BoxFit.cover,
    alignment: Alignment.centerRight,
    opacity: 0.22,
  );

  double _destinationWidth(HexoraNavDestination destination) {
    final labelWidth =
        (destination.label.characters.length * 7.0).clamp(34.0, 126.0);
    return NavigationTokens.globalItemHeight + labelWidth + 8;
  }

  double _reservedActionWidth(double viewportWidth) {
    final compactActions =
        navigationDisplayMode == NavigationDisplayMode.iconsOnly ||
            viewportWidth < 1200;
    var width = 12.0;
    if (downloads != null) width += compactActions ? 44 : 112;
    if (onlineMembers != null) width += compactActions ? 44 : 136;
    if (onOpenNotifications != null) width += 44;
    if (profile != null) width += 50;
    if (profileDetails != null &&
        navigationDisplayMode != NavigationDisplayMode.iconsOnly &&
        viewportWidth >= _profileDetailsBreakpoint) {
      width += 148;
    }
    if (onBack != null) width += 46;
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final es = Localizations.localeOf(context).languageCode == 'es';
    final primary = destinations
        .where((d) => d.placement == HexoraNavPlacement.primary)
        .toList();
    final grouped = destinations
        .where((d) => d.placement == HexoraNavPlacement.more)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final showWordmark = width >= _brandTextBreakpoint;
        // Left cluster = Hexora brand (logo [+ wordmark]) then the company
        // selector. Both stay; the module strip takes the remaining width.
        final brandWidth = showWordmark ? 120.0 : 40.0;
        final companyWidth = groupSwitcher == null
            ? 0.0
            : (width >= _companyNameBreakpoint ? 196.0 : 52.0);
        final leftWidth =
            brandWidth + (groupSwitcher == null ? 0.0 : 8.0 + companyWidth);
        final availableModuleWidth =
            width - 24 - leftWidth - 25 - _reservedActionWidth(width);
        final labeledModuleWidth = primary.fold<double>(
              0,
              (sum, destination) => sum + _destinationWidth(destination),
            ) +
            (grouped.isNotEmpty ? 76 : 0);
        final showLabels = switch (navigationDisplayMode) {
          NavigationDisplayMode.automatic =>
            availableModuleWidth >= labeledModuleWidth,
          NavigationDisplayMode.iconsAndText => true,
          NavigationDisplayMode.iconsOnly => false,
        };
        final iconsOnly =
            navigationDisplayMode == NavigationDisplayMode.iconsOnly;

        final toggleTooltip = collapsed
            ? (es ? 'Mostrar menú principal' : 'Show main menu')
            : (es ? 'Ocultar menú principal' : 'Hide main menu');
        // Shell geometry is animated by HexoraAppShell. This surface always
        // keeps its natural height so its controls are clipped as a whole
        // instead of being squeezed into intermediate constraints.
        return Container(
          key: const ValueKey('global-nav-surface'),
          height: NavigationTokens.globalBarHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            // Navy stays the fallback/base; the branded texture sits subtly
            // on top so labels and icons remain readable.
            color: HexoraGlobalNavColors.background,
            image: _brandedBackground,
            border: Border(
              bottom: BorderSide(color: HexoraGlobalNavColors.divider),
            ),
          ),
          child: Row(
            children: [
              _Brand(
                onTap: onToggleCollapsed ?? onBrandTap,
                collapsed: false,
                showText: showWordmark,
                tooltip:
                    onToggleCollapsed == null ? brandTooltip : toggleTooltip,
              ),
              if (groupSwitcher != null) ...[
                const SizedBox(width: 8),
                groupSwitcher!,
              ],
              Container(
                width: 1,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: HexoraGlobalNavColors.divider,
              ),
              Expanded(
                child: _ScrollableNavStrip(
                  isSpanish: es,
                  children: [
                    for (final d in primary)
                      _DestinationItem(
                        destination: d,
                        selected: d.id == activeId,
                        showLabel:
                            showLabels || (!iconsOnly && d.id == activeId),
                        onTap: () => onSelected(d.id),
                      ),
                    if (grouped.isNotEmpty)
                      _MoreMenu(
                        items: grouped,
                        activeId: activeId,
                        showLabel: showLabels,
                        iconsOnly: iconsOnly,
                        onSelected: onSelected,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (downloads != null) ...[
                downloads!,
                const SizedBox(width: 4),
              ],
              if (onlineMembers != null) ...[
                const SizedBox(width: 4),
                onlineMembers!,
              ],
              if (onOpenNotifications != null) ...[
                const SizedBox(width: 4),
                HexoraNavIconButton(
                  icon: notificationCount > 0
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_none_rounded,
                  tooltip: notificationCount > 0
                      ? (es
                          ? 'Notificaciones ($notificationCount sin leer)'
                          : 'Notifications ($notificationCount unread)')
                      : (es ? 'Notificaciones' : 'Notifications'),
                  selected: notificationsSelected,
                  badgeCount: notificationCount,
                  onPressed: onOpenNotifications,
                ),
              ],
              if (profile != null) ...[
                const SizedBox(width: 10),
                profile!,
              ],
              if (profileDetails != null &&
                  !iconsOnly &&
                  width >= _profileDetailsBreakpoint) ...[
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: profileDetails!,
                ),
              ],
              if (onBack != null) ...[
                const SizedBox(width: 6),
                HexoraNavIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: backTooltip ?? (es ? 'Volver' : 'Back'),
                  onPressed: onBack,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({
    required this.onTap,
    required this.tooltip,
    required this.showText,
    required this.collapsed,
  });

  final VoidCallback? onTap;
  final String? tooltip;
  final bool showText;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: collapsed
          ? BoxDecoration(
              color: HexoraGlobalNavColors.background,
              borderRadius: BorderRadius.circular(NavigationTokens.radius),
            )
          : const BoxDecoration(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.asset(
                'assets/images/branding/logo_icon.png',
                width: 28,
                height: 28,
              ),
            ),
            if (showText) ...[
              const SizedBox(width: 8),
              Text(
                'HEXORA',
                style: NavigationTokens.title(context).copyWith(
                  color: HexoraGlobalNavColors.foreground,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
            if (onTap != null) ...[
              const SizedBox(width: 3),
              Icon(
                collapsed
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_up_rounded,
                size: 16,
                color: HexoraGlobalNavColors.foreground.withValues(alpha: 0.72),
              ),
            ],
          ],
        ),
      ),
    );
    if (onTap == null) {
      return Semantics(label: 'Hexora', child: content);
    }
    final accessibleLabel = tooltip ?? 'Hexora';
    return Semantics(
      button: true,
      expanded: !collapsed,
      label: accessibleLabel,
      child: Tooltip(
        message: accessibleLabel,
        waitDuration: const Duration(milliseconds: 350),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(NavigationTokens.radius),
          hoverColor: HexoraGlobalNavColors.foreground.withValues(alpha: 0.06),
          focusColor: HexoraGlobalNavColors.foreground.withValues(alpha: 0.14),
          child: ExcludeSemantics(child: content),
        ),
      ),
    );
  }
}

class _DestinationItem extends StatelessWidget {
  const _DestinationItem({
    required this.destination,
    required this.selected,
    required this.showLabel,
    required this.onTap,
  });

  final HexoraNavDestination destination;
  final bool selected;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: HexoraNavTile(
        selected: selected,
        onTap: onTap,
        tooltip: showLabel ? null : destination.label,
        semanticLabel: destination.label,
        padding: showLabel
            ? const EdgeInsets.symmetric(
                horizontal: NavigationTokens.globalItemPadding)
            : EdgeInsets.zero,
        builder: (context, fg) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(destination.icon, size: NavigationTokens.iconSize, color: fg),
            if (showLabel) ...[
              const SizedBox(width: 6),
              Text(
                destination.label,
                style: NavigationTokens.label(context, selected: selected)
                    .copyWith(color: fg),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({
    required this.items,
    required this.activeId,
    required this.showLabel,
    required this.iconsOnly,
    required this.onSelected,
  });

  final List<HexoraNavDestination> items;
  final String activeId;
  final bool showLabel;
  final bool iconsOnly;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final es = Localizations.localeOf(context).languageCode == 'es';
    final cs = Theme.of(context).colorScheme;
    final moreLabel = es ? 'Más' : 'More';
    HexoraNavDestination? active;
    for (final d in items) {
      if (d.id == activeId) active = d;
    }
    final labelText = active?.label ?? moreLabel;
    final hasLabel = showLabel || (active != null && !iconsOnly);

    return MenuAnchor(
      alignmentOffset: const Offset(0, 6),
      menuChildren: [
        for (final d in items)
          MenuItemButton(
            leadingIcon: Icon(d.icon, size: NavigationTokens.iconSize),
            trailingIcon: d.id == activeId
                ? Icon(Icons.check_rounded,
                    size: NavigationTokens.iconSize, color: cs.primary)
                : null,
            onPressed: () => onSelected(d.id),
            child: Text(d.label, style: NavigationTokens.label(context)),
          ),
      ],
      builder: (context, controller, _) => HexoraNavTile(
        selected: active != null,
        tooltip: hasLabel
            ? null
            : (es ? 'Más módulos y opciones' : 'More modules and options'),
        semanticLabel: labelText,
        padding: hasLabel
            ? const EdgeInsets.only(
                left: NavigationTokens.globalItemPadding, right: 6)
            : EdgeInsets.zero,
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
        builder: (context, fg) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(active?.icon ?? Icons.more_horiz_rounded,
                size: NavigationTokens.iconSize, color: fg),
            if (hasLabel) ...[
              const SizedBox(width: 6),
              Text(
                labelText,
                style: NavigationTokens.label(context, selected: active != null)
                    .copyWith(color: fg),
              ),
              const SizedBox(width: 2),
              Icon(Icons.expand_more_rounded, size: 16, color: fg),
            ],
          ],
        ),
      ),
    );
  }
}

/// Horizontal strip that scrolls (wheel or chevrons) when modules do not fit.
class _ScrollableNavStrip extends StatefulWidget {
  const _ScrollableNavStrip({required this.children, required this.isSpanish});

  final List<Widget> children;
  final bool isSpanish;

  @override
  State<_ScrollableNavStrip> createState() => _ScrollableNavStripState();
}

class _ScrollableNavStripState extends State<_ScrollableNavStrip> {
  final ScrollController _controller = ScrollController();
  bool _hasOverflow = false;
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncScrollState);
    _scheduleScrollStateSync();
  }

  @override
  void didUpdateWidget(covariant _ScrollableNavStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleScrollStateSync();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_syncScrollState)
      ..dispose();
    super.dispose();
  }

  void _scheduleScrollStateSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncScrollState();
    });
  }

  void _syncScrollState() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final hasOverflow = position.maxScrollExtent > 0.5;
    final canScrollLeft = position.pixels > 0.5;
    final canScrollRight = position.pixels < position.maxScrollExtent - 0.5;
    if (_hasOverflow == hasOverflow &&
        _canScrollLeft == canScrollLeft &&
        _canScrollRight == canScrollRight) {
      return;
    }
    setState(() {
      _hasOverflow = hasOverflow;
      _canScrollLeft = canScrollLeft;
      _canScrollRight = canScrollRight;
    });
  }

  void _scrollBy(double delta) {
    if (!_controller.hasClients) return;
    final target = (_controller.offset + delta)
        .clamp(0.0, _controller.position.maxScrollExtent)
        .toDouble();
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_controller.hasClients) return;
    if (event.scrollDelta.dy.abs() <= event.scrollDelta.dx.abs()) return;
    _scrollBy(event.scrollDelta.dy);
  }

  @override
  Widget build(BuildContext context) {
    _scheduleScrollStateSync();
    return Row(
      children: [
        if (_hasOverflow)
          _scrollButton(
            icon: Icons.chevron_left_rounded,
            tooltip: widget.isSpanish
                ? 'Ver módulos anteriores'
                : 'View previous modules',
            enabled: _canScrollLeft,
            onPressed: () => _scrollBy(-260),
          ),
        Expanded(
          child: Listener(
            onPointerSignal: _handlePointerSignal,
            child: SingleChildScrollView(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              child: Row(children: widget.children),
            ),
          ),
        ),
        if (_hasOverflow)
          _scrollButton(
            icon: Icons.chevron_right_rounded,
            tooltip: widget.isSpanish ? 'Ver más módulos' : 'View more modules',
            enabled: _canScrollRight,
            onPressed: () => _scrollBy(260),
          ),
      ],
    );
  }

  Widget _scrollButton({
    required IconData icon,
    required String tooltip,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    const fg = HexoraGlobalNavColors.foreground;
    return IconButton(
      tooltip: tooltip,
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: NavigationTokens.iconSize),
      color: fg.withValues(alpha: 0.72),
      disabledColor: fg.withValues(alpha: 0.20),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 28, height: 36),
    );
  }
}
