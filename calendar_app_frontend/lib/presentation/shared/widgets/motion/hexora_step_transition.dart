import 'package:flutter/material.dart';
import 'package:hexora/theme/motion/hexora_motion.dart';

/// A compact fade and horizontal slide for stateful workflow content.
///
/// Keep steppers and footers outside this widget so they remain stable while
/// only the current step changes.
class HexoraStepTransition extends StatelessWidget {
  const HexoraStepTransition({
    super.key,
    required this.step,
    required this.child,
  });

  final Object step;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = HexoraMotion.reduceMotion(context);
    return AnimatedSwitcher(
      duration: reducedMotion ? Duration.zero : HexoraMotion.navigation,
      reverseDuration: reducedMotion ? Duration.zero : HexoraMotion.standard,
      switchInCurve: HexoraMotion.enter,
      switchOutCurve: HexoraMotion.exit,
      layoutBuilder: (currentChild, previousChildren) => ClipRect(
        child: Stack(
          alignment: Alignment.topLeft,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        ),
      ),
      transitionBuilder: (transitionChild, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(.025, 0),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: slide,
            transformHitTests: false,
            child: transitionChild,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<Object>(step),
        child: child,
      ),
    );
  }
}
