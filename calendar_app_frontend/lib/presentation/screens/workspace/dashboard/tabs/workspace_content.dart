import 'package:flutter/material.dart';
import 'package:hexora/navigation/shell/hexora_nav_components.dart';
import 'package:hexora/theme/motion/hexora_motion.dart';
import 'package:hexora/theme/themes/navigation_tokens.dart';

import 'workspace_tab.dart';
import 'workspace_tab_bar.dart';
import 'workspace_tab_manager.dart';
import 'workspace_tab_scope.dart';

class WorkspaceContent extends StatefulWidget {
  const WorkspaceContent({
    super.key,
    required this.manager,
    required this.builder,
  });

  final WorkspaceTabManager manager;
  final Widget Function(BuildContext context, WorkspaceTab tab) builder;

  @override
  State<WorkspaceContent> createState() => _WorkspaceContentState();
}

class _CachedWorkspaceTab {
  _CachedWorkspaceTab(this.tab, this.child);

  WorkspaceTab tab;
  final Widget child;
}

class _WorkspaceContentState extends State<WorkspaceContent>
    with SingleTickerProviderStateMixin {
  final Map<WorkspaceTabIdentity, _CachedWorkspaceTab> _cache = {};
  late final AnimationController _contentController = AnimationController(
    vsync: this,
    duration: HexoraMotion.moduleNavigation,
    value: 1,
  );
  late final CurvedAnimation _contentCurve = CurvedAnimation(
    parent: _contentController,
    curve: HexoraMotion.enter,
  );
  late final Animation<double> _contentOpacity = Tween<double>(
    begin: .92,
    end: 1,
  ).animate(_contentCurve);
  WorkspaceTabIdentity? _lastActiveIdentity;

  @override
  void initState() {
    super.initState();
    _lastActiveIdentity = widget.manager.activeIdentity;
    widget.manager.addListener(_handleManagerChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _contentController.duration =
        HexoraMotion.duration(context, HexoraMotion.moduleNavigation);
    if (HexoraMotion.reduceMotion(context)) _contentController.value = 1;
  }

  @override
  void didUpdateWidget(covariant WorkspaceContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.manager == widget.manager) return;
    oldWidget.manager.removeListener(_handleManagerChanged);
    widget.manager.addListener(_handleManagerChanged);
    _lastActiveIdentity = widget.manager.activeIdentity;
    _contentController.value = 1;
  }

  void _handleManagerChanged() {
    final activeIdentity = widget.manager.activeIdentity;
    if (_lastActiveIdentity == activeIdentity) return;
    _lastActiveIdentity = activeIdentity;
    if (!mounted || HexoraMotion.reduceMotion(context)) {
      _contentController.value = 1;
      return;
    }
    _contentController.forward(from: 0);
  }

  @override
  void dispose() {
    widget.manager.removeListener(_handleManagerChanged);
    _contentCurve.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool _tabConfigurationChanged(WorkspaceTab previous, WorkspaceTab next) {
    if (previous.section != next.section ||
        previous.arguments.length != next.arguments.length) {
      return true;
    }
    for (final entry in next.arguments.entries) {
      if (previous.arguments[entry.key] != entry.value) return true;
    }
    return false;
  }

  Widget _cachedTab(BuildContext context, WorkspaceTab tab) {
    final cached = _cache[tab.identity];
    if (cached != null && !_tabConfigurationChanged(cached.tab, tab)) {
      // A user-facing title is presentation metadata, not page identity.
      // Updating it after document hydration must not recreate forms or lose
      // scroll/controller state.
      cached.tab = tab;
      return cached.child;
    }
    final child = widget.builder(context, tab);
    _cache[tab.identity] = _CachedWorkspaceTab(tab, child);
    return child;
  }

  Widget _tabView(
    BuildContext context,
    WorkspaceTabManager manager,
    WorkspaceTab tab,
    bool active,
  ) {
    final content = WorkspaceTabScope(
      manager: manager,
      tab: tab,
      child: _cachedTab(context, tab),
    );
    return WorkspaceTabChromeScope(
      active: active,
      contentOpacity: _contentOpacity,
      tabBarBuilder: (tabBarContext) => WorkspaceTabBar(
        manager: manager,
        onClose: (tab) => _requestClose(tabBarContext, tab),
      ),
      child: content,
    );
  }

  Future<void> _requestClose(BuildContext context, WorkspaceTab tab) async {
    final manager = widget.manager;
    if (!manager.isDirty(tab.identity)) {
      manager.closeTab(tab.identity);
      return;
    }
    final es = Localizations.localeOf(context).languageCode == 'es';
    final result = await showDialog<_CloseDecision>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(es ? 'Cambios sin guardar' : 'Unsaved changes'),
        content: Text(
          es
              ? 'Esta pestaña contiene cambios sin guardar.'
              : 'This tab contains unsaved changes.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, _CloseDecision.cancel),
            child: Text(es ? 'Cancelar' : 'Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, _CloseDecision.discard),
            child: Text(es ? 'Descartar' : 'Discard'),
          ),
          if (manager.canSave(tab.identity))
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, _CloseDecision.save),
              child: Text(es ? 'Guardar' : 'Save'),
            ),
        ],
      ),
    );
    if (!context.mounted || result == null || result == _CloseDecision.cancel) {
      return;
    }
    if (result == _CloseDecision.save && !await manager.save(tab.identity)) {
      return;
    }
    manager.closeTab(tab.identity);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.manager,
      builder: (context, _) {
        final manager = widget.manager;
        final tabs = manager.tabs;
        final active = manager.activeIdentity;
        _cache.removeWhere(
          (identity, _) => !tabs.any((tab) => tab.identity == identity),
        );
        final activeIndex = tabs.indexWhere((tab) => tab.identity == active);
        if (tabs.isEmpty) return const _EmptyWorkspace();
        return IndexedStack(
          index: activeIndex < 0 ? 0 : activeIndex,
          children: [
            for (final tab in tabs)
              KeyedSubtree(
                key: ValueKey<String>(tab.identity.value),
                child: TickerMode(
                  enabled: tab.identity == active,
                  // Restored tabs can include several data-heavy modules.
                  // Mount each tab only after it is selected once; visited
                  // tabs remain cached and mounted so forms, scrolling, and
                  // controller state are still preserved between switches.
                  child:
                      tab.identity == active || _cache.containsKey(tab.identity)
                          ? _tabView(
                              context,
                              manager,
                              tab,
                              tab.identity == active,
                            )
                          : const SizedBox.shrink(),
                ),
              ),
          ],
        );
      },
    );
  }
}

typedef WorkspaceTabBarBuilder = Widget Function(BuildContext context);

/// Publishes the shared tab strip to the main-content column of each module.
class WorkspaceTabChromeScope extends InheritedWidget {
  const WorkspaceTabChromeScope({
    super.key,
    required this.active,
    required this.contentOpacity,
    required this.tabBarBuilder,
    required super.child,
  });

  final bool active;
  final Animation<double> contentOpacity;
  final WorkspaceTabBarBuilder tabBarBuilder;

  static WorkspaceTabChromeScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WorkspaceTabChromeScope>();

  @override
  bool updateShouldNotify(WorkspaceTabChromeScope oldWidget) =>
      oldWidget.active != active ||
      oldWidget.contentOpacity != contentOpacity ||
      oldWidget.tabBarBuilder != tabBarBuilder;
}

/// Wraps only a module's right-hand content column. It is a no-op for mobile
/// and standalone routes where no workspace chrome is present.
class WorkspaceMainContent extends StatelessWidget {
  const WorkspaceMainContent({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final chrome = WorkspaceTabChromeScope.maybeOf(context);
    if (chrome == null) return child;
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: WorkspaceChromeFrame(
        tabBar: chrome.active ? chrome.tabBarBuilder(context) : null,
        child: FadeTransition(
          opacity: chrome.active
              ? chrome.contentOpacity
              : const AlwaysStoppedAnimation<double>(1),
          child: child,
        ),
      ),
    );
  }
}

/// Gives the shared tab strip and its workspace body one horizontal geometry.
///
/// Keeping the inset here prevents individual modules from drifting a few
/// pixels away from the tab strip when sidebars appear, collapse, or switch
/// between unified and separated navigation.
class WorkspaceChromeFrame extends StatelessWidget {
  const WorkspaceChromeFrame({
    super.key,
    this.tabBar,
    this.bodyPadding = EdgeInsets.zero,
    required this.child,
  });

  final Widget? tabBar;
  final EdgeInsetsGeometry bodyPadding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const horizontalInset = EdgeInsetsDirectional.symmetric(
      horizontal: NavigationTokens.workspaceNavigationGap,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (tabBar != null)
          ColoredBox(
            // Paint the side gutters as part of the navigation strip too.
            color: HexoraGlobalNavColors.backgroundFor(context),
            child: Padding(
              padding: horizontalInset,
              child: tabBar!,
            ),
          ),
        Expanded(
          child: Padding(
            padding: horizontalInset,
            child: Padding(
              padding: bodyPadding,
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

enum _CloseDecision { cancel, discard, save }

class _EmptyWorkspace extends StatelessWidget {
  const _EmptyWorkspace();

  @override
  Widget build(BuildContext context) {
    final es = Localizations.localeOf(context).languageCode == 'es';
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/branding/logo_icon.png',
            width: 42,
            height: 42,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.hexagon_outlined, size: 38, color: cs.primary),
          ),
          const SizedBox(height: 12),
          Text(
            es ? 'Bienvenido a Hexora' : 'Welcome to Hexora',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            es
                ? 'Selecciona una sección para comenzar'
                : 'Choose a section to get started',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
