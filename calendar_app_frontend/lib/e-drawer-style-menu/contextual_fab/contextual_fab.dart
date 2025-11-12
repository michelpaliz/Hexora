import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/e-drawer-style-menu/contextual_fab/fab_action.dart';
import 'package:hexora/e-drawer-style-menu/contextual_fab/fab_shell.dart';
import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart';

class ContextualFab extends StatelessWidget {
  const ContextualFab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppDarkColors.primary : AppColors.primary;

    final settings = ModalRoute.of(context)?.settings;
    final routeName = settings?.name ?? '';
    final args = settings?.arguments;
    final groupArg = args is Group ? args : null;

    final action = resolveFabAction(
      context: context,
      routeName: routeName,
      groupArg: groupArg,
      accentColor: baseColor,
    );

    return FabShell(
      color: baseColor,
      child: FloatingActionButton(
        onPressed: action.onPressed,
        elevation: 0,
        shape: const CircleBorder(),
        backgroundColor: baseColor,
        foregroundColor: Colors.white,
        child: Icon(action.icon, size: 26),
      ),
    );
  }
}
