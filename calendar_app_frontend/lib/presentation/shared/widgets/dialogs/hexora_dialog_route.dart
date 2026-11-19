import 'package:flutter/material.dart';
import 'package:hexora/theme/motion/hexora_motion.dart';

/// Shows a Hexora dialog with the shared subtle fade and scale transition.
Future<T?> showHexoraDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  String? barrierLabel,
  Color? barrierColor,
  bool useRootNavigator = true,
  bool useSafeArea = true,
  Offset? anchorPoint,
  TraversalEdgeBehavior? traversalEdgeBehavior,
  bool? requestFocus,
  RouteSettings? routeSettings,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  final reducedMotion = HexoraMotion.reduceMotion(context);
  final localizations = MaterialLocalizations.of(context);

  return navigator.push<T>(RawDialogRoute<T>(
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel ?? localizations.modalBarrierDismissLabel,
    barrierColor:
        barrierColor ?? DialogTheme.of(context).barrierColor ?? Colors.black54,
    transitionDuration: reducedMotion ? Duration.zero : HexoraMotion.dialog,
    settings: routeSettings,
    anchorPoint: anchorPoint,
    traversalEdgeBehavior: traversalEdgeBehavior,
    requestFocus: requestFocus,
    pageBuilder: (dialogContext, animation, secondaryAnimation) => themes.wrap(
      useSafeArea
          ? SafeArea(child: Builder(builder: builder))
          : Builder(builder: builder),
    ),
    transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: HexoraMotion.enter,
        reverseCurve: HexoraMotion.exit,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: .985, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  ));
}
