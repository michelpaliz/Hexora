import 'package:flutter/material.dart';

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

class _WorkspaceContentState extends State<WorkspaceContent> {
  final Map<WorkspaceTabIdentity, _CachedWorkspaceTab> _cache = {};

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
                  child: _tabView(
                    context,
                    manager,
                    tab,
                    tab.identity == active,
                  ),
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
    required this.tabBarBuilder,
    required super.child,
  });

  final bool active;
  final WorkspaceTabBarBuilder tabBarBuilder;

  static WorkspaceTabChromeScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WorkspaceTabChromeScope>();

  @override
  bool updateShouldNotify(WorkspaceTabChromeScope oldWidget) =>
      oldWidget.active != active || oldWidget.tabBarBuilder != tabBarBuilder;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (chrome.active)
          chrome.tabBarBuilder(context)
        else
          const SizedBox.shrink(),
        Expanded(child: child),
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
          Icon(Icons.tab_outlined, size: 30, color: cs.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            es ? 'Abre una sección para empezar' : 'Open a section to begin',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
