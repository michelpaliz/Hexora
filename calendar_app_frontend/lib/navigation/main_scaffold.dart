import 'package:flutter/material.dart';
import 'package:hexora/theme/themes/mobile_theme.dart';
import 'package:hexora/navigation/fab/contextual_fab.dart';
import 'package:hexora/navigation/horizontal_nav/horizontal_drawer_nav.dart';

class MainScaffold extends StatelessWidget {
  /// Keep `title` for back-compat; use `titleWidget` to show custom header (avatar + name).
  final String? title;
  final Widget body;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;

  /// If false, no AppBar is rendered (saves vertical space).
  final bool showAppBar;

  /// The primary action is resolved from the current route.
  final FloatingActionButton? fab; // legacy, unused now
  final Color? appBarBackgroundColor;
  final IconThemeData? iconTheme;
  final bool? centerTitle;
  final bool showBottomNavAndFab;
  final bool showFab;

  const MainScaffold({
    super.key,
    this.title,
    required this.body,
    this.titleWidget,
    this.leading,
    this.actions,
    this.fab,
    this.showAppBar = true,
    this.appBarBackgroundColor,
    this.iconTheme,
    this.centerTitle,
    this.showBottomNavAndFab = true,
    this.showFab = true,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).canvasColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: bg,
      extendBody: false,
      appBar: showAppBar
          ? AppBar(
              backgroundColor: appBarBackgroundColor ?? bg,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              toolbarHeight:
                  MobileTheme.isActive(context) ? kToolbarHeight : 72,
              titleSpacing: 16,
              centerTitle: centerTitle ?? false,
              leading: leading,
              title: titleWidget ?? (title != null ? Text(title!) : null),
              actions: actions,
              iconTheme: iconTheme ?? IconThemeData(color: onSurface),
              actionsIconTheme: iconTheme ?? IconThemeData(color: onSurface),
              automaticallyImplyLeading: false,
            )
          : null,
      body: Container(color: bg, child: body),
      bottomNavigationBar: showBottomNavAndFab
          ? DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                )),
              ),
              child: const HorizontalDrawerNav(),
            )
          : null,
      floatingActionButtonLocation:
          showBottomNavAndFab ? FloatingActionButtonLocation.endFloat : null,
      floatingActionButton:
          showBottomNavAndFab && showFab ? const ContextualFab() : null,
    );
  }
}
