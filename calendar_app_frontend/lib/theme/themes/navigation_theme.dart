import 'package:flutter/material.dart';
import 'package:hexora/theme/colors/app_colors.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

/// Shared colors for the workspace's navy navigation panels.
ThemeData navigationTheme(ThemeData base) => base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.navigationForeground,
        displayColor: AppColors.navigationForeground,
      ),
      iconTheme: const IconThemeData(color: AppColors.navigationForeground),
      extensions: [
        ...base.extensions.values.where((value) => value is! AppTypography),
        AppTypography.dark(),
      ],
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        primary: const Color(0xFF9DC3FF),
        primaryContainer: AppColors.primary,
        onPrimaryContainer: Colors.white,
        secondaryContainer: const Color(0xFF31465F),
        onSecondaryContainer: AppColors.navigationForeground,
        surface: AppColors.dashboardTopBar,
        onSurface: AppColors.navigationForeground,
        onSurfaceVariant: const Color(0xFFD4DFEF),
        surfaceContainerHighest: const Color(0xFF31465F),
        outline: const Color(0xFF9CAEC7),
        outlineVariant: const Color(0xFF41546D),
      ),
    );

class NavigationSurface extends StatelessWidget {
  const NavigationSurface({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => Theme(
        data: navigationTheme(Theme.of(context)),
        child: ColoredBox(
          color: AppColors.dashboardTopBar,
          child: Builder(builder: builder),
        ),
      );
}
