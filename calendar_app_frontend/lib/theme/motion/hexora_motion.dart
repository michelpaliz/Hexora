import 'package:flutter/material.dart';

/// Shared motion timings and curves for Hexora interactions.
///
/// Keep motion subtle and state-preserving. Call [duration] when an animation
/// must respect the platform reduced-motion preference.
abstract final class HexoraMotion {
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration standard = Duration(milliseconds: 200);
  static const Duration navigation = Duration(milliseconds: 240);
  static const Duration chart = Duration(milliseconds: 750);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasized = Curves.easeInOutCubic;

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
