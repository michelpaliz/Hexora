import 'package:flutter/widgets.dart';

/// Coordinates distraction-free global navigation with the module sidebar.
///
/// Keeping this state in the application shell lets the shared sidebar reserve
/// the branded restore header while the existing workspace subtree remains
/// mounted in its original position.
class GlobalNavigationCollapseScope extends InheritedWidget {
  const GlobalNavigationCollapseScope({
    super.key,
    required this.collapsed,
    required this.expansion,
    required this.onRestore,
    required super.child,
  });

  final bool collapsed;

  /// Shared shell animation progress: 0 is collapsed, 1 is expanded.
  final Animation<double> expansion;
  final VoidCallback onRestore;

  static GlobalNavigationCollapseScope? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<GlobalNavigationCollapseScope>();

  @override
  bool updateShouldNotify(GlobalNavigationCollapseScope oldWidget) =>
      oldWidget.collapsed != collapsed ||
      oldWidget.expansion != expansion ||
      oldWidget.onRestore != onRestore;
}
