import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/theme/motion/hexora_motion.dart';
import 'package:flutter/material.dart';

/// Navigation-only sizing. Do not apply these values to forms or body text.
abstract final class NavigationTokens {
  static const double textSize = 12.5;
  static const double titleSize = 15;
  static const double groupSize = 13;
  static const double createActionSize = 12;
  static const double sectionSize = 10.5;
  static const double sectionLetterSpacing = 0.5;
  static const double countSize = 11;
  static const double iconSize = 18;
  static const double desktopRowHeight = 40;
  static const double touchRowHeight = 48;
  static const double sidebarWidth = 248;
  static const double railWidth = 56;
  static const double itemGap = 4;
  static const double groupGap = 8;
  static const double childGap = 2;
  static const double itemPadding = 12;
  static const double outerPadding = 16;
  static const double nestedIndent = 16;
  static const double radius = 8;
  static const double indicatorWidth = 3;
  static const double mobileBreakpoint = 760;
  static const Duration motion = HexoraMotion.standard;

  // App shell (global bar + contextual toolbar).
  static const double globalBarHeight = 56;
  static const double globalItemHeight = 36;
  static const double globalItemPadding = 10;
  static const double contextBarHeight = 36;
  static const double searchHeight = 34;
  static const double sidebarToggleSize = 30;
  static const double badgeHeight = 14;
  static const double badgeTextSize = 9;

  static double rowHeight(BuildContext context) {
    final platform = Theme.of(context).platform;
    final touch = platform == TargetPlatform.android ||
        platform == TargetPlatform.iOS ||
        (MediaQuery.maybeSizeOf(context)?.width ?? double.infinity) <
            mobileBreakpoint;
    return touch ? touchRowHeight : desktopRowHeight;
  }

  static TextStyle label(BuildContext context, {bool selected = false}) =>
      (Theme.of(context).extension<AppTypography>()?.bodySmall ??
              Theme.of(context).textTheme.labelMedium ??
              const TextStyle())
          .copyWith(
        fontSize: textSize,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        letterSpacing: 0,
      );

  static TextStyle title(BuildContext context) =>
      label(context).copyWith(fontSize: titleSize, fontWeight: FontWeight.w600);

  static TextStyle section(BuildContext context) => label(context).copyWith(
      fontSize: sectionSize,
      fontWeight: FontWeight.w600,
      letterSpacing: sectionLetterSpacing);
}

/// Theme-derived state colors, shared by rails, rows, chips and menus.
class NavigationColors {
  NavigationColors(this.scheme);
  final ColorScheme scheme;

  Color get foreground => scheme.onSurfaceVariant;
  Color get selectedForeground =>
      scheme.brightness == Brightness.dark ? Colors.white : scheme.onSurface;

  /// Sidebar text levels, from most to least prominent after the selected item.
  Color get groupForeground =>
      Color.lerp(scheme.onSurfaceVariant, scheme.onSurface, 0.55)!;
  Color get itemForeground =>
      Color.lerp(scheme.onSurfaceVariant, scheme.onSurface, 0.25)!;
  Color get createActionForeground => scheme.onSurfaceVariant;
  Color get sectionForeground => scheme.brightness == Brightness.dark
      ? scheme.onSurfaceVariant.withValues(alpha: 0.72)
      : scheme.onSurfaceVariant;
  Color get createActionIcon => scheme.primary.withValues(alpha: 0.9);

  Color get selectedBackground =>
      Color.alphaBlend(scheme.primary.withValues(alpha: 0.16), scheme.surface);
  Color get indicator => scheme.primary;
  Color get hover => scheme.primary.withValues(alpha: 0.08);
  Color get focus => scheme.primary.withValues(alpha: 0.16);
  Color get pressed => scheme.primary.withValues(alpha: 0.20);
  Color get disabled => scheme.onSurface.withValues(alpha: 0.38);

  Color overlay(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) return Colors.transparent;
    if (states.contains(WidgetState.pressed)) return pressed;
    if (states.contains(WidgetState.focused)) return focus;
    if (states.contains(WidgetState.hovered)) return hover;
    return Colors.transparent;
  }
}
