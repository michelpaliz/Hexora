import 'package:flutter/material.dart';
import 'package:hexora/navigation/shell/global_navigation_collapse_scope.dart';
import 'package:hexora/navigation/shell/hexora_nav_components.dart';
import 'package:hexora/presentation/shared/widgets/secondary_sidebar_header.dart';
import 'package:hexora/presentation/utils/logo/hexora_brand.dart';
import 'package:hexora/theme/colors/app_colors.dart';
import 'package:hexora/theme/themes/theme_variant.dart';

abstract final class SidebarEdgeGeometry {
  /// The painted circle is intentionally smaller than its interaction target.
  static const double handleDiameter = 32;
  static const double handleTapTarget = 44;
  static const double notchSpan = 76;
  static const double expandedNotchDepth = 18;
  static const double collapsedNotchDepth = 14;

  static double notchDepth(bool collapsed) =>
      collapsed ? collapsedNotchDepth : expandedNotchDepth;

  static double handleCenterInset(bool collapsed) {
    final depth = notchDepth(collapsed);
    const radius = handleDiameter / 2;
    return depth < radius ? radius : depth;
  }

  static double contentSafeInset(bool collapsed) =>
      collapsed ? 0 : expandedNotchDepth;

  static double centerY(double viewportHeight) => viewportHeight / 2;

  /// Matches the Chrome-style workspace tab strip.
  static const double globalRestoreHeaderHeight = 36;
}

typedef SidebarFooterBuilder = Widget Function(
  BuildContext context,
  bool collapsed,
);

typedef SidebarHeaderBuilder = Widget Function(
  BuildContext context,
  bool collapsed,
);

/// Aligns contextual module sidebars beneath the primary sidebar controls.
/// The primary module sidebar sits outside this scope, so only secondary
/// navigation receives the inset.
class SecondarySidebarTopInsetScope extends InheritedWidget {
  const SecondarySidebarTopInsetScope({
    super.key,
    required this.topInset,
    this.title,
    this.icon,
    required super.child,
  });

  final double topInset;
  final String? title;
  final IconData? icon;

  static SecondarySidebarTopInsetScope? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<SecondarySidebarTopInsetScope>();

  @override
  bool updateShouldNotify(SecondarySidebarTopInsetScope oldWidget) =>
      oldWidget.topInset != topInset ||
      oldWidget.title != title ||
      oldWidget.icon != icon;
}

/// Publishes one workspace-level header to every shared module sidebar.
class SidebarHeaderScope extends InheritedWidget {
  const SidebarHeaderScope({
    super.key,
    required this.builder,
    required super.child,
  });

  final SidebarHeaderBuilder builder;

  static SidebarHeaderScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SidebarHeaderScope>();

  @override
  bool updateShouldNotify(SidebarHeaderScope oldWidget) =>
      oldWidget.builder != builder;
}

/// Publishes one workspace-level footer to every shared module sidebar.
class SidebarFooterScope extends InheritedWidget {
  const SidebarFooterScope({
    super.key,
    required this.builder,
    required super.child,
  });

  final SidebarFooterBuilder builder;

  static SidebarFooterScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SidebarFooterScope>();

  @override
  bool updateShouldNotify(SidebarFooterScope oldWidget) =>
      oldWidget.builder != builder;
}

/// Full-height sidebar surface with a concave notch in its right boundary.
/// The clipped background and the button share one geometry and stack.
class SidebarEdgeShell extends StatelessWidget {
  const SidebarEdgeShell({
    super.key,
    required this.collapsed,
    required this.onToggle,
    required this.child,
    this.showHandle = true,
    this.backgroundColor = AppColors.dashboardTopBar,
    this.expandTooltip,
    this.collapseTooltip,
    this.toggleKey,
    this.headerTitle,
    this.collapseInHeader = false,
  });

  final bool collapsed;
  final VoidCallback? onToggle;
  final Widget child;
  final bool showHandle;
  final Color backgroundColor;
  final String? expandTooltip;
  final String? collapseTooltip;
  final Key? toggleKey;
  final String? headerTitle;
  final bool collapseInHeader;

  @override
  Widget build(BuildContext context) {
    final globalNavigation = GlobalNavigationCollapseScope.maybeOf(context);
    final expansion = globalNavigation?.expansion;
    if (expansion == null) {
      return _buildShell(context, globalNavigation, 1);
    }
    if (!TickerMode.of(context)) {
      return _buildShell(
        context,
        globalNavigation,
        globalNavigation!.collapsed ? 0 : 1,
      );
    }
    return AnimatedBuilder(
      animation: expansion,
      builder: (context, _) =>
          _buildShell(context, globalNavigation, expansion.value),
    );
  }

  Widget _buildShell(
    BuildContext context,
    GlobalNavigationCollapseScope? globalNavigation,
    double globalExpansion,
  ) {
    return LayoutBuilder(builder: (context, constraints) {
      final theme = Theme.of(context);
      final neutralLight =
          theme.extension<HexoraThemeVariant>()?.neutralLight == true;
      // Module sidebars historically defaulted to the navy dashboard surface.
      // In the neutral light variant, make that default follow the primary
      // sidebar surface while preserving explicitly supplied colors.
      final shellBackground =
          neutralLight && backgroundColor == AppColors.dashboardTopBar
              ? theme.colorScheme.surface
              : backgroundColor;
      final height = constraints.hasBoundedHeight
          ? constraints.maxHeight
          : MediaQuery.sizeOf(context).height;
      final centerY = SidebarEdgeGeometry.centerY(height);
      final usesEdgeHandle = showHandle && (collapsed || !collapseInHeader);
      final notchDepth =
          usesEdgeHandle ? SidebarEdgeGeometry.notchDepth(collapsed) : 0.0;
      final handleCenterInset =
          SidebarEdgeGeometry.handleCenterInset(collapsed);
      final footerScope = SidebarFooterScope.maybeOf(context);
      final footer = footerScope?.builder(context, collapsed);
      final sidebarHeaderScope = SidebarHeaderScope.maybeOf(context);
      final sidebarHeader = sidebarHeaderScope?.builder(context, collapsed);
      final globalHeaderExtent =
          SidebarEdgeGeometry.globalRestoreHeaderHeight * (1 - globalExpansion);
      final showGlobalRestoreHeader =
          globalNavigation != null && globalHeaderExtent > 0.01;
      final restoreHeaderVisible =
          globalNavigation?.collapsed == true && globalExpansion <= 0.001;
      final showHeader = !collapsed &&
          onToggle != null &&
          showHandle &&
          (headerTitle ?? '').trim().isNotEmpty;
      final secondaryHeaderExtent = showHeader ? 36.0 : 0.0;
      final contextualScope = SecondarySidebarTopInsetScope.maybeOf(context);
      final contextualTopInset = contextualScope?.topInset ?? 0;
      final contextualTitle = contextualScope?.title?.trim();
      final showContextualTitle = !collapsed &&
          !showHeader &&
          contextualTitle != null &&
          contextualTitle.isNotEmpty;
      final accountHeaderExtent =
          sidebarHeader == null ? 0.0 : (collapsed ? 48.0 : 52.0);
      final headerExtent = globalHeaderExtent +
          accountHeaderExtent +
          secondaryHeaderExtent +
          contextualTopInset;

      return SizedBox.expand(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ClipPath(
                clipper: _SidebarNotchClipper(
                  centerY: centerY,
                  depth: notchDepth,
                ),
                child: ColoredBox(color: shellBackground),
              ),
            ),
            // Content fills the space above an intrinsically sized footer, so a
            // footer that grows (e.g. the account menu expanding upward) pushes
            // the content up while the footer stays pinned to the bottom.
            Positioned.fill(
              top: headerExtent,
              child: Padding(
                padding: EdgeInsets.only(
                  right: usesEdgeHandle
                      ? SidebarEdgeGeometry.contentSafeInset(collapsed)
                      : 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: child),
                    if (footer != null) footer,
                  ],
                ),
              ),
            ),
            if (showHeader)
              PositionedDirectional(
                start: 0,
                end: usesEdgeHandle
                    ? SidebarEdgeGeometry.contentSafeInset(false)
                    : 0,
                top: globalHeaderExtent + accountHeaderExtent,
                height: secondaryHeaderExtent,
                child: SecondarySidebarHeader(
                  title: headerTitle!,
                  onCollapse: onToggle!,
                  toggleKey: collapseInHeader ? toggleKey : null,
                  showCollapseAction: collapseInHeader,
                ),
              ),
            if (showContextualTitle)
              PositionedDirectional(
                start: 0,
                end: usesEdgeHandle
                    ? SidebarEdgeGeometry.contentSafeInset(false)
                    : 0,
                top: globalHeaderExtent +
                    accountHeaderExtent +
                    secondaryHeaderExtent,
                height: contextualTopInset,
                child: SecondarySidebarHeader(
                  title: contextualTitle,
                  icon: contextualScope?.icon,
                  emphasized: true,
                  onCollapse: () {},
                  showCollapseAction: false,
                ),
              ),
            if (sidebarHeader != null)
              PositionedDirectional(
                start: 0,
                end: usesEdgeHandle
                    ? SidebarEdgeGeometry.contentSafeInset(collapsed)
                    : 0,
                top: globalHeaderExtent,
                height: accountHeaderExtent,
                child: sidebarHeader,
              ),
            if (showGlobalRestoreHeader)
              PositionedDirectional(
                start: 0,
                end: 0,
                top: 0,
                height: globalHeaderExtent,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    minHeight: SidebarEdgeGeometry.globalRestoreHeaderHeight,
                    maxHeight: SidebarEdgeGeometry.globalRestoreHeaderHeight,
                    child: IgnorePointer(
                      ignoring: !restoreHeaderVisible,
                      child: ExcludeFocus(
                        excluding: !restoreHeaderVisible,
                        child: Opacity(
                          opacity: restoreHeaderVisible ? 1 : 0,
                          child: _HexoraGlobalNavigationRestoreHeader(
                            collapsed: collapsed,
                            onRestore: globalNavigation.onRestore,
                            label: globalNavigation.restoreLabel,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (showHandle && onToggle != null && usesEdgeHandle)
              Positioned(
                right:
                    handleCenterInset - SidebarEdgeGeometry.handleTapTarget / 2,
                top: centerY - SidebarEdgeGeometry.handleTapTarget / 2,
                child: SidebarCollapseToggle(
                  key: toggleKey,
                  collapsed: collapsed,
                  onPressed: onToggle,
                  diameter: SidebarEdgeGeometry.handleDiameter,
                  expandTooltip: expandTooltip,
                  collapseTooltip: collapseTooltip,
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _HexoraGlobalNavigationRestoreHeader extends StatelessWidget {
  const _HexoraGlobalNavigationRestoreHeader({
    required this.collapsed,
    required this.onRestore,
    this.label,
  });

  final bool collapsed;
  final VoidCallback onRestore;
  final String? label;

  static const DecorationImage _brandedBackground = DecorationImage(
    image: AssetImage('assets/images/home_page/dark_bg_color.png'),
    fit: BoxFit.cover,
    alignment: Alignment.centerLeft,
    opacity: 0.22,
  );

  @override
  Widget build(BuildContext context) {
    final es = Localizations.localeOf(context).languageCode == 'es';
    const spanishTooltip = 'Mostrar menú principal';
    const englishTooltip = 'Show main navigation';
    final tooltip = es ? spanishTooltip : englishTooltip;
    final displayLabel =
        label?.trim().isNotEmpty == true ? label!.trim() : 'Hexora';
    final foreground = HexoraGlobalNavColors.foregroundFor(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HexoraGlobalNavColors.backgroundFor(context),
        image: Theme.of(context).brightness == Brightness.dark
            ? _brandedBackground
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Semantics(
          button: true,
          expanded: false,
          label: tooltip,
          child: Tooltip(
            message: tooltip,
            child: InkWell(
              key: const ValueKey('global-navigation-restore-header'),
              onTap: onRestore,
              hoverColor: foreground.withValues(alpha: 0.06),
              focusColor: foreground.withValues(alpha: 0.14),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: collapsed ? 12 : 14),
                child: Row(
                  mainAxisAlignment: collapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    if (collapsed)
                      const HexoraBrandIcon(
                        size: 24,
                        excludeFromSemantics: true,
                      )
                    else ...[
                      Expanded(
                        child: Tooltip(
                          message: displayLabel,
                          child: Text(
                            displayLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: foreground,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 17,
                        color: foreground.withValues(alpha: 0.72),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarNotchClipper extends CustomClipper<Path> {
  const _SidebarNotchClipper({
    required this.centerY,
    required this.depth,
  });

  final double centerY;
  final double depth;

  @override
  Path getClip(Size size) {
    final edge = size.width;
    const halfSpan = SidebarEdgeGeometry.notchSpan / 2;
    const shoulderControl = halfSpan * 0.64;

    return Path()
      ..moveTo(0, 0)
      ..lineTo(edge, 0)
      ..lineTo(edge, centerY - halfSpan)
      ..cubicTo(edge, centerY - shoulderControl, edge - depth,
          centerY - shoulderControl, edge - depth, centerY)
      ..cubicTo(edge - depth, centerY + shoulderControl, edge,
          centerY + shoulderControl, edge, centerY + halfSpan)
      ..lineTo(edge, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_SidebarNotchClipper oldClipper) =>
      oldClipper.centerY != centerY || oldClipper.depth != depth;
}
