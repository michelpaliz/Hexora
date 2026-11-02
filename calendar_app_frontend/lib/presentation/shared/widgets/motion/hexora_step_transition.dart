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
    this.forward = true,
  }) : children = null;

  const HexoraStepTransition.indexed({
    super.key,
    required int currentStep,
    required List<Widget> this.children,
  })  : step = currentStep,
        child = null,
        forward = true;

  final Object step;
  final Widget? child;
  final List<Widget>? children;
  final bool forward;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = HexoraMotion.reduceMotion(context);
    final indexedChildren = children;
    if (indexedChildren != null) {
      final currentStep = (step as int).clamp(0, indexedChildren.length - 1);
      final duration = reducedMotion ? Duration.zero : HexoraMotion.navigation;
      return Stack(
        fit: StackFit.expand,
        children: [
          for (var index = 0; index < indexedChildren.length; index++)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: index != currentStep,
                child: ExcludeSemantics(
                  excluding: index != currentStep,
                  child: TickerMode(
                    enabled: index == currentStep,
                    child: Focus(
                      canRequestFocus: index == currentStep,
                      descendantsAreFocusable: index == currentStep,
                      child: AnimatedOpacity(
                        duration: duration,
                        curve: HexoraMotion.emphasized,
                        opacity: index == currentStep ? 1 : 0,
                        child: AnimatedSlide(
                          duration: duration,
                          curve: HexoraMotion.emphasized,
                          offset: index == currentStep
                              ? Offset.zero
                              : Offset(index < currentStep ? -.025 : .025, 0),
                          child: indexedChildren[index],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }
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
        return AnimatedBuilder(
          animation: animation,
          child: transitionChild,
          builder: (context, transitionChild) {
            final outgoing = animation.status == AnimationStatus.reverse;
            final direction = forward ? 1.0 : -1.0;
            final dx = (outgoing ? -direction : direction) *
                .015 *
                (1 - animation.value);
            return Opacity(
              opacity: animation.value,
              child: FractionalTranslation(
                translation: Offset(dx, 0),
                transformHitTests: false,
                child: transitionChild,
              ),
            );
          },
        );
      },
      child: KeyedSubtree(
        key: ValueKey<Object>(step),
        child: child!,
      ),
    );
  }
}
