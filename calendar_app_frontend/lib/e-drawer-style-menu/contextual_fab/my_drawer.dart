import 'package:flutter/material.dart';
import 'package:hexora/e-drawer-style-menu/contextual_fab/horizontal_drawer_nav/horizontal_drawer_nav.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = ThemeColors.containerBg(context);

    return Drawer(
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              right: BorderSide(
                  color: cs.outlineVariant.withOpacity(0.35), width: 1),
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // If you re-enable header/list later, place them above/below this nav.
              // MyHeaderDrawer(),
              // SizedBox(height: 8),
              HorizontalDrawerNav(), // ⬅️ horizontal 3-icon bar
              // SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
