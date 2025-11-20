import 'package:hexora/e-drawer-style-menu/contextual_fab/contextual_fab.dart';
import 'package:hexora/e-drawer-style-menu/contextual_fab/horizontal_drawer_nav.dart';
import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart';
import 'package:flutter/material.dart';

class MainScaffold extends StatelessWidget {
  /// Keep `title` for back-compat; use `titleWidget` to show custom header (avatar + name).
  final String? title;
  final Widget body;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;

  /// If false, no AppBar is rendered (saves vertical space).
  final bool showAppBar;

  /// Stop passing per-screen FABs when using the center-docked FAB.
  final FloatingActionButton? fab; // legacy, unused now

  const MainScaffold({
    super.key,
    this.title,
    required this.body,
    this.titleWidget,
    this.leading,
    this.actions,
    this.fab,
    this.showAppBar = true, // 👈 new
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppDarkColors.background : AppColors.background;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: bg,
      extendBody: true, // Allows body to extend behind bottom bar
      appBar: showAppBar
          ? AppBar(
              backgroundColor: bg,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              toolbarHeight: 72,
              titleSpacing: 16,
              centerTitle: false,
              leading: leading,
              title: titleWidget ?? (title != null ? Text(title!) : null),
              actions: actions,
              iconTheme: IconThemeData(color: onSurface),
              actionsIconTheme: IconThemeData(color: onSurface),
              automaticallyImplyLeading: false,
            )
          : null, // 👈 no AppBar at all
      // Removed SafeArea wrapper to let BottomAppBar handle safe areas
      body: Container(color: bg, child: body),
      bottomNavigationBar: BottomAppBar(
        shape: AutomaticNotchedShape(
          const RoundedRectangleBorder(), // host
          ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(22), // guest (FAB)
          ),
        ),
        notchMargin: 10,
        elevation: 8,
        color: (Theme.of(context).brightness == Brightness.dark
                ? AppDarkColors.background
                : AppColors.background)
            .withOpacity(0.96),
        child: const HorizontalDrawerNav(centerGapWidth: 96),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: const ContextualFab(),
    );
  }
}
