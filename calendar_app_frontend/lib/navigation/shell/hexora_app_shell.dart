import 'package:flutter/material.dart';
import 'package:hexora/navigation/shell/global_navigation_collapse_scope.dart';
import 'package:hexora/theme/motion/hexora_motion.dart';
import 'package:hexora/theme/themes/navigation_tokens.dart';

/// Single shell for workspace screens: a global navigation bar on top and the
/// active module below. The module label is published through
/// [HexoraNavContext] so shared contextual toolbars (e.g. `FolderPanel`) can
/// render `Module / Page` breadcrumbs without each module wiring it up.
class HexoraAppShell extends StatefulWidget {
  const HexoraAppShell({
    super.key,
    required this.globalNav,
    required this.body,
    this.moduleLabel,
    this.moduleIcon,
    this.globalNavigationCollapsed = false,
    this.onRestoreGlobalNavigation,
  });

  final Widget globalNav;
  final Widget body;
  final String? moduleLabel;
  final IconData? moduleIcon;
  final bool globalNavigationCollapsed;
  final VoidCallback? onRestoreGlobalNavigation;

  @override
  State<HexoraAppShell> createState() => _HexoraAppShellState();
}

class _HexoraAppShellState extends State<HexoraAppShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _navigationController;

  @override
  void initState() {
    super.initState();
    _navigationController = AnimationController(
      vsync: this,
      duration: HexoraMotion.layout,
      value: widget.globalNavigationCollapsed ? 0 : 1,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navigationController.duration =
        HexoraMotion.duration(context, HexoraMotion.layout);
  }

  @override
  void didUpdateWidget(covariant HexoraAppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.globalNavigationCollapsed ==
        widget.globalNavigationCollapsed) {
      return;
    }
    _navigationController.animateTo(
      widget.globalNavigationCollapsed ? 0 : 1,
      duration: HexoraMotion.duration(context, HexoraMotion.layout),
      curve: HexoraMotion.emphasized,
    );
  }

  @override
  void dispose() {
    _navigationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.moduleLabel;
    final workspace = label == null
        ? widget.body
        : HexoraNavContext(
            moduleLabel: label,
            moduleIcon: widget.moduleIcon,
            child: widget.body,
          );
    return AnimatedBuilder(
      animation: _navigationController,
      child: workspace,
      builder: (context, workspace) {
        final expansion = _navigationController.value;
        final scopedWorkspace = widget.onRestoreGlobalNavigation == null
            ? workspace!
            : GlobalNavigationCollapseScope(
                collapsed: widget.globalNavigationCollapsed,
                expansion: _navigationController,
                onRestore: widget.onRestoreGlobalNavigation!,
                child: workspace!,
              );
        final navHeight = NavigationTokens.globalBarHeight * expansion;
        // Keep the workspace constraints stable while the navigation moves.
        // A Column with an animated first-child height forces every mounted
        // workspace tab (including inactive IndexedStack children) through a
        // full layout on every frame. Translating the workspace is handled by
        // the compositor; its height changes only once after expansion ends.
        final workspaceBottomInset = !widget.globalNavigationCollapsed &&
                _navigationController.status == AnimationStatus.completed
            ? NavigationTokens.globalBarHeight
            : 0.0;
        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              bottom: workspaceBottomInset,
              child: Transform.translate(
                offset: Offset(0, navHeight),
                transformHitTests: true,
                child: scopedWorkspace,
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: navHeight,
              child: SizedBox(
                key: const ValueKey('global-navigation-viewport'),
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    minHeight: NavigationTokens.globalBarHeight,
                    maxHeight: NavigationTokens.globalBarHeight,
                    child: FadeTransition(
                      opacity: _navigationController,
                      child: IgnorePointer(
                        ignoring: widget.globalNavigationCollapsed,
                        child: ExcludeFocus(
                          excluding: widget.globalNavigationCollapsed,
                          child: widget.globalNav,
                        ),
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

/// Exposes the active module to descendants (breadcrumbs, toolbars).
class HexoraNavContext extends InheritedWidget {
  const HexoraNavContext({
    super.key,
    required this.moduleLabel,
    this.moduleIcon,
    required super.child,
  });

  final String moduleLabel;
  final IconData? moduleIcon;

  static HexoraNavContext? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HexoraNavContext>();

  @override
  bool updateShouldNotify(HexoraNavContext oldWidget) =>
      oldWidget.moduleLabel != moduleLabel ||
      oldWidget.moduleIcon != moduleIcon;
}

/// Compact `Module / Page` trail. The module segment is dropped when it would
/// repeat the page title or when [compact] is set (narrow layouts).
class HexoraBreadcrumb extends StatelessWidget {
  const HexoraBreadcrumb({
    super.key,
    required this.title,
    this.module,
    this.compact = false,
  });

  final String title;
  final String? module;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = NavigationTokens.label(context);
    final moduleLabel =
        module ?? HexoraNavContext.maybeOf(context)?.moduleLabel;
    final showModule = !compact &&
        moduleLabel != null &&
        moduleLabel.trim().toLowerCase() != title.trim().toLowerCase();

    final current = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: base.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600),
    );
    if (!showModule) {
      return Semantics(header: true, child: current);
    }

    final muted = base.copyWith(color: cs.onSurfaceVariant);
    return Semantics(
      header: true,
      label: '$moduleLabel, $title',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(moduleLabel, maxLines: 1, style: muted),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '/',
                style: muted.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                ),
              ),
            ),
            Flexible(child: current),
          ],
        ),
      ),
    );
  }
}
