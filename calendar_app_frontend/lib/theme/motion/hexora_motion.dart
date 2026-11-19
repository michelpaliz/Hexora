import 'package:flutter/material.dart';

/// Shared motion timings and curves for Hexora interactions.
///
/// Keep motion subtle and state-preserving. Call [duration] when an animation
/// must respect the platform reduced-motion preference.
abstract final class HexoraMotion {
  /// Short feedback such as tabs and small controls.
  static const Duration fast = Duration(milliseconds: 120);

  /// General content transitions.
  static const Duration normal = Duration(milliseconds: 180);

  /// Coordinated shell geometry changes (navigation and sidebars).
  static const Duration layout = Duration(milliseconds: 200);

  /// Backwards-compatible default for existing components.
  static const Duration standard = normal;
  static const Duration navigation = Duration(milliseconds: 240);
  static const Duration chart = Duration(milliseconds: 750);

  /// Motion profiles for navigation surfaces. These intentionally remain
  /// separate from wizard/page timings so changing one does not affect the
  /// other workflows.
  static const Duration moduleNavigation = Duration(milliseconds: 180);
  static const Duration submenuNavigation = Duration(milliseconds: 160);
  static const Duration tabNavigation = Duration(milliseconds: 110);
  static const Duration tabIndicator = Duration(milliseconds: 150);
  static const Duration sidePanel = layout;
  static const Duration popup = Duration(milliseconds: 120);
  static const Duration dialog = Duration(milliseconds: 180);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasized = Curves.easeInOutCubic;
  static const Curve navigationCurve = Cubic(0.2, 0, 0, 1);

  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  static Duration duration(BuildContext context, Duration preferred) =>
      reduceMotion(context) ? Duration.zero : preferred;

  static AnimationStyle expansionStyle(BuildContext context) => AnimationStyle(
        duration: duration(context, standard),
        reverseDuration: duration(context, fast),
        curve: enter,
        reverseCurve: exit,
      );

  static AnimationStyle sheetStyle(BuildContext context) => AnimationStyle(
        duration: duration(context, navigation),
        reverseDuration: duration(context, standard),
        curve: enter,
        reverseCurve: exit,
      );

  static AnimationStyle popupStyle(BuildContext context) => AnimationStyle(
        duration: duration(context, popup),
        reverseDuration: duration(context, popup),
        curve: navigationCurve,
        reverseCurve: exit,
      );
}

/// Shared route transition used by desktop, web, and mobile themes.
class HexoraPageTransitionsBuilder extends PageTransitionsBuilder {
  const HexoraPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.isFirst || HexoraMotion.reduceMotion(context)) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: HexoraMotion.enter,
      reverseCurve: HexoraMotion.exit,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(.012, 0),
          end: Offset.zero,
        ).animate(curved),
        transformHitTests: false,
        child: child,
      ),
    );
  }
}
