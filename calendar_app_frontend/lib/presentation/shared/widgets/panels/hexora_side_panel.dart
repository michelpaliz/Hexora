import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

/// Standard shell for side-panel content.
///
/// It provides an optional header, a scroll-safe body slot and an optional
/// footer. The widget stays presentation-only: the caller decides whether it is
/// embedded in a page column (chat) or positioned by [HexoraSidePanelHost].
class HexoraSidePanel extends StatelessWidget {
  const HexoraSidePanel({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onClose,
    this.closeTooltip,
    this.header,
    this.footer,
    this.padding = EdgeInsets.zero,
    this.footerPadding = const EdgeInsets.fromLTRB(16, 12, 16, 16),
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.showDivider = true,
    this.embedded = false,
    this.onDismiss,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onClose;
  final String? closeTooltip;
  final Widget? header;
  final Widget? footer;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry footerPadding;
  final Color? backgroundColor;
  final Color? borderColor;
  final BorderRadius? borderRadius;

  /// When true the panel renders without its own surface/border so it can be
  /// embedded inside an existing sheet such as the insights chat right column.
  final bool embedded;
  final bool showDivider;

  /// Invoked on Escape. Defaults to [onClose].
  ///
  /// Route hosts already pop on Escape through their dismissible barrier, but
  /// inline hosts (the chat right column) are plain widgets, so the panel
  /// handles [DismissIntent] itself before it reaches the enclosing route.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final dismiss = onDismiss ?? onClose;
    final panel = _buildPanel(context);
    if (dismiss == null) return panel;
    return Actions(
      actions: <Type, Action<Intent>>{
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (_) {
            dismiss();
            return null;
          },
        ),
      },
      child: Focus(autofocus: true, child: panel),
    );
  }

  Widget _buildPanel(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = borderRadius ?? BorderRadius.circular(embedded ? 0 : 18);
    final hasHeader = header != null ||
        title != null ||
        subtitle != null ||
        leading != null ||
        trailing != null ||
        onClose != null;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasHeader) ...[
          header ??
              HexoraSidePanelHeader(
                title: title,
                subtitle: subtitle,
                leading: leading,
                trailing: trailing,
                onClose: onClose,
                closeTooltip: closeTooltip,
              ),
          if (showDivider)
            Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: 0.4),
            ),
        ],
        Expanded(
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
        if (footer != null) ...[
          if (showDivider)
            Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: 0.4),
            ),
          Padding(
            padding: footerPadding,
            child: footer!,
          ),
        ],
      ],
    );

    if (embedded) {
      return Material(
        color: backgroundColor ?? Colors.transparent,
        child: content,
      );
    }

    return Material(
      color: backgroundColor ?? cs.surface,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: borderColor ?? cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: content,
      ),
    );
  }
}

/// Header used by [HexoraSidePanel] and directly by custom panel layouts.
class HexoraSidePanelHeader extends StatelessWidget {
  const HexoraSidePanelHeader({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onClose,
    this.closeTooltip,
    this.onBack,
    this.backTooltip,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 10, 12),
  });

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onClose;
  final String? closeTooltip;

  /// Shows a back arrow before the title when there is a previous step.
  final VoidCallback? onBack;
  final String? backTooltip;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typography = AppTypography.of(context);
    final hasTitle = title?.trim().isNotEmpty == true;
    final hasSubtitle = subtitle?.trim().isNotEmpty == true;
    final iconStyle = IconButton.styleFrom(
      minimumSize: const Size.square(32),
      maximumSize: const Size.square(32),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      foregroundColor: cs.onSurfaceVariant,
    );

    return Padding(
      padding: onBack == null
          ? padding
          : padding.resolve(Directionality.of(context)).copyWith(left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onBack != null) ...[
            IconButton(
              tooltip: backTooltip ??
                  MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 19),
              style: iconStyle,
            ),
            const SizedBox(width: 6),
          ],
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasTitle)
                  Text(
                    title!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typography.titleLarge.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                if (hasSubtitle) ...[
                  if (hasTitle) const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typography.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
          if (onClose != null) ...[
            const SizedBox(width: 4),
            IconButton(
              tooltip: closeTooltip ??
                  MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, size: 19),
              style: IconButton.styleFrom(
                minimumSize: const Size.square(32),
                maximumSize: const Size.square(32),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: cs.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Hosts a [HexoraSidePanel] as an animated right-side overlay.
///
/// Desktop/tablet widths get a floating panel anchored to the right; widths
/// below [mobileBreakpoint] get a full-screen sheet. The underlying route is
/// never rebuilt, so list scroll position, filters and search stay intact
/// while the panel is open.
class HexoraSidePanelHost {
  const HexoraSidePanelHost._();

  static const double mobileBreakpoint = 700;

  /// Opens [builder] in a side panel.
  ///
  /// [builder] is responsible for returning a [HexoraSidePanel] (usually with
  /// its own header and footer). [preferredWidth] is clamped to the available
  /// viewport so the panel never overflows on tablets.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    double preferredWidth = 520,
    bool barrierDismissible = true,
    String? barrierLabel,
    RouteSettings? settings,
  }) {
    assert(debugCheckHasMaterialLocalizations(context));
    final localizations = MaterialLocalizations.of(context);
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel ?? localizations.modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      transitionDuration: const Duration(milliseconds: 240),
      routeSettings: settings,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final media = MediaQuery.of(dialogContext);
        final screenWidth = media.size.width;
        final overlaysPage = screenWidth >= mobileBreakpoint;
        final panelWidth = overlaysPage
            ? _panelWidth(screenWidth, preferredWidth)
            : screenWidth;

        final panel = MediaQuery(
          data: media.copyWith(
            size: Size(panelWidth, media.size.height),
          ),
          child: Builder(builder: builder),
        );

        if (!overlaysPage) {
          return Material(
            color: Theme.of(dialogContext).colorScheme.surface,
            child: SafeArea(child: SizedBox.expand(child: panel)),
          );
        }

        return SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 12,
                bottom: 12,
                right: 12,
                width: panelWidth,
                child: _PanelShadow(
                  borderRadius: BorderRadius.circular(18),
                  child: panel,
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final overlaysPage =
            MediaQuery.sizeOf(context).width >= mobileBreakpoint;
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final offset = Tween<Offset>(
          begin: overlaysPage ? const Offset(1, 0) : const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(position: offset, child: child),
        );
      },
    );
  }

  static double _panelWidth(double screenWidth, double preferredWidth) {
    final available = math.max(0.0, screenWidth - 24);
    final maxWidth = screenWidth >= 1400
        ? preferredWidth
        : screenWidth >= 1100
            ? preferredWidth - 20
            : preferredWidth - 40;
    return maxWidth.clamp(400.0, available).toDouble();
  }
}

/// Docks an optional [panel] on the right of [child] inside the same screen.
///
/// No route is pushed: when there is room for both, [child] shrinks and the
/// panel sits beside it with a divider; on narrow layouts the panel covers
/// the [child] area instead. [child] keeps the same element in both cases, so
/// its scroll position, selection, filters and search survive opening and
/// closing the panel.
///
/// Give each distinct panel a key so switching between panels animates and
/// resets their state.
class HexoraSidePanelLayout extends StatelessWidget {
  const HexoraSidePanelLayout({
    super.key,
    required this.child,
    this.panel,
    this.minPanelWidth = 420,
    this.maxPanelWidth = 520,
    this.minContentWidth = 520,
    this.backgroundColor,
  });

  final Widget child;
  final Widget? panel;
  final double minPanelWidth;
  final double maxPanelWidth;

  /// Narrowest the main content may become before the panel overlays it.
  final double minContentWidth;
  final Color? backgroundColor;

  static const Duration _duration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final docked = width >= minPanelWidth + minContentWidth;
        final panelWidth = docked
            ? (width * 0.4).clamp(minPanelWidth, maxPanelWidth).toDouble()
            : width;
        final open = panel != null;
        final media = MediaQuery.of(context);

        return Stack(
          fit: StackFit.expand,
          children: [
            AnimatedPadding(
              duration: _duration,
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(right: open && docked ? panelWidth : 0),
              child: child,
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: panelWidth,
              child: IgnorePointer(
                ignoring: !open,
                child: AnimatedSwitcher(
                  duration: _duration,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (panelChild, animation) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child:
                        FadeTransition(opacity: animation, child: panelChild),
                  ),
                  child: !open
                      ? const SizedBox.shrink(key: ValueKey('no-panel'))
                      : KeyedSubtree(
                          key: ValueKey<Object>(
                              panel!.key ?? panel!.runtimeType),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: backgroundColor ?? cs.surface,
                              border: Border(
                                left: BorderSide(
                                  color:
                                      cs.outlineVariant.withValues(alpha: 0.5),
                                ),
                              ),
                              boxShadow: docked
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: isDark ? 0.28 : 0.08,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(-4, 0),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: MediaQuery(
                              data: media.copyWith(
                                size: Size(panelWidth, media.size.height),
                              ),
                              child: panel!,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PanelShadow extends StatelessWidget {
  const _PanelShadow({
    required this.child,
    required this.borderRadius,
  });

  final Widget child;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.18),
            blurRadius: 30,
            spreadRadius: 1,
            offset: const Offset(-8, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }
}
