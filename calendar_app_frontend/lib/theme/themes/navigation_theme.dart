import 'package:flutter/material.dart';
import 'package:hexora/theme/colors/app_colors.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'navigation_tokens.dart';
export 'navigation_tokens.dart';

/// Only Material navigation/menu components are changed; form and body themes
/// deliberately retain their existing typography, density and dimensions.
ThemeData applyNavigationComponentTheme(ThemeData base, {bool touch = false}) {
  final colors = NavigationColors(base.colorScheme);
  final label = (base.extension<AppTypography>()?.bodySmall ??
          base.textTheme.labelMedium ??
          const TextStyle())
      .copyWith(
          fontSize: NavigationTokens.textSize,
          fontWeight: FontWeight.w500,
          letterSpacing: 0);
  final rowHeight = touch
      ? NavigationTokens.touchRowHeight
      : NavigationTokens.desktopRowHeight;
  final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(NavigationTokens.radius));
  final itemStyle = MenuItemButton.styleFrom(
    textStyle: label,
    iconSize: NavigationTokens.iconSize,
    minimumSize: Size(0, rowHeight),
    padding: const EdgeInsets.symmetric(
        horizontal: NavigationTokens.itemPadding, vertical: 8),
    shape: shape,
    visualDensity: VisualDensity.standard,
  ).copyWith(
    overlayColor: WidgetStateProperty.resolveWith(colors.overlay),
    foregroundColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.disabled)
            ? colors.disabled
            : colors.foreground),
    backgroundColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected)
            ? colors.selectedBackground
            : Colors.transparent),
  );
  return base.copyWith(
    menuTheme: MenuThemeData(
        style: MenuStyle(
      backgroundColor:
          WidgetStatePropertyAll(base.colorScheme.surfaceContainer),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      shape: WidgetStatePropertyAll(shape),
      padding: const WidgetStatePropertyAll(
          EdgeInsets.all(NavigationTokens.itemGap)),
    )),
    menuButtonTheme: MenuButtonThemeData(style: itemStyle),
    popupMenuTheme: base.popupMenuTheme.copyWith(
      color: base.colorScheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      shape: shape,
      textStyle: label.copyWith(color: colors.foreground),
      labelTextStyle: WidgetStateProperty.resolveWith((states) =>
          label.copyWith(
              color: states.contains(WidgetState.disabled)
                  ? colors.disabled
                  : colors.foreground)),
      menuPadding: const EdgeInsets.all(NavigationTokens.itemGap),
    ),
    navigationRailTheme: base.navigationRailTheme.copyWith(
      minWidth: NavigationTokens.railWidth,
      minExtendedWidth: NavigationTokens.sidebarWidth,
      indicatorColor: colors.selectedBackground,
      selectedIconTheme: IconThemeData(
          size: NavigationTokens.iconSize, color: colors.indicator),
      unselectedIconTheme: IconThemeData(
          size: NavigationTokens.iconSize, color: colors.foreground),
      selectedLabelTextStyle: label.copyWith(
          color: colors.selectedForeground, fontWeight: FontWeight.w600),
      unselectedLabelTextStyle: label.copyWith(color: colors.foreground),
    ),
    navigationBarTheme: base.navigationBarTheme.copyWith(
      indicatorColor: colors.selectedBackground,
      labelTextStyle: WidgetStatePropertyAll(label),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          size: NavigationTokens.iconSize,
          color: states.contains(WidgetState.selected)
              ? colors.indicator
              : colors.foreground)),
    ),
    bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
      selectedLabelStyle: label.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: label,
      selectedIconTheme: const IconThemeData(size: NavigationTokens.iconSize),
      unselectedIconTheme: const IconThemeData(size: NavigationTokens.iconSize),
    ),
  );
}

/// Shared colors for the workspace's navy navigation panels.
ThemeData navigationTheme(ThemeData base) =>
    applyNavigationComponentTheme(base.copyWith(
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
        primary: AppDarkColors.primary,
        primaryContainer: AppDarkColors.surfaceHover,
        onPrimaryContainer: AppDarkColors.textPrimary,
        secondaryContainer: AppDarkColors.surfaceHover,
        onSecondaryContainer: AppDarkColors.textPrimary,
        surface: AppDarkColors.sidebar,
        surfaceContainerLowest: AppDarkColors.sidebar,
        surfaceContainerLow: AppDarkColors.surface,
        surfaceContainer: AppDarkColors.surface,
        surfaceContainerHigh: AppDarkColors.surfaceHover,
        onSurface: AppDarkColors.textPrimary,
        onSurfaceVariant: AppDarkColors.textSecondary,
        surfaceContainerHighest: AppDarkColors.surfaceHover,
        outline: AppDarkColors.border,
        outlineVariant: AppDarkColors.border,
      ),
    ));

class NavigationSurface extends StatelessWidget {
  const NavigationSurface({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => Theme(
        data: navigationTheme(Theme.of(context)),
        child: ColoredBox(
          color: AppDarkColors.sidebar,
          child: Builder(builder: builder),
        ),
      );
}
