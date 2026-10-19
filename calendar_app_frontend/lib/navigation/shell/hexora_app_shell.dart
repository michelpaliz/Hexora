import 'package:flutter/material.dart';
import 'package:hexora/theme/themes/navigation_tokens.dart';

/// Single shell for workspace screens: a global navigation bar on top and the
/// active module below. The module label is published through
/// [HexoraNavContext] so shared contextual toolbars (e.g. `FolderPanel`) can
/// render `Module / Page` breadcrumbs without each module wiring it up.
class HexoraAppShell extends StatelessWidget {
  const HexoraAppShell({
    super.key,
    required this.globalNav,
    required this.body,
    this.moduleLabel,
    this.moduleIcon,
  });

  final Widget globalNav;
  final Widget body;
  final String? moduleLabel;
  final IconData? moduleIcon;

  @override
  Widget build(BuildContext context) {
    final label = moduleLabel;
    return Column(
      children: [
        globalNav,
        Expanded(
          child: label == null
              ? body
              : HexoraNavContext(
                  moduleLabel: label,
                  moduleIcon: moduleIcon,
                  child: body,
                ),
        ),
      ],
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
    final moduleLabel = module ?? HexoraNavContext.maybeOf(context)?.moduleLabel;
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
