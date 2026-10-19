import 'package:flutter/material.dart';
import 'package:hexora/theme/themes/navigation_tokens.dart';

/// Compact desktop menu entries with larger mobile touch targets. Selection,
/// keyboard traversal, dismissal and callbacks remain Material's behavior.
class NavigationPopupMenuItem<T> extends PopupMenuItem<T> {
  const NavigationPopupMenuItem(
      {super.key,
      super.value,
      super.onTap,
      super.enabled,
      super.height = NavigationTokens.desktopRowHeight,
      super.padding,
      super.textStyle,
      super.labelTextStyle,
      super.mouseCursor,
      required super.child});

  @override
  PopupMenuItemState<T, NavigationPopupMenuItem<T>> createState() =>
      _NavigationPopupMenuItemState<T>();
}

class _NavigationPopupMenuItemState<T>
    extends PopupMenuItemState<T, NavigationPopupMenuItem<T>> {
  @override
  Widget build(BuildContext context) => ConstrainedBox(
      constraints:
          BoxConstraints(minHeight: NavigationTokens.rowHeight(context)),
      child: IconTheme.merge(
          data: const IconThemeData(size: NavigationTokens.iconSize),
          child: super.build(context)));
}
