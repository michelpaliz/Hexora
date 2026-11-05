import 'package:flutter/material.dart';
import 'package:hexora/theme/motion/hexora_motion.dart';

/// Applies the shared Hexora transition when a module menu changes content.
///
/// The child remains in its normal position in the tree, so module state and
/// existing navigation behavior are preserved.
class HexoraMenuContentTransition extends StatefulWidget {
  const HexoraMenuContentTransition({
    super.key,
    required this.transitionKey,
    required this.child,
    this.duration = HexoraMotion.standard,
    this.curve = HexoraMotion.enter,
    this.initialOpacity = 0.82,
    this.slideOffset = const Offset(0.012, 0),
    this.translateX = 0,
    this.preserveState = false,
  });

  const HexoraMenuContentTransition.module({
    super.key,
    required this.transitionKey,
    required this.child,
    this.duration = HexoraMotion.moduleNavigation,
    this.curve = HexoraMotion.navigationCurve,
    this.initialOpacity = 0.86,
    this.slideOffset = Offset.zero,
    this.translateX = 10,
    this.preserveState = true,
  });

  const HexoraMenuContentTransition.tab({
    super.key,
    required this.transitionKey,
    required this.child,
    this.duration = HexoraMotion.tabNavigation,
    this.curve = HexoraMotion.navigationCurve,
    this.initialOpacity = 0.94,
    this.slideOffset = Offset.zero,
    this.translateX = 0,
    this.preserveState = false,
  });

  const HexoraMenuContentTransition.submenu({
    super.key,
    required this.transitionKey,
    required this.child,
    this.duration = HexoraMotion.submenuNavigation,
    this.curve = HexoraMotion.navigationCurve,
    this.initialOpacity = 0.9,
    this.slideOffset = Offset.zero,
    this.translateX = 0,
    this.preserveState = false,
  });

  final Object transitionKey;
  final Widget child;
  final Duration duration;
  final Curve curve;
  final double initialOpacity;
  final Offset slideOffset;
  final double translateX;
  final bool preserveState;

  @override
  State<HexoraMenuContentTransition> createState() =>
      _HexoraMenuContentTransitionState();
}

class _HexoraMenuContentTransitionState
    extends State<HexoraMenuContentTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 1,
  );
  final Map<Object, Widget> _preservedChildren = <Object, Widget>{};

  @override
  void initState() {
    super.initState();
    if (widget.preserveState) {
      _preservedChildren[widget.transitionKey] = widget.child;
    }
  }

  @override
  void didUpdateWidget(covariant HexoraMenuContentTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (widget.preserveState) {
      _preservedChildren[widget.transitionKey] = widget.child;
    } else if (oldWidget.preserveState) {
      _preservedChildren.clear();
    }
    if (oldWidget.transitionKey != widget.transitionKey) {
      if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) && _controller.value != 1) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = _content();
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);
    final opacity = Tween<double>(
      begin: widget.initialOpacity,
      end: 1,
    ).animate(curved);
    final offset = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(curved);

    Widget animatedChild = SlideTransition(
      position: offset,
      transformHitTests: false,
      child: child,
    );
    if (widget.translateX != 0) {
      animatedChild = AnimatedBuilder(
        animation: curved,
        child: animatedChild,
        builder: (context, child) => Transform.translate(
          offset: Offset(widget.translateX * (1 - curved.value), 0),
          transformHitTests: false,
          child: child,
        ),
      );
    }
    return ClipRect(
      child: FadeTransition(
        opacity: opacity,
        child: animatedChild,
      ),
    );
  }

  Widget _content() {
    if (!widget.preserveState) return widget.child;
    final keys = _preservedChildren.keys.toList(growable: false);
    final activeIndex = keys.indexOf(widget.transitionKey);
    return IndexedStack(
      index: activeIndex,
      children: [
        for (var index = 0; index < keys.length; index++)
          TickerMode(
            enabled: index == activeIndex,
            child: KeyedSubtree(
              key: ValueKey<Object>(keys[index]),
              child: _preservedChildren[keys[index]]!,
            ),
          ),
      ],
    );
  }
}
