import 'package:flutter/widgets.dart';

import 'workspace_tab.dart';
import 'workspace_tab_manager.dart';

/// Lets forms update their tab title and dirty state without depending on the
/// dashboard implementation.
class WorkspaceTabScope extends InheritedWidget {
  const WorkspaceTabScope({
    super.key,
    required this.manager,
    required this.tab,
    required super.child,
  });

  final WorkspaceTabManager manager;
  final WorkspaceTab tab;

  static WorkspaceTabScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WorkspaceTabScope>();

  void updateTitle(String title) => manager.updateTabTitle(tab.identity, title);

  void setDirty({
    required bool dirty,
    WorkspaceTabSaveHandler? onSave,
  }) =>
      manager.setDirty(tab.identity, dirty: dirty, onSave: onSave);

  @override
  bool updateShouldNotify(WorkspaceTabScope oldWidget) =>
      oldWidget.tab != tab || oldWidget.manager != manager;
}
